#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "kubeseal"
need "kubectl"
need "sed"

. "$REPO_ROOT"/setup/secrets/.env

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

PUB_CERT="$REPO_ROOT"/setup/secrets/pub-cert.pem

kseal() {
    name=$(basename -s .txt "$@")
    if [[ -z "$NS" ]]; then
      NS=default
    fi
    envsubst < "$@" > values.yaml | kubectl -n "$NS" create secret generic "$name" --from-file=values.yaml --dry-run -o json | kubeseal --format=yaml --cert="$REPO_ROOT"/setup/pub-cert.pem && rm values.yaml
}

#
# Secrets
#

kubectl create secret generic cloudflare-ddns \
  --from-literal=api-key="$CF_APIKEY" \
  --from-literal=user="$CF_USER" \
  --from-literal=zones="$CF_ZONES" \
  --from-literal=hosts="$CF_HOSTS" \
  --from-literal=record-types="$CF_RECORDTYPES" \
  --namespace default --dry-run -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/secrets/cloudflare-ddns.yaml

# kubectl create secret generic traefik-basic-auth-devin \
#   --from-literal=auth="$DEVIN_AUTH" \
#   --namespace traefik --dry-run -o json \
#   | \
# kubeseal --format=yaml --cert="$PUB_CERT" \
#     > "$REPO_ROOT"/deployments/secrets/traefik-basic-auth.yaml