desc "Create Github Release."
namespace :release do
  desc "Create Github Release."
  task :create_github_release_by_branch, [:branch, :release, :env, :token] do |t, args|
    require 'rest-client'
    require 'json'
    begin
      release_hash = { "devnet" => "DevNet", "testnet" =>"TestNet", "betanet" =>"MainNet" }
      release_target = { "devnet" => "develop", "testnet" =>"testnet", "betanet" =>"master" }
      release_name = release_hash[args[:env]]
      if "#{args[:app_env]}" == "betanet"
        headers = {content_type: :json, "Accept": "application/vnd.github.v3+json", "Authorization":"token #{args[:token]}"}
        payload = {"tag_name"  =>  "mainnet-#{args[:release]}", "target_commitish"  =>  args[:branch], "name"  =>  "#{release_name} v#{args[:release]}","body"  => "Sifchain MainNet Release v#{args[:release]}","prerelease"  =>  true}.to_json
        response = RestClient.post 'https://api.github.com/repos/Sifchain/sifnode/releases', payload, headers
        json_response_job_object = JSON.parse response.body
        puts json_response_job_object
      else
        headers = {content_type: :json, "Accept": "application/vnd.github.v3+json", "Authorization":"token #{args[:token]}"}
        payload = {"tag_name"  =>  "#{args[:env]}-#{args[:release]}", "target_commitish"  =>  args[:branch], "name"  =>  "#{release_name} v#{args[:release]}","body"  => "Sifchain #{args[:env]} Release v#{args[:release]}","prerelease"  =>  true}.to_json
        response = RestClient.post 'https://api.github.com/repos/Sifchain/sifnode/releases', payload, headers
        json_response_job_object = JSON.parse response.body
        puts json_response_job_object
      end
    rescue
      puts 'Release Already Exists'
    end
  end
end

desc "Create create_github_release_by_branch_and_repo."
namespace :release do
  desc "Create create_github_release_by_branch_and_repo."
  task :create_github_release_by_branch_and_repo, [:branch, :release, :env, :token, :repo] do |t, args|
    require 'rest-client'
    require 'json'
      release_hash = { "develop" => "DevNet", "testnet" =>"TestNet", "master" =>"MainNet" }
      release_target = { "devnet" => "develop", "testnet" =>"testnet", "betanet" =>"master" }
      puts release_hash
      puts args[:env]
      puts args[:repo]
      puts args[:branch]
      puts args[:release]
      release_name = release_hash[args[:env]]
      puts "Release Name #{release_name}"
      if "#{args[:app_env]}" == "betanet"
        headers = {content_type: :json, "Accept": "application/vnd.github.v3+json", "Authorization":"token #{args[:token]}"}
        payload = {"tag_name"  =>  "mainnet-#{args[:release]}", "target_commitish"  =>  args[:branch], "name"  =>  "#{release_name} v#{args[:release]}","body"  => "#{args[:repo]} MainNet Release v#{args[:release]}","prerelease"  =>  true}.to_json
        url = "https://api.github.com/repos/Sifchain/#{args[:repo]}/releases"
        puts "github api url #{url}"
        response = RestClient.post url, payload, headers
        json_response_job_object = JSON.parse response.body
        puts json_response_job_object
      else
        headers = {content_type: :json, "Accept": "application/vnd.github.v3+json", "Authorization":"token #{args[:token]}"}
        payload = {"tag_name"  =>  "#{args[:env]}-#{args[:release]}", "target_commitish"  =>  args[:branch], "name"  =>  "#{release_name} v#{args[:release]}","body"  => "#{args[:repo]} #{args[:env]} Release v#{args[:release]}","prerelease"  =>  true}.to_json
        url = "https://api.github.com/repos/Sifchain/#{args[:repo]}/releases"
        puts "github api url #{url}"
        response = RestClient.post url, payload, headers
        json_response_job_object = JSON.parse response.body
        puts json_response_job_object
      end
  end
end

desc "Wait for Release Pipeline to Finish."
namespace :release do
  desc "Wait for Release Pipeline to Finish."
  task :wait_for_release_pipeline, [:APP_ENV, :RELEASE, :GIT_TOKEN] do |t, args|
    require 'rest-client'
    require 'json'
    job_succeeded = false
    max_loops = 20
    loop_count = 0
    until job_succeeded == true
      headers = {"Accept": "application/vnd.github.v3+json","Authorization":"token #{args[:GIT_TOKEN]}"}
      response = RestClient.get 'https://api.github.com/repos/Sifchain/sifnode/actions/workflows', headers
      find_release="#{args[:APP_ENV]}-#{args[:RELEASE]}"
      json_response_object = JSON.parse response.body
      json_response_object["workflows"].each do |child|
        if child["name"] == "Release"
          workflow_id = child["id"]
          response = RestClient.get "https://api.github.com/repos/Sifchain/sifnode/actions/workflows/#{workflow_id}/runs", headers
          json_response_job_object = JSON.parse response.body
          job = json_response_job_object["workflow_runs"].first()
          if job["head_branch"] == find_release
            puts "Release Job: #{job["head_branch"]} finished with state: #{job["status"]}"
            puts job
            if job["status"].include?("completed")
              puts job["head_branch"]
              puts job["status"]
              puts job["conclusion"]
              job_succeeded = true
              break
            else
              puts job["head_branch"]
              puts job["status"]
              puts job["conclusion"]
            end
          end
        end
      end
      loop_count += 1
      puts loop_count
      puts "On Loop #{loop_count} of #{max_loops}"
      if loop_count >= max_loops
        puts "Reached Max Loops"
        exit 1
      end
      sleep(60)
    end
  end
end