require "securerandom"

desc "management processes for the kube cluster and terraform commands"
namespace :cluster do
  desc "Scaffold new cluster environment configuration"
  task :scaffold, [:cluster, :provider] do |t, args|
    check_args(args)

    # create path location
    system("mkdir -p #{cwd}/../../.live")
    system("mkdir #{path(args)}") or exit

    # create config from template
    system("go run github.com/belitre/gotpl #{cwd}/../terraform/template/aws/cluster.tf.tpl \
      --set chainnet=#{args[:cluster]} > #{path(args)}/main.tf")

    system("go run github.com/belitre/gotpl #{cwd}/../terraform/template/aws/.envrc.tpl \
      --set chainnet=#{args[:cluster]} > #{path(args)}/.envrc")

    # init terraform
    system("cd #{path(args)} && terraform init")

    puts "Cluster configuration scaffolding complete: #{path(args)}"
  end

  desc "Deploy a new cluster"
  task :deploy, [:cluster, :provider] do |t, args|
    check_args(args)
    puts "Deploy cluster config: #{path(args)}"
    system("cd #{path(args)} && terraform apply -auto-approve") or exit 1
    puts "Cluster #{path(args)} created successfully"
  end

  desc "Destroy a cluster"
  task :destroy, [:cluster, :provider] do |t, args|
    check_args(args)
    puts "Destroy running cluster: #{path(args)}"
    system("cd #{path(args)} && terraform destroy") or exit 1
    puts "Cluster #{path(args)} destroyed successfully"
  end

#moved openapi:deploy to supporting_applications:openapi:deploy

#moved the sifnode namespace to sifnode.rake

#moved ebrelayer:deploy to chain:ebrelayer:deploy

#moved vault:deploy to vault:vault:deploy

  #======================================= PIPELINE AUTOMATION RUBY CONVERSIONS =============================================#
#moved vault:login to vault:vault:login

  desc "Sifchain Art."
  namespace :generate do
    desc "Sifchain Art."
    task :art, [] do |t, args|

      cluster_automation = %Q{
#!/usr/bin/env bash
set +x
echo '                       iiii     ffffffffffffffff                 hhhhhhh                                 iiii'
echo '                      i::::i   f::::::::::::::::f                h:::::h                                i::::i'
echo '                       iiii   f::::::::::::::::::f               h:::::h                                 iiii'
echo '                              f::::::fffffff:::::f               h:::::h'
echo '        ssssssssss   iiiiiii  f:::::f       ffffffcccccccccccccccch::::h hhhhh         aaaaaaaaaaaaa   iiiiiiinnnn  nnnnnnnn'
echo '      ss::::::::::s  i:::::i  f:::::f           cc:::::::::::::::ch::::hh:::::hhh      a::::::::::::a  i:::::in:::nn::::::::nn'
echo '    ss:::::::::::::s  i::::i f:::::::ffffff    c:::::::::::::::::ch::::::::::::::hh    aaaaaaaaa:::::a  i::::in::::::::::::::nn'
echo '    s::::::ssss:::::s i::::i f::::::::::::f   c:::::::cccccc:::::ch:::::::hhh::::::h            a::::a  i::::inn:::::::::::::::n'
echo '     s:::::s  ssssss  i::::i f::::::::::::f   c::::::c     ccccccch::::::h   h::::::h    aaaaaaa:::::a  i::::i  n:::::nnnn:::::n'
echo '       s::::::s       i::::i f:::::::ffffff   c:::::c             h:::::h     h:::::h  aa::::::::::::a  i::::i  n::::n    n::::n'
echo '          s::::::s    i::::i  f:::::f         c:::::c             h:::::h     h:::::h a::::aaaa::::::a  i::::i  n::::n    n::::n'
echo '    ssssss   s:::::s  i::::i  f:::::f         c::::::c     ccccccch:::::h     h:::::ha::::a    a:::::a  i::::i  n::::n    n::::n'
echo '    s:::::ssss::::::si::::::if:::::::f        c:::::::cccccc:::::ch:::::h     h:::::ha::::a    a:::::a i::::::i n::::n    n::::n'
echo '    s::::::::::::::s i::::::if:::::::f         c:::::::::::::::::ch:::::h     h:::::ha:::::aaaa::::::a i::::::i n::::n    n::::n'
echo '     s:::::::::::ss  i::::::if:::::::f          cc:::::::::::::::ch:::::h     h:::::h a::::::::::aa:::ai::::::i n::::n    n::::n'
echo '      sssssssssss    iiiiiiiifffffffff            cccccccccccccccchhhhhhh     hhhhhhh  aaaaaaaaaa  aaaaiiiiiiii nnnnnn    nnnnnn'
      }
      system(cluster_automation) or exit 1
    end
  end

