# TestNet Repair



## Reset your node

1. Switch into your `sifnode/deploy/docker/testnet` folder.

2. Delete the folders `.sifnoded` and `.sifnodecli`:

```bash
rm -rf .sifnoded .sifnodecli
```

3. Update your testnet `docker-compose.yml` (can be found in `sifnode/deploy/docker/testnet/docker-compose.yml`) with:

```yaml
version: '3'

services:
  sifnode:
    image: sifchain/sifnoded:testnet-0.8.7-hotfix.1
    ports:
      - 26656:26656
      - 26657:26657
    environment:
      CHAINNET: sifchain-testnet
      MONIKER: ${MONIKER}
      MNEMONIC: ${MNEMONIC}
      PEER_ADDRESSES: b4caebe07ab25126e4e6053bf955833198f18ed0@54.216.30.38:26656,b6f113a30e7019b034e8b31cd2541aebebaacb60@54.66.212.111:26656,ffcc2fab592d512eca7f903fd494d85a93e19cfe@122.248.219.121:26656,a2864737f01d3977211e2ea624dd348595dd4f73@3.222.8.87:26656
      GENESIS_URL: https://rpc-testnet.sifchain.finance/genesis
      GAS_PRICE: ${GAS_PRICE}
      BIND_IP_ADDRESS: ${BIND_IP_ADDRESS}
      DAEMON_NAME: sifnoded
      DAEMON_HOME: /root/.sifnoded
      DAEMON_ALLOW_DOWNLOAD_BINARIES: "true"
      DAEMON_RESTART_AFTER_UPGRADE: "true"
    volumes:
      - .:/root:Z
      - ../scripts:/root/scripts:Z
    command: /root/scripts/entrypoint.sh
```

3. Switch back to the top level folder of the sifnode repository:

```bash
cd ../../../
```

4. Boot your node using the rake task (e.g.: `rake genesis:sifnode:boot...`). PLEASE NOTE: The node will fail with the error ` ERROR: error during handshake: error on replay: wrong Block.Header.AppHash.` --- this is OK and is expected.

## Repair

1. Switch into your `sifnode/deploy/docker/testnet/.sifnoded/data` folder.

2. Download the latest snapshot:

```bash
wget https://s3.ap-southeast-1.amazonaws.com/finance.sifchain.snapshots.sifchain-testnet/snapshot-1624522917.tgz
```

3. Unpack the snapshot:

```bash
tar -zxvf snapshot-1624522917.tgz
```

4. Switch back to the top level folder of the sifnode repository:

```bash
cd ../../../../../
```

5. Boot your node using the rake task (e.g.: `rake genesis:sifnode:boot...`).
