require 'fileutils'
require 'net/http'
require 'json'

desc "Vault ebrelayer Operations"
namespace :vault do


  desc "Deploy a new ebrelayer to an existing cluster"
  task :deploy, [:app_namespace, :image, :image_tag, :env, :app_name] do |t, args|
    cluster_automation = %x{
      set +x
      helm upgrade #{args[:app_name]} deploy/helm/#{args[:app_name]} \
          --install -n #{args[:app_namespace]} \
          --create-namespace \
          --set image.repository=#{args[:image]} \
          --set image.tag=#{args[:image_tag]} \
          --kubeconfig=./kubeconfig

      kubectl rollout status \
          --kubeconfig=./kubeconfig deployment/#{args[:app_name]} \
          -n #{args[:app_namespace]}

    }
    $? ==0 ? "Success" : exit 1
  end


  desc "Push Secret to Vault"
  task :push_secret_to_vault, [:path] do |t, args|
    require "json"
    secret_to_insert = File.read("app_secrets").to_s
    #secrets_json = `kubectl exec -n vault --kubeconfig=./kubeconfig -it vault-0 -- vault kv put -format json #{args[:path]} #{secret_to_insert}`
    secrets_json = %x{
      kubectl exec -n vault \
        --kubeconfig=./kubeconfig \
        -it vault-0 \
        -- vault kv put \
        -format json #{args[:path]} #{secret_to_insert}
      }
    $? == 0 ? secrets_json : exit 1
    #puts secrets_json
  end


  desc "Ensure vault-0 pod has been successfully logged into with token. "
  task :login, [] do |t, args|
    cluster_automation = %x{
      kubectl exec \
        --kubeconfig=./kubeconfig \
        -n vault \
        -it vault-0 \
        -- vault login \
        ${VAULT_TOKEN} > /dev/null
      }
    $? == 0 ? "Success" : exit 1
    #system(cluster_automation) or exit 1
  end


  desc "Deploy Helm Files"
  task :helm_deploy_vault, [:app_namespace, :image, :image_tag, :env, :app_name] do |t, args|
    puts "Deploy the Helm Files."
    deoploy_helm = %x{
      helm upgrade #{args[:app_name]} \
      deploy/helm/#{args[:app_name]}-vault \
      --install -n #{args[:app_namespace]} \
      --create-namespace \
      --set image.repository=#{args[:image]} \
      --set image.tag=#{args[:image_tag]} \
      --kubeconfig=./kubeconfig}
    $? == 0 ? "Success" : exit 1
    #system(deoploy_helm) or exit 1

    puts "Use kubectl rollout to wait for pods to start."
    check_kubernetes_rollout_status = %Q{
    sleep 30
    kubectl rollout status --kubeconfig=./kubeconfig deployment/#{args[:app_name]} -n #{args[:app_namespace]}
    }
    system(check_kubernetes_rollout_status) or exit 1
  end


  desc "Check Vault Secret Exists"
  task :check_application_configured, [:app_env, :region, :app_name] do |t, args|
    vault_secret_check = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault \
      -it vault-0 \
      -- vault kv get kv-v2/#{args[:region]}/#{args[:app_env]}/#{args[:app_name]}
    }
    if vault_secret_check.include?("#No value found")
      puts "Application Not Configured Please Run https://github.com/Sifchain/chainOps/actions/workflows/setup_new_application_in_vault.yaml"
      exit 1
    else
      puts "Secret Exists"
    end
  end


  desc "Enable Application and Vault to Talk to Kubernetes."
  task :enable_kubernetes, [] do |t, args|
    check_kubernetes_enabled = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault \
      -it vault-0 \
      -- vault auth list | grep kubernetes
    }
    if check_kubernetes_enabled.include?("kubernetes")
      puts "Kubernetes Already Enabled"
    else
      enable_kubernetes = %x{
        kubectl exec \
        --kubeconfig=./kubeconfig \
        -n vault \
        -it vault-0 \
        -- vault auth enable kubernetes
      }
      $? ==0 ? "Success" : exit 1
      #system(enable_kubernetes) or exit 1
    end
  end


  desc "Generate Temp Secrets For Path"
  task :pull_temp_secrets_file, [:path] do |t, args|
    require "json"
    secrets_json = %x{
      kubectl exec \
      -n vault \
      --kubeconfig=./kubeconfig \
      -it vault-0 \
      -- vault kv get \
      -format json #{args[:path]}
    }
    data = JSON.parse(secrets_json)
    temp_secrets_string = ""
    data['data']['data'].each do |key, value|
      temp_secrets_string += "export #{key}='#{value}' \n"
    end
    File.open("tmp_secrets", 'w') { |file| file.write(temp_secrets_string) }
  end


  desc "Setup Service Account, and Vault Security Connections for Application."
  task :configure_application, [:app_namespace, :image, :image_tag, :env, :app_name] do |t, args|
    service_account = %Q{
apiVersion: v1
kind: ServiceAccount
metadata:
name: #{args[:app_name]}
namespace: #{args[:app_namespace]}
labels:
  app: #{args[:app_name]}
    }
    puts "Create Service Account File."
    puts service_account
    File.open("service_account.yaml", 'w') { |file| file.write(service_account) }

    puts "Create Service Account If It Exists"
    create_service_account = %x{
      kubectl apply \
      --kubeconfig=./kubeconfig \
      -f service_account.yaml \
      -n #{args[:app_namespace]}
    }
    puts create_service_account

    puts "Create Service Account If It Exists"
    create_service_account = %x{
      kubectl apply \
      --kubeconfig=./kubeconfig \
      -f service_account.yaml
    }
    puts create_service_account

    puts "Get the Token from Pod"
    token = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault \
      -it vault-0 \
      -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
      } or exit 1

    puts "Get the Kubernetes Cluster IP"
    kubernetes_cluster_ip = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -it vault-0 \
      -n vault \
      -- printenv \
      | grep KUBERNETES_PORT_443_TCP_ADDR \
      | cut -d '=' -f 2 \
      | tr -d '\\n' \
      | tr -d '\\r'} or exit 1
    puts kubernetes_cluster_ip

    ENV["token"] = token
    ENV["kubernetes_cluster_ip"] = kubernetes_cluster_ip

    puts "Write Auth Config"
    write_config_auth = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault \
      -it vault-0 \
      -- vault write auth/kubernetes/config \
      token_reviewer_jwt="#{ENV["token"]}" \
      kubernetes_host="https://#{ENV["kubernetes_cluster_ip"]}:443" \
      kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt} or exit 1
    puts write_config_auth

    puts "Write Auth Role"
    write_auth_role = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault \
      -it vault-0 \
      -- vault write auth/kubernetes/role/#{args[:app_name]} \
      bound_service_account_names=#{args[:app_name]} \
      bound_service_account_namespaces=#{args[:app_namespace]} \
      policies=#{args[:app_name]} \
      ttl=1h} or exit 1
    puts write_auth_role

    puts "Clean Up"
    remove_service_account = %x{rm -rf service_account.yaml}
    puts remove_service_account

  end


  desc "Create vault policy for application to read secrets."
  task :create_vault_policy, [:region, :app_namespace, :image, :image_tag, :env, :app_name] do |t, args|

    puts "Build Vault Policy File For Application #{args[:app_name]}"
    policy_file = %Q{
path "#{args[:region]}/#{args[:env]}/#{args[:app_name]}" { capabilities = ["read"] }
path "#{args[:region]}/#{args[:env]}/#{args[:app_name]}/*" { capabilities = ["read"] }
path "/#{args[:region]}/#{args[:env]}/#{args[:app_name]}" { capabilities = ["read"] }
path "/#{args[:region]}/#{args[:env]}/#{args[:app_name]}/*" { capabilities = ["read"] }
path "*" { capabilities = ["read"] }
      }
    File.open("#{args[:app_name]}-policy.hcl", 'w') { |file| file.write(policy_file) }

    puts "Copy Policy to the Vault Pod."
    copy_policy_file_to_pod = %x{
      kubectl cp \
      --kubeconfig=./kubeconfig #{args[:app_name]}-policy.hcl \
      vault-0:/home/vault/#{args[:app_name]}-policy.hcl \
      -n vault
    }
    $? ==0 ? "Success" : exit 1
    #system(copy_policy_file_to_pod) or exit 1

    puts "Delete Policy if it Exists for Update"
    delete_policy_if_exists = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault \
      -it vault-0 \
      -- vault policy delete #{args[:app_name]}
    }
    $? ==0 ? "Success" : exit 1
    #system(delete_policy_if_exists) or exit 1

    puts "Write Vault Policy Based on Copied File"
    write_policy = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault -it vault-0 \
      -- vault policy write #{args[:app_name]} \
      /home/vault/#{args[:app_name]}-policy.hcl
    }
    $? ==0 ? "Success" : exit 1
    #system(write_policy) or exit 1

    puts "Enable Policy"
    enable_policy = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault -it vault-0 \
      -- vault write sys/internal/counters/config enabled=enable
    }
    $? ==0 ? "Success" : exit 1
    #system(enable_policy) or exit 1

    puts "Delete the Policy File and Cleanup After."
    File.delete("#{args[:app_name]}-policy.hcl") if File.exist?("#{args[:app_name]}-policy.hcl")

  end


