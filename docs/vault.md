# Vault

Vault is implemented with a [transit seal type](https://www.vaultproject.io/docs/configuration/seal/transit.html) with a dedicated 'transit' vault on a remote host outside of the kubernetes cluster. In this case, it's a raspberry pi3b host running vault as a docker container.

Instructions inspired from auto [unseal with transit guide](https://learn.hashicorp.com/vault/operations/autounseal-transit)

Prerequisites:

- Docker
- `vault` CLI

## 1. Install a dedicated Vault transit server outside of the k3s cluster

> Note: Save the Root token and Unseal key

```bash
# Make persistent directories and set permissions
mkdir -p /vault/{config,data}
mkdir -p /vault/data
sudo chown 100:100 vault/data

# Make initial config file
tee /vault/config/config.hcl <<EOF
storage "file" {
    path = "/vault/data"
}

listener "tcp" {
  tls_disable = 1
  address = "[::]:8200"
  cluster_address = "[::]:8201"
}
EOF

# Run Vault server
docker run -d --name vault \
    --cap-add=IPC_LOCK \
    -p 8200:8200 \
    -v /vault/config:/vault/config \
    -v /vault/data:/vault/data \
    vault server

# Initialize Vault
env VAULT_ADDR=http://127.0.0.1:8200 vault operator init -n 1 -t 1

# Note:
# Notice the Root Token and Unseal Key from the output above, use it below

# Unseal the Vault server
env VAULT_ADDR=http://127.0.0.1:8200 vault operator unseal <Unseal Key>
```

## 2. Configure dedicated vault server to act as a transit server

> Note: Save the wrapping_token

```bash
# Login to the Vault server
env VAULT_ADDR=http://127.0.0.1:8200 vault login <Root Token>

# Enable the transit secrets engine
env VAULT_ADDR=http://127.0.0.1:8200 vault secrets enable transit

# Create a key named 'autounseal'
env VAULT_ADDR=http://127.0.0.1:8200 vault write -f transit/keys/autounseal

# Create a policy file
tee /vault/config/autounseal.hcl <<EOF
path "transit/encrypt/autounseal" {
   capabilities = [ "update" ]
}

path "transit/decrypt/autounseal" {
   capabilities = [ "update" ]
}
EOF

# Create an 'autounseal' policy
env VAULT_ADDR=http://127.0.0.1:8200 vault policy write autounseal /vault/config/autounseal.hcl

# Create a client token with autounseal policy attached and response wrap it with TTL of 600 seconds.
env VAULT_ADDR=http://127.0.0.1:8200 vault token create -policy="autounseal" -wrap-ttl=600

# Note:
# Notice the "wrapping_token" from the output above, use it below

# Unwrap the autounseal token and capture the client token
env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=<wrapping_token> vault unwrap

# Note:
# Notice the "token" from the output above, use it below

# Populate a special kubernetes secret leveraged by the Vault helm chart to populate the $VAULT_TOKEN env variable.
kubectl --namespace kube-system create secret generic vault --from-literal=vault-unwrap-token="<token>"
```

## 3. Initialize Vault

> Note: If you commited and pushed the Vault Helm chart will be deployed.
> Vault won't be in a ready state until we initialize it below

```bash
# Proxy Vault to our local machine
kubectl -n kube-system port-forward svc/vault 8200:8200

# Engage
env VAULT_ADDR='http://127.0.0.1:8200' vault operator init -recovery-shares=1 -recovery-threshold=1

# Note:
# Notice the Unseal Key and Root Token from the output above and keep in a very safe place, use it below

env VAULT_ADDR='http://127.0.0.1:8200' vault operator unseal <Unseal Key>
env VAULT_ADDR='http://127.0.0.1:8200' vault login <Root Token>
```
