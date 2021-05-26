desc ""
namespace :chain do
  desc "Chain state operations"
  namespace :state do
    desc "Export chain state"
    task :export, [:file, :node_directory] do |t, args|
      fh = File.open(args[:file], "w")
      if fh.nil?
        puts "unable to open the file #{args[:file]}!"
        exit(1)
      end

      state = `sifnoded export --home #{args[:node_directory]}`
      fh.puts state
      fh.close
    end
  end

  desc "Migrate a chain"
  task :migrate, [:version, :genesis_file, :node_directory] do |t, args|
    system("sifnoded migrate #{args[:version]} #{args[:genesis_file]} --home #{args[:node_directory]}")
  end
end

desc "ebrelayer Operations"
namespace :ebrelayer do
  desc "Deploy a new ebrelayer to an existing cluster"
  task :deploy, [:cluster, :chainnet, :provider, :namespace, :image, :image_tag, :node_host, :eth_websocket_address, :eth_bridge_registry_address, :eth_private_key, :moniker, :mnemonic] do |t, args|
    check_args(args)

    cmd = %Q{helm upgrade ebrelayer #{cwd}/../../deploy/helm/ebrelayer \
      --install -n #{ns(args)} --create-namespace \
      --set image.repository=#{image_repository(args)} \
      --set image.tag=#{image_tag(args)} \
      --set ebrelayer.env.chainnet=#{args[:chainnet]} \
      --set ebrelayer.args.nodeHost=#{args[:node_host]} \
      --set ebrelayer.args.ethWebsocketAddress=#{args[:eth_websocket_address]} \
      --set ebrelayer.args.ethBridgeRegistryAddress=#{args[:eth_bridge_registry_address]} \
      --set ebrelayer.env.ethPrivateKey=#{args[:eth_private_key]} \
      --set ebrelayer.env.moniker=#{args[:moniker]} \
      --set ebrelayer.args.mnemonic=#{args[:mnemonic]}
    }

    system({"KUBECONFIG" => kubeconfig(args)}, cmd)
  end
end

desc "Block Explorer"
namespace :blockexplorer do
  desc "Deploy a Block Explorer to an existing cluster"
  task :deploy, [:cluster, :chainnet, :provider, :namespace, :image, :image_tag, :root_url, :genesis_url, :rpc_url, :api_url, :mongo_password] do |t, args|
    check_args(args)

    cmd = %Q{helm upgrade block-explorer #{cwd}/../../deploy/helm/block-explorer \
      --install -n #{ns(args)} --create-namespace \
      --set image.repository=#{image_repository(args)} \
      --set image.tag=#{image_tag(args)} \
      --set blockExplorer.env.chainnet=#{args[:chainnet]} \
      --set blockExplorer.env.rootURL=#{args[:root_url]} \
      --set blockExplorer.env.genesisURL=#{args[:genesis_url]} \
      --set blockExplorer.env.remote.rpcURL=#{args[:rpc_url]} \
      --set blockExplorer.env.remote.apiURL=#{args[:api_url]} \
      --set blockExplorer.args.mongoPassword=#{args[:mongo_password]}
    }

    system({"KUBECONFIG" => kubeconfig(args)}, cmd)
  end
end

desc "eth operations"
namespace :ethereum do
  desc "Deploy an ETH node"
  task :deploy, [:cluster, :provider, :namespace, :network] do |t, args|
    check_args(args)

    if args.has_key? :network
      network_id =  if args[:network] == "ropsten"
                      3
                    else
                      1
                    end
    end

    if args.has_key? :network
      cmd = %Q{helm upgrade ethereum #{cwd}/../../deploy/helm/ethereum \
          --install -n #{ns(args)} --create-namespace \
          --set geth.args.network='--#{args[:network]}' \
          --set geth.args.networkID=#{network_id} \
          --set ethstats.env.websocketSecret=#{SecureRandom.base64 20}
      }
    else
      cmd = %Q{helm upgrade ethereum #{cwd}/../../deploy/helm/ethereum \
          --install -n #{ns(args)} --create-namespace \
          --set ethstats.env.webSocketSecret=#{SecureRandom.base64 20}
      }
    end

    system({"KUBECONFIG" => kubeconfig(args)}, cmd)
  end
end
