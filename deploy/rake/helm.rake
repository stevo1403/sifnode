desc "Manages helm charts"
namespace :repo do
    desc "Installs helm chart to k8s repo"
    task :add_chart, [:chart_name, :repo_addr] do |t, args|
        is_installed = %x{helm repo list --kubeconfig=./kubeconfig}
        if is_installed.include?("#{args[:chart_name]}")
            puts "Helm repo: #{:chart_name} already installed"
        else
            add_helm_repo=%x{helm repo add \
                #{:chart_name} \
                #{:repo_addr} \
                --kubeconfig=./kubeconfig}
            puts "add helm repo #{add_helm_repo}"
            helm_repo_update = %x{helm repo update --kubeconfig=./kubeconfig}
            puts "helm repo update #{helm_repo_update}"
end