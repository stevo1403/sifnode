desc "Kubernetes Create Namespace"
namespace :namespace do
  desc "Create Kubernetes Namespace."
  task :create, [:app_namespace] do |t, args|
    puts "Create Kubernetes Namespace."
    get_namespaces = %x{kubectl get namespaces --kubeconfig=./kubeconfig}
    if get_namespaces.include?("#{args[:app_namespace]}")
      puts "Namespace Exists"
      puts get_namespaces
    else
      puts "Namespace Doesn't Exists"
      puts get_namespaces
      create_namespace = %x{
        kubectl create namespace #{args[:app_namespace]} \
        --kubeconfig=./kubeconfig}
      $? ==0 ? "Created Namespace #{:app_namespace}" : exit 1
      #system(create_namespace) or exit 1
    end
  end
end

#moved kubernetes:helm_mongo_deploy to supporting_applications:mogo_db:mongo_deploy_helm

desc "Deploy Kubernetes Manifest"
namespace :kubernetes do
  desc "Deploy Kubernetes Manifest"
  task :manifest_deploy, [:app_namespace, :image, :image_tag, :env, :app_name] do |t, args|
    puts "Deploy the Helm Files."
    deoploy_manifest = %Q{kubectl apply -f deploy/manifests/#{args[:app_name]}/deployment.yaml -n #{args[:app_namespace]} --kubeconfig=./kubeconfig}
    system(deoploy_manifest) or exit 1
  end
end

#moved kubernetes:install_strimzi to supporting_application:strimzi:install_strimzi

desc "Check statefulset pods have come up."
namespace :kubernetes do
  desc "Check kubernetes stateful set to match replica count"
  task :stateful_set_status_check, [:APP_NAME, :APP_NAMESPACE, :REPLICA_COUNT] do |t, args|
      was_successful = false
      max_loops = 20
      loop_count = 0
      until was_successful == true
          ss_check = `kubectl get statefulset -n #{args[:APP_NAMESPACE]} --kubeconfig=./kubeconfig | grep #{args[:APP_NAME]} | grep "#{args[:REPLICA_COUNT]}/#{args[:REPLICA_COUNT]}"`
          if ss_check.empty?()
              loop_count += 1
              puts "On Loop #{loop_count} of #{max_loops}"
              if loop_count >= max_loops
                  puts "Reached Max Loops"
                  break
              end
          else
              #:SEARCH_PATH "new transaction witnessed in sifchain client."
              puts "Number of Specified Replicas available."
              was_successful = true
              break
          end
          sleep(60)
      end
  end
end

desc "Check kubernetes pod for specific log entry to ensure valid deployment."
namespace :kubernetes do
  desc "Check kubernetes pod for specific log entry to ensure valid deployment."
  task :log_validate_search, [:APP_NAME, :APP_NAMESPACE, :SEARCH_PATH] do |t, args|
    ENV["APP_NAMESPACE"] = "#{args[:APP_NAMESPACE]}"
    ENV["APP_NAME"] = "#{args[:APP_NAME]}"
    was_successful = false
    max_loops = 20
    loop_count = 0
    until was_successful == true
      pod_name = `kubectl get pods --kubeconfig=./kubeconfig -n #{ENV["APP_NAMESPACE"]} | grep #{ENV["APP_NAME"]} | cut -d ' ' -f 1`.strip
      puts "looking up logs fo #{pod_name}"
      pod_logs = `kubectl logs #{pod_name} --kubeconfig=./kubeconfig -n #{ENV["APP_NAMESPACE"]}`
      if pod_logs.include?(args[:SEARCH_PATH])
        #:SEARCH_PATH "new transaction witnessed in sifchain client."
        puts "Log Search Completed Container Running and Producing Valid Logs"
        was_successful = true
        break
      end
      loop_count += 1
      puts "On Loop #{loop_count} of #{max_loops}"
      if loop_count >= max_loops
        puts "Reached Max Loops"
        break
      end
      sleep(60)
    end
  end
end

desc "Check kubernetes pod for specific log entry to ensure valid deployment."
namespace :kubernetes do
  desc "Check kubernetes pod for specific log entry to ensure valid deployment."
  task :log_validate_search_bycontainer, [:APP_NAME, :APP_NAMESPACE, :SEARCH_PATH, :CONTAINER] do |t, args|
    ENV["APP_NAMESPACE"] = "#{args[:APP_NAMESPACE]}"
    ENV["APP_NAME"] = "#{args[:APP_NAME]}"
    was_successful = false
    max_loops = 20
    loop_count = 0
    until was_successful == true
      pod_name = `kubectl get pods --kubeconfig=./kubeconfig -n #{ENV["APP_NAMESPACE"]} | grep #{ENV["APP_NAME"]} | cut -d ' ' -f 1`.strip
      puts "looking up logs fo #{pod_name}"
      pod_logs = `kubectl logs #{pod_name} -c #{args[:CONTAINER]} --kubeconfig=./kubeconfig -n #{ENV["APP_NAMESPACE"]}`
      if pod_logs.include?(args[:SEARCH_PATH])
        #:SEARCH_PATH "new transaction witnessed in sifchain client."
        puts "Log Search Completed Container Running and Producing Valid Logs"
        was_successful = true
        break
      end
      loop_count += 1
      puts "On Loop #{loop_count} of #{max_loops}"
      if loop_count >= max_loops
        puts "Reached Max Loops"
        break
      end
      sleep(60)
    end
  end
end

desc "Check kubernetes pod for specific log entry to ensure valid deployment."
namespace :kubernetes do
  desc "Check kubernetes pod for specific log entry to ensure valid deployment."
  task :log_validate, [:APP_NAME, :APP_NAMESPACE, :SEARCH_PATH] do |t, args|
    ENV["APP_NAMESPACE"] = "#{args[:APP_NAMESPACE]}"
    ENV["APP_NAME"] = "#{args[:APP_NAME]}"
    was_successful = false
    max_loops = 20
    loop_count = 0
    until was_successful == true
      pod_name = `kubectl get pods --kubeconfig=./kubeconfig -n #{ENV["APP_NAMESPACE"]} | grep #{ENV["APP_NAME"]} | cut -d ' ' -f 1`.strip
      puts "looking up logs fo #{pod_name}"
      pod_logs = `kubectl logs #{pod_name} --kubeconfig=./kubeconfig -c ebrelayer -n #{ENV["APP_NAMESPACE"]}`
      if pod_logs.include?(args[:SEARCH_PATH])
        #:SEARCH_PATH "new transaction witnessed in sifchain client."
        puts "Log Search Completed Container Running and Producing Valid Logs"
        was_successful = true
        break
      end
      loop_count += 1
      puts "On Loop #{loop_count} of #{max_loops}"
      if loop_count >= max_loops
        puts "Reached Max Loops"
        break
      end
      sleep(60)
    end
  end
end


desc "namespace operations"
namespace :namespace do
  desc "Destroy an existing namespace"
  task :destroy, [:chainnet, :provider, :namespace, :skip_prompt] do |t, args|
    check_args(args)
    are_you_sure(args)
    cmd = "kubectl delete namespace #{args[:namespace]}"
    system({"KUBECONFIG" => kubeconfig(args)}, cmd)
  end
end


desc "Deploy if not exist"
namespace :deployment
  desc "Deploy if not exist"
  task :deploy_if_not_exist, [:DEPLOYMENT_NAME, :NAMESPACE, :REPO_NAME, :ADD_ARGS] do |t, args|
    check_deployed = %x{kubectl get deployment -n #{:NAMESPACE} --kubeconfig=./kubeconfig}
    if check_deployed.include?(:DEPLOYMENT_NAME)
      puts "#{:DEPLOYMENT_NAME already deployed}"
    else
      helm_install = %x{
        helm install \
        #{:DEPLOYMENT_NAME} \
        #{:REPO_NAME} \
        --namespace #{:NAMESPACE} \
        #{ADD_ARGS} \
        --kubeconfig=./kubeconfig}
  end
end


desc "Get rollout status"
namespace :rollout
  desc "Get rollout status"
  task :status, [:TYPE, :SERVICE, :NAMESPACE] do |t, args|
    rollout_status  = %x{
      kubectl rollout status \
      #{:TYPE}/#{:SERVICE} \
      -n #{:NAMESPACE} \
      --kubeconfig=./kubeconfig
    }
    puts rollout_status
  end
end
