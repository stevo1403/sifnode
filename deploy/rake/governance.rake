desc "Create Release Governance Request."
namespace :release do
  desc "Create Release Governance Request."
  task :generate_governance_release_request_nopassphrase, [:upgrade_hours, :block_time, :deposit, :rowan, :chainnet, :release_version, :from, :app_env, :token, :moniker, :mnemonic] do |t, args|
      require 'rest-client'
      require 'json'

      puts "Looking for the Release Handler"
      release_search = "#{args[:release_version]}"
      setupHandlers = File.read("app/setupHandlers.go").strip
      setupHandlers.include?(release_search) ? (puts 'Found') : (exit 1)

      release_version = "#{args[:app_env]}-#{args[:release_version]}"
      puts "Calculating Upgrade Block Height"
      if "#{args[:app_env]}" == "betanet"
          response = RestClient.get "http://rpc.sifchain.finance/abci_info?"
          json_response_object = JSON.parse response.body
      else
          response = RestClient.get "http://rpc-#{args[:app_env]}.sifchain.finance/abci_info?"
          json_response_object = JSON.parse response.body
      end

      current_height = json_response_object["result"]["response"]["last_block_height"].to_f
      average_block_time = "#{args[:block_time]}".to_f
      average_time = 60 / average_block_time
      average_time = average_time * 60 * "#{args[:upgrade_hours]}".to_f
      future_block_height = current_height + average_time + 100
      block_height = future_block_height.round
      puts "Block Height #{block_height}"

      if "#{args[:app_env]}" == "betanet"
          sha_token=""
          headers = {"Accept": "application/vnd.github.v3+json","Authorization":"token #{args[:token]}"}
          response = RestClient.get 'https://api.github.com/repos/Sifchain/sifnode/releases', headers
          json_response_job_object = JSON.parse response.body
          json_response_job_object.each do |release|
              if release["tag_name"].include?("mainnet-#{args[:release_version]}")
                  release["assets"].each do |asset|
                      if asset["name"].include?(".sha256")
                          response = RestClient.get asset["browser_download_url"], headers
                          sha_token = response.body.strip
                      end
                  end
              end
          end
        else
            sha_token=""
            headers = {"Accept": "application/vnd.github.v3+json","Authorization":"token #{args[:token]}"}
            response = RestClient.get 'https://api.github.com/repos/Sifchain/sifnode/releases', headers
            json_response_job_object = JSON.parse response.body
            json_response_job_object.each do |release|
                if release["tag_name"].include?("#{args[:app_env]}-#{args[:release_version]}")
                    release["assets"].each do |asset|
                        if asset["name"].include?(".sha256")
                            response = RestClient.get asset["browser_download_url"], headers
                            sha_token = response.body.strip
                        end
                    end
                end
            end
        end

        if sha_token.empty?
            puts "No Sha Found"
            exit 1
        end

        puts "Sha found #{sha_token}"

        if "#{args[:app_env]}" == "betanet"
            governance_request = %Q{
make CHAINNET=sifchain IMAGE_TAG=keyring BINARY=sifnodecli build-image
docker run -i sifchain/sifnodecli:keyring sh <<'EOF'
sifnodecli keys add #{args[:moniker]} -i --recover --keyring-backend test <<'EOF'
#{args[:mnemonic]}
\r
EOF
sifnodecli tx gov submit-proposal software-upgrade #{args[:release_version]} \
            --from #{args[:from]} \
            --deposit #{args[:deposit]} \
            --upgrade-height #{block_height} \
            --info '{"binaries":{"linux/amd64":"https://github.com/Sifchain/sifnode/releases/download/mainnet-#{args[:release_version]}/sifnoded-#{args[:app_env]}-#{args[:release_version]}-linux-amd64.zip?checksum='#{sha_token}'"}}' \
            --title #{args[:app_env]}-#{args[:release_version]} \
            --description #{args[:app_env]}-#{args[:release_version]} \
            --node tcp://rpc.sifchain.finance:80 \
            --keyring-backend test \
            -y \
            --chain-id #{args[:chainnet]} \
            --gas-prices "#{args[:rowan]}"
            sleep 60
exit
EOF
             }
            system(governance_request) or exit 1
        else
            puts "create dev net gov request #{sha_token}"
            governance_request = %Q{
make CHAINNET=sifchain IMAGE_TAG=keyring BINARY=sifnodecli build-image
docker run -i sifchain/sifnodecli:keyring sh <<'EOF'
sifnodecli keys add #{args[:moniker]} -i --recover --keyring-backend test <<'EOF'
#{args[:mnemonic]}
\r
EOF
    sifnodecli tx gov submit-proposal software-upgrade #{args[:release_version]} \
       --from #{args[:from]} \
       --deposit #{args[:deposit]} \
       --upgrade-height #{block_height} \
       --info '{"binaries":{"linux/amd64":"https://github.com/Sifchain/sifnode/releases/download/#{args[:app_env]}-#{args[:release_version]}/sifnoded-#{args[:app_env]}-#{args[:release_version]}-linux-amd64.zip?checksum='#{sha_token}'"}}' \
       --title #{args[:app_env]}-#{args[:release_version]} \
       --description #{args[:app_env]}-#{args[:release_version]} \
       --node tcp://rpc-#{args[:app_env]}.sifchain.finance:80 \
       --keyring-backend test \
       -y \
       --chain-id #{args[:chainnet]} \
       --gas-prices "#{args[:rowan]}"
    sleep 60
    exit
EOF
}
         system(governance_request) or exit 1
        end
    end
  end


