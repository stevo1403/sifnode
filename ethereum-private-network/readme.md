# Geth Private Network

You can run a network with `docker-compose up`, which will launch a single bootstrap and member node. You can increase the number of nodes with the command `docker-compose scale eth=N`. To re-set the environment, delete the volumes with `docker-compose stop -v`. 

Once a network is running you can connect to any container with a Geth console. To do so, run this command `docker exec -it <CONTAINER_NAME> geth attach ipc://root/.ethereum/devchain/geth.ipc` where `<CONTAINER_NAME>` can be found with `docker container ls`. 

To start mining, run `miner.start()` from the Geth console and check it's running with `web3.eth.mining`. 

The following addresses have been allocated `1000 Eth` from genesis. 

```
"0x007ccffb7916f37f7aeef05e8096ecfbe55afc2f"
"0x99429f64cf4d5837620dcc293c1a537d58729b68"
"0xca247d7425a29c6645fa991f9151f994a830882d"
"0x794f74c8916310d6a0009bb8a43a5acab59a58ad"
"0x276ecb88715a503b00d1f15af4c17dc051991667"
"0x83042c0147acce98e35ed9ef52e6dfc5c67ef92e"
"0x8ab7114ba0f7ca706af69f799588766c8426aa24"
"0x932d9e95e5d2cac02eebbe6763ab2c7b0a9d6a2f"
"0x893c3f80d2a0375b3f00f856cf8a6775e4efc26a"
"0xb1d3073bcc45462a3b0dfe69902cdd12971efec9"
```

You can pass the `files/password` file as an argument to unlock these addresses. 