#moved automation:configure_aws_credentials to local_config:automation:configure_aws_credentials

#moved certmanager:install to supporting_applications:certmanager:install

#moved vault:install to vault.rake

#moved anchore:scan to security:anchore:scan
#move anchore:scan_by_path to security:anchore:scan_by_path

#moved vault:pull_temp_secrets_file_app to vault.rake

#moved vault:pull_temp_secrets_file to vault.rake

#moved vault:push_secret_to_vault to vault.rake


  desc "Utility for Doing Variable Replacement"
  namespace :utilities do
    desc "Utility for Doing Variable Replacement"
    task :template_variable_replace, [:template_file_name, :final_file_name] do |t, args|
      variable_template_replace(args[:template_file_name], args[:final_file_name])
    end
  end

#moved vault:create_vault_policy to vault.rake

#moved vault:enable_kubernetes to vault.rake

#moved vault:configure_application to vault.rake

#moved anchore:image_scan to security:anchore:image_scan

#moved vault:check_application_configured to vault.rake

#moved kubernetes:create_namespace to kubernetes.rake

#moved vault:helm_deploy_vault to vault.rake

#moved kubernetes:helm_mongo_deploy to kubernetes.rake

#moved kubernetes:manifest_deploy to kubernetes.rake

#moved kubernetes:install_strimzi to kubernetes.rake

#moved kubernetes:stateful_set_status_check to kubernetes.rake

#moved kubernetes:log_validate_search to kubernetes.rake

#moved kubernetes:log_validate_search_bycontainer to kubernetes.rake

#moved kubernetes:log_validate to kubernetes.rake




#moved release:create_github_release_by_branch to github:release:create_github_release_by_branch

#moved release:create_github_release_by_branch_and_repo to github:release:create_github_release_by_branch_and_repo

#moved release:generate_governance_release_request_nopassphrase to governance.rake

#moved release:generate_vote_no_passphrase to governance.rake

#moved release:wait_for_release_pipeline to github:release:wait_for_release_pipeline

  #=======================================RUBY CONVERSIONS END=============================================#

#moved blockexplorer:deploy to chain:blockexplorer:deploy

#moved ethereum:deploy to chain:ethereum:deploy

  desc "logstash operations"
  namespace :logstash do
    desc "Deploy a logstash node"
    task :deploy, [:cluster, :provider, :namespace, :elasticsearch_username, :elasticsearch_password] do |t, args|
      cmd = %Q{helm upgrade logstash #{cwd}/../../deploy/helm/logstash \
            --install -n #{ns(args)} --create-namespace \
            --set logstash.args.cluster=#{args[:cluster]} \
            --set logstash.args.elasticsearchUsername=#{args[:elasticsearch_username]} \
            --set logstash.args.elasticsearchPassword=#{args[:elasticsearch_password]} \
      }

      system({"KUBECONFIG" => kubeconfig(args)}, cmd)
    end
  end

#moved namespace:destroy to kubernetes.rake kubernetes:namespace:destroy
end

#
# Get the path to our terraform config based off the supplied rake args
#
# @param args Arguments passed to rake
#
def path(args)
  return "#{cwd}/../../.live/sifchain-#{args[:provider]}-#{args[:cluster]}" if args.has_key? :cluster

  "#{cwd}/../../.live/sifchain-#{args[:provider]}-#{args[:chainnet]}"
end

#
# Get the path to our kubeconfig based off the supplied rake args
#
# @param args Arguments passed to rake
#
def kubeconfig(args)
  return "#{path(args)}/kubeconfig_sifchain-#{args[:provider]}-#{args[:cluster]}" if args.has_key? :cluster

  "#{path(args)}/kubeconfig_sifchain-#{args[:provider]}-#{args[:chainnet]}"
end

#
# k8s namespace
#
# @param args Arguments passed to rake
#
def ns(args)
  args[:namespace] ? "#{args[:namespace]}" : "sifnode"
end

#
# Image tag
#
# @param args Arguments passed to rake
#
def image_tag(args)
  args[:image_tag] ? "#{args[:image_tag]}" : "testnet"
end

#
# Image repository
#
# @param args Arguments passed to rake
#
def image_repository(args)
  args[:image] ? "#{args[:image]}" : "sifchain/sifnoded"
end