end


desc "Install Vault If Not Exists"
namespace :vault do
  desc "Install Vault into Kubernetes Env Configured"
  task :install, [:env, :region, :path, :aws_role, :aws_region] do |t, args|


    APP_NAME='vault'
    APP_NAMESPACE='vault'
    POD='vault-0'
    SERVICE='vault-internal'
    CSR_NAME='vault-csr'
    NAMESPACE='vault'
    SECRET_NAME="#{APP_NAME}-#{POD}-tls"
    TMPDIR='/tmp'
    KEY_NAME="vault-#{args[:env]}"

    list_keys = %x{
      aws kms list-keys \
      --profile #{args[:env]} \
      --region #{args[:aws_region]}
    }
    keys_object = JSON.parse list_keys
    key_found = false
    key_id = ""

    keys_object["Keys"].each do |v|
      get_key = %x{
        aws kms describe-key \
        --key-id=#{v["KeyId"]} 
        -profile #{args[:env]} 
        -region #{args[:aws_region]}
      }
      get_key_object = JSON.parse get_key
      if get_key_object["KeyMetadata"]["Description"].include?("#{KEY_NAME}")
        puts "key found use id #{v["KeyId"]}"
        key_id = "#{v["KeyId"]}"
        key_found=true
        break
      end
    end

    role_ids = []

    if not key_found
      POLICY = %Q{
        {"Version" : "2012-10-17",
          "Id" : "key-default-#{args[:env]}",
          "Statement" : [{"Sid" : "Enable IAM User Permissions",
                          "Effect" : "Allow", 
                          "Principal" : {"AWS" : "#{args[:aws_role]}"},
                          "Action" : "kms:",
                          "Resource" : "*"},
                        {"Sid" : "Allow Use of Key",
                          "Effect" : "Allow",
                          "Principal" : {"AWS" : "#{args[:aws_role]}"},
                          "Action" : ["*"],"Resource" : "*"}]
          }
        }
      create_key = %x{
        aws kms create-key \
        --tags TagKey=Name,TagValue=#{KEY_NAME} \
        --description "vault-#{args[:env]}" \
        --profile #{args[:env]} \
        --region #{args[:aws_region]} \
        --policy '#{POLICY}'
      }
      key_id_json = JSON.parse create_key
      key_id=key_id_json["KeyMetadata"]["KeyId"]
    end

    check_namespace = %x{kubectl get namespaces --kubeconfig=./kubeconfig | grep vault}
    puts "check namespace #{check_namespace}"
    if check_namespace.empty?
      create_namespace = %x{kubectl create namespace --kubeconfig=./kubeconfig vault}
      puts "create namespace #{create_namespace}"
    else
      puts "Namespace exists"
    end

    delete_secret_if_exists = %x{
      kubectl delete secret \
      -n vault vault-eks-creds \
      --kubeconfig=./kubeconfig \
      --ignore-not-found=true}
    puts delete_secret_if_exists

    create_aws_secret = %x{
      kubectl create secret generic \
      --kubeconfig=./kubeconfig vault-eks-creds \
      --from-literal=AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
      --from-literal=AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
      -n vault}
    puts create_aws_secret

    check_vault_installed = %x{kubectl get pods -n vault --kubeconfig=./kubeconfig | grep vault}
    if check_vault_installed.empty?
      puts "Check if helm repo is installed if not install."
      check_helm_repo_setup = %x{helm repo list --kubeconfig=./kubeconfig | grep hashicorp}
      if check_helm_repo_setup.empty?
        add_helm_repo = %x{helm repo add hashicorp https://helm.releases.hashicorp.com --kubeconfig=./kubeconfig}
        puts "add helm repo #{add_helm_repo}"
        helm_repo_update = %x{helm repo update --kubeconfig=./kubeconfig}
        puts "helm repo update #{helm_repo_update}"
      else
        puts "Namespace exists"
      end
    end

    puts "Template the overrides file for vault."
    template_file_text = File.read("#{args[:path]}override-values.yaml").strip
    ENV.each_pair do |k, v|
      replace_string="-=#{k}=-"
      if replace_string == "-=aws_region=-"
        template_file_text.include?(k) ? (template_file_text.gsub! replace_string, "#{args[:aws_region]}") : (puts 'env matching...')
      elsif replace_string == "-=kmskey=-"
        puts "found kms"
        template_file_text.include?(k) ? (template_file_text.gsub! replace_string, key_id) : (puts 'env matching...')
      elsif replace_string == "-=aws_role=-"
        template_file_text.include?(k) ? (template_file_text.gsub! replace_string, "#{args[:aws_role]}") : (puts 'env matching...')
      end
    end
    File.open("#{args[:path]}override-values.yaml", 'w') { |file| file.write(template_file_text) }

    puts "Check if deployment exists and install if it doesn't"
    check_vault_deployment_exist = %x{kubectl get statefulsets --kubeconfig=./kubeconfig -n vault | grep vault}
    if check_vault_deployment_exist.empty?
      helm_install = %x{
        helm install vault hashicorp/vault \
        --namespace vault -f #{args[:path]}override-values.yaml \
        --kubeconfig=./kubeconfig}
      puts "helm install #{helm_install}"
    else
      helm_upgrade = %x{
        helm upgrade vault hashicorp/vault \
        --namespace vault -f #{args[:path]}override-values.yaml \
        --kubeconfig=./kubeconfig}
      puts "helm upgrade #{helm_upgrade}"
    end

    puts "sleep for 300 seconds to wait for vault to start."
    sleep(180)

    puts "Ensure there is  avault pod that exists as extra mesure to ensure vault is up and running."
    check_vault_pod_exist = %x{kubectl get pod --kubeconfig=./kubeconfig -n vault | grep vault}
    if check_vault_pod_exist.empty?
      puts "Something went wrong no vault pods. #{check_vault_pod_exist}"
      exit 1
    else
      puts "Everything Looks Good. #{check_vault_pod_exist}"
    end
    puts "Check if vault init has been completed."
    check_vault_init = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault -it vault-0 \
      -- vault status | \
      grep Initialized | \
      grep true}
    if check_vault_init.empty?
      puts "Initialize Vault"
      vault_init = %x{
              vault_init_output=$(kubectl exec --kubeconfig=./kubeconfig -n vault vault-0 -- vault operator init -n 1 -t 1)
              sleep 60
              echo -e ${vault_init_output} > vault_output
              VAULT_TOKEN=`echo $vault_init_output | cut -d ':' -f 7 | cut -d ' ' -f 2`
              kubectl exec -n vault --kubeconfig=./kubeconfig -it vault-0 -- vault login ${VAULT_TOKEN} > /dev/null
           }
      $? ==0 ? "Success" : exit 1
      #system(vault_init)
      vault_output = %x{cat vault_output}
      if vault_output.include?("s.")
        upload_to_s3 = %x{
          aws s3 cp ./vault_output \
          s3://sifchain-vault-output-backup/#{args[:env]}/#{args[:region]}/vault-master-keys.$(date  | \
          sed -e 's/ //g').backup --region us-west-2}
        puts upload_to_s3
      else
        puts "vault token not found #{vault_output}"
      end
    else
      puts "Vault Already Inited."
    end

    puts "check kv is enabled"
    check_kv_engine_enabled = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault \
      -it vault-0 -- vault secrets list | \
      grep kv-v2}
    if check_kv_engine_enabled.empty?
      puts "kv not enabled please enable"
      enable_kv_enagine = %x{
        kubectl exec \
        --kubeconfig=./kubeconfig \
        -n vault  vault-0 -- vault secrets enable kv-v2}
      puts "enable kv engine #{enable_kv_enagine}"
    else
      puts "kv engine already enabled."
    end

    puts "create test secret"
    create_test_secret = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault -it vault-0 \
      -- vault kv put kv-v2/staging/test \
      username=test123 \
      password=foobar123}
    puts create_test_secret

    puts "sleep for 30 seconds"
    sleep(30)

    get_test_secret = %x{
      kubectl exec \
      --kubeconfig=./kubeconfig \
      -n vault -it vault-0 \
      -- vault kv get kv-v2/staging/test | \
      grep "test123"}
    if get_test_secret.empty?
      puts "Secret not found"
      exit 1
    else
      puts "Secret Found Vault Running Properly"
    end

  end
