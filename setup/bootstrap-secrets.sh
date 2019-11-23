#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "vault"
need "kubectl"
need "sed"

. "$REPO_ROOT"/setup/.env

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

kvault() {
  name="secrets/$(dirname "$@")/$(basename -s .txt "$@")"
  echo "Writing $name to vault"
  if output=$(envsubst < "$REPO_ROOT/deployments/$*"); then
    printf '%s' "$output" | vault kv put "$name" values.yaml=-
  fi
}

loginVault() {
  message "logging into vault"
  kubectl -n kube-system port-forward svc/vault 8200:8200 >/dev/null 2>&1 &
  VAULT_FWD_PID=$!
  sleep 5

  export VAULT_ADDR='http://127.0.0.1:8200'

  if [ -z "$VAULT_ROOT_TOKEN" ]; then
    echo "VAULT_ROOT_TOKEN is not set! Check $REPO_ROOT/setup/.env"
    exit 1
  fi

  vault login -no-print "$VAULT_ROOT_TOKEN" || exit 1

  vault auth list >/dev/null 2>&1
  if [[ "$?" -ne 0 ]]; then
    echo "not logged into vault!"
    echo "1. port-forward the vault service (e.g. 'kubectl -n kube-system port-forward svc/vault 8200:8200 &')"
    echo "2. set VAULT_ADDR (e.g. 'export VAULT_ADDR=http://localhost:8200')"
    echo "3. login: (e.g. 'vault login <some token>')"
    exit 1
  fi
}

loadSecretsToVault() {
    message "Writing secrets to vault"
    vault kv put secrets/default/cloudflare-ddns user="$CF_USER"
    vault kv put secrets/default/cloudflare-ddns api-key="$CF_APIKEY"
    vault kv put secrets/default/cloudflare-ddns zones="$CF_ZONES"
    vault kv put secrets/default/cloudflare-ddns hosts="$CF_HOSTS"
    vault kv put secrets/default/cloudflare-ddns record-types="$CF_RECORDTYPES"
}

loginVault
loadSecretsToVault

kill $VAULT_FWD_PID