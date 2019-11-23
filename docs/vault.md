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

# Set global Vault Address
set -gx VAULT_ADDR http://127.0.0.1:8200

# Initialize Vault
vault operator init -n 1 -t 1

# Note:
# Notice the Root Token and Unseal Key from the output above, use it below

# Unseal the Vault server
vault operator unseal <Unseal Key>
```

## 2. Configure dedicated vault server to act as a transit server

> Note: Save the wrapping_token

```bash
# Set global Vault Address
set -gx VAULT_ADDR http://127.0.0.1:8200

# Login to the Vault server
vault login <Root Token>

# Enable the transit secrets engine
vault secrets enable transit

# Create a key named 'autounseal'
vault write -f transit/keys/autounseal

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
vault policy write autounseal /vault/config/autounseal.hcl

# Create a client token with autounseal policy attached and response wrap it with TTL of 600 seconds.
vault token create -policy="autounseal" -wrap-ttl=600

# Note:
# Notice the "wrapping_token" from the output above, use it below

# Unwrap the autounseal token and capture the client token
env VAULT_TOKEN=<wrapping_token> \
  vault unwrap

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

# Set global Vault Address
set -gx VAULT_ADDR http://127.0.0.1:8200

# Engage
vault operator init -recovery-shares=1 -recovery-threshold=1

# Note:
# Notice the Unseal Key and Root Token from the output above and keep in a very safe place, use it below

vault operator unseal <Unseal Key>

vault login <Root Token>
```

## 4. Vault Secrets Operator

```bash
# Proxy Vault to our local machine
kubectl -n kube-system port-forward svc/vault 8200:8200

# Set global Vault Address
set -gx VAULT_ADDR http://127.0.0.1:8200

# Log into Vault
vault login <Root Token>

# Enable K/V secrets type
vault secrets enable -path=secrets -version=1 kv

# Create read-only policy for kubernetes
printf "
path \"secrets/*\" {
  capabilities = [\"read\"]
}
" | vault policy write vault-secrets-operator -

# Set Envars
set -gx VAULT_SECRETS_OPERATOR_NAMESPACE (kubectl -n kube-system get sa vault-secrets-operator -o jsonpath="{.metadata.namespace}"); \
set -gx VAULT_SECRET_NAME (kubectl -n kube-system get sa vault-secrets-operator -o jsonpath="{.secrets[*]['name']}"); \
set -gx SA_JWT_TOKEN (kubectl -n kube-system get secret $VAULT_SECRET_NAME -o jsonpath="{.data.token}" | base64 -d; echo); \
set -gx K8S_HOST (kubectl -n kube-system config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Verify Envars
env | grep -E 'VAULT_SECRETS_OPERATOR_NAMESPACE|VAULT_SECRET_NAME|SA_JWT_TOKEN|K8S_HOST'

# Write the certificate to a file (Fish doesn't work as a Envar)
kubectl -n kube-system get secret $VAULT_SECRET_NAME -o jsonpath="{.data['ca\.crt']}" | base64 -d > ~/.kube/k3s.crt

# Enable auth
vault auth enable kubernetes

# Tell Vault how to communicate with the Kubernetes cluster
vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="$K8S_HOST" \
  kubernetes_ca_cert=@~/.kube/k3s.crt

# Check that the config was successfully saved
vault read auth/kubernetes/config

# Create a role named, 'vault-secrets-operator' to map Kubernetes Service Account to Vault policies and default token TTL
vault write auth/kubernetes/role/vault-secrets-operator \
  bound_service_account_names="vault-secrets-operator" \
  bound_service_account_namespaces="$VAULT_SECRETS_OPERATOR_NAMESPACE" \
  policies=vault-secrets-operator \
  ttl=24h

# Check that the config was successfully saved
vault read auth/kubernetes/role/vault-secrets-operator

# Delete Pod to have it rescheduled
kubectl get pods -n kube-system --no-headers=true | awk '/vault-secrets-operator/{print $1}'| xargs kubectl delete -n kube-system pod

```