end


desc "Generate Temp Secrets For Application Path In Vault"
namespace :vault do
  desc "Generate Temp Secrets For Application Path In Vault"
  task :pull_temp_secrets_file_app, [:app_name,:app_region,:app_env] do |t, args|
    require "json"
    secrets_json = %x{
      kubectl exec \
      -n vault \
      --kubeconfig=./kubeconfig \
      -it vault-0 \
      -- vault kv get \
      -format json kv-v2/#{args[:app_region]}/#{args[:app_env]}/#{args[:app_name]}}
    data = JSON.parse(secrets_json)
    temp_secrets_string = ""
    data['data']['data'].each do |key, value|
      temp_secrets_string += "export #{key}='#{value}' \n"
    end
    File.open("tmp_secrets", 'w') { |file| file.write(temp_secrets_string) }
  end
end


desc "Generate Temp Secrets For Path"
namespace :vault do
  
end


desc "Push Secret To Vault"
namespace :vault do
  
end


desc "Vault Create Policy"
namespace :vault do
  
end


desc "Vault Enable Kubernetes"
namespace :vault do
  
end


desc "Vault Configure Kubernetes for Application"
namespace :vault do
  
end


desc "Check Vault Secret Exists"
namespace :vault do
  
end


desc "Deploy Helm Files"
namespace :vault do
  
end