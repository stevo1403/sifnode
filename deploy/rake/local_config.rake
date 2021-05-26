
  desc "CONFIGURE AWS PROFILE AND KUBECONFIG"
  namespace :automation do
    desc "Deploy a new ebrelayer to an existing cluster"
    task :configure_aws_credentials, [:APP_ENV, :AWS_ACCESS_KEY_ID, :AWS_SECRET_ACCESS_KEY, :AWS_REGION, :AWS_ROLE, :CLUSTER_NAME] do |t, args|
      require 'fileutils'
      require 'net/http'

      puts "Download aws-iam-authenticator"
      File.write("aws-iam-authenticator", Net::HTTP.get(URI.parse("https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator")))

      puts "Create AWS Directory!"
      FileUtils.mkdir_p("/home/runner/.aws")

      credential_file = %Q{
        [default]
        aws_access_key_id = #{args[:AWS_ACCESS_KEY_ID]}
        aws_secret_access_key = #{args[:AWS_SECRET_ACCESS_KEY]}
        region = #{args[:AWS_REGION]}

        [sifchain-base]
        aws_access_key_id = #{args[:AWS_ACCESS_KEY_ID]}
        aws_secret_access_key = #{args[:AWS_SECRET_ACCESS_KEY]}
        region = #{args[:AWS_REGION]}
      }

      config_file = %Q{
        [profile #{args[:APP_ENV]}]
        source_profile = sifchain-base
        role_arn = #{args[:AWS_ROLE]}
        color = 83000a
        role_session_name = elk_stack
        region = #{args[:AWS_REGION]}
      }

      if ENV["pipeline_debug"] == "true"
        puts "config file"
        puts config_file

        puts "credential file"
        puts credential_file
      end

      puts "Write AWS Config File."
      File.open("/home/runner/.aws/config", 'w') { |file| file.write(config_file) }

      puts "Write AWS Credential File"
      File.open("/home/runner/.aws/credentials", 'w') { |file| file.write(credential_file) }

      puts "Generate Kubernetes Config from configured profile"
      get_kubectl = %Q{
              export PATH=$(pwd):${PATH}
              aws eks update-kubeconfig --name #{args[:CLUSTER_NAME]} \
              --region #{args[:AWS_REGION]} \
              --role-arn #{args[:AWS_ROLE]} \
              --profile #{args[:APP_ENV]} \
              --kubeconfig ./kubeconfig
        }
      system(get_kubectl) or exit 1

      puts "Test Generated Kubernetes Profile"
      test_kubectl = %Q{
            kubectl get pods --all-namespaces --kubeconfig ./kubeconfig
        }
      system(test_kubectl) or exit 1
    end
  end