desc "Create Release Governance Request Vote."
namespace :release do
    desc "Create Release Governance Request Vote."
    task :generate_vote_no_passphrase, [:rowan, :chainnet, :from, :app_env, :moniker, :mnemonic] do |t, args|
        if "#{args[:app_env]}" == "betanet"
            governance_request = %Q{
make CHAINNET=sifchain IMAGE_TAG=keyring BINARY=sifnodecli build-image
docker run -i sifchain/sifnodecli:keyring sh <<'EOF'
sifnodecli keys add #{args[:moniker]} -i --recover --keyring-backend test <<'EOF'
#{args[:mnemonic]}
\r
EOF
vote_id=$(go run ./cmd/sifnodecli q gov proposals --node tcp://rpc.sifchain.finance:80 --trust-node -o json | jq --raw-output 'last(.[]).id' --raw-output)
echo "vote_id $vote_id"
go run ./cmd/sifnodecli tx gov vote ${vote_id} yes \
    --from #{args[:from]} \
    --keyring-backend test \
    --chain-id #{args[:chainnet]}  \
    --node tcp://rpc.sifchain.finance:80 \
    --gas-prices "#{args[:rowan]}" -y
sleep 15
exit
EOF
}
            system(governance_request) or exit 1
        else
            governance_request = %Q{
make CHAINNET=sifchain IMAGE_TAG=keyring BINARY=sifnodecli build-image
docker run -i sifchain/sifnodecli:keyring sh <<'EOF'
sifnodecli keys add #{args[:moniker]} -i --recover --keyring-backend test <<'EOF'
#{args[:mnemonic]}
\r
EOF
vote_id=$(go run ./cmd/sifnodecli q gov proposals --node tcp://rpc-#{args[:app_env]}.sifchain.finance:80 --trust-node -o json | jq --raw-output 'last(.[]).id' --raw-output)
echo "vote_id $vote_id"
go run ./cmd/sifnodecli tx gov vote ${vote_id} yes \
    --from #{args[:from]} \
    --keyring-backend test \
    --chain-id #{args[:chainnet]}  \
    --node tcp://rpc-#{args[:app_env]}.sifchain.finance:80 \
    --gas-prices "#{args[:rowan]}" -y
sleep 15
exit
EOF
}
          system(governance_request) or exit 1
       end
    end
  end
