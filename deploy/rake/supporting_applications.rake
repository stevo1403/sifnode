desc "Deploy Mongo"
namespace :mongo_db do
  desc "Deploy Mongo"
  task :mongo_deploy_helm, [:ROOT_PASSWORD, :USERNAME, :PASSWORD, :DATABASE] do |t, args|
    puts "Deploy the Helm Files."
    deoploy_helm = %x{
          helm repo add bitnami https://charts.bitnami.com/bitnami --kubeconfig=./kubeconfig
          helm repo update --kubeconfig=./kubeconfig
          helm upgrade mongodb --install \
          -n mongodb \
          -f deploy/helm/mongodb/values.yaml \
          --set auth.rootPassword="#{args[:ROOT_PASSWORD]}" \
          --set auth.username="#{args[:USERNAME]}" \
          --set auth.password="#{args[:PASSWORD]}" \
          --set auth.database="#{args[:DATABASE]}" \
          bitnami/mongodb --create-namespace --kubeconfig=./kubeconfig
    }
    $? ==0 ? "Success" : exit 1
    #system(deoploy_helm) or exit 1
  end
end

desc "Install Strimzi"
namespace :strimzi do
  desc "Install Strimzi"
  task :install_strimzi, [] do |t, args|
    puts "Deploy the Helm Files."
    install_strimzi = %x{
      check_strimz_installed=$(kubectl get pods --all-namespaces --kubeconfig=./kubeconfig | grep "strimzi-cluster-operator")
      if [ -z "${check_strimz_installed}" ]; then
              echo "Strimzi not installed install strimzi"
              helm repo add strimzi https://strimzi.io/charts/ --kubeconfig=./kubeconfig
              helm repo update --kubeconfig=./kubeconfig
              helm install strimzi-kafka strimzi/strimzi-kafka-operator --kubeconfig=./kubeconfig
      else
          echo "Strimzi installed alread."
      fi
    }
    $? ==0 ? "Success" : exit 1
    #system(install_strimzi) or exit 1
  end
end

namespace :openapi do
  namespace :deploy do
    desc "Deploy OpenAPI - Swagger documentation ui"
    task :swaggerui, [:chainnet, :provider, :namespace] do |t, args|
      check_args(args)

      cmd = %x{helm upgrade swagger-ui #{cwd}/../../deploy/helm/swagger-ui \
        --install -n #{ns(args)} --create-namespace \
      }
      $? ==0 ? "Success" : exit 1
      #system({"KUBECONFIG" => kubeconfig(args)}, cmd)
    end

    desc "Deploy OpenAPI - Prism Mock server "
    task :prism, [:chainnet, :provider, :namespace] do |t, args|
      check_args(args)

      cmd = %Q{helm upgrade prism #{cwd}/../../deploy/helm/prism \
        --install -n #{ns(args)} --create-namespace \
      }

      system({"KUBECONFIG" => kubeconfig(args)}, cmd)
    end
  end
end

desc "Install Cert-Manager If Not Exists"
namespace :certmanager do
  desc "Install Cert-Manager Into Kubernetes"
  task :install, [] do |t, args|
    service = "cert-manager"
    namespace = "cert-manager"
    kubernetes:namespace:create[namespace]
    helm:repo:add_chart["jetstack", "https://charts.jetstack.io"]
    kubernetes:deployment:deploy_if_not_exist[service, namespace, "jetstack/cert-manager", "--version v1.2.0 --set installCRDs=true"]
    kubernetes:rollout:status["deployment", service, namespace]

  end
end