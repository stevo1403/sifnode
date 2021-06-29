# Disable RPC.

## Kubernetes

1. Open up the `sifnode` service definitions:

```bash
KUBECONFIG=<path/to/your/kubeconfig> kubectl edit svc sifnode -n sifnode
```

2. Scroll down in the editor that opens to the ports section. This will look something like:

```yaml
ports:
  - name: p2p
    nodePort: 31361
    port: 26656
    protocol: TCP
    targetPort: 26656
  - name: rpc
    nodePort: 32001
    port: 26657
    protocol: TCP
    targetPort: 26657
```

_don't worry if `nodePort` is different on your cluster, as this value is dynamically assigned when you first set up your cluster_

3. Remove the config for RPC such that your `ports` section now looks something like:

```yaml
ports:
  - name: p2p
    nodePort: 31361
    port: 26656
    protocol: TCP
    targetPort: 26656
```

_again, don't worry if `nodePort` is different on your cluster, as this value is dynamically assigned when you first set up your cluster_

4. Save and exit. Your validator will then update, and the RPC port will no longer be accessible.

## Standalone (Docker)

In your `docker-compose.yml` file (should be found in `deploy/docker/mainnet/`, from where you cloned the Sifnode repository to) remove the line:

```
- 26657:26657
```

and restart the container.
