#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "kubeseal"
need "kubectl"
need "sed"

. "${REPO_ROOT}/setup/.env"

PUB_CERT="${REPO_ROOT}/setup/pub-cert.pem"

# Helper function to generate secrets
kseal() {
  # Get the path and basename of the txt file
  # e.g. "deployments/default/pihole/pihole-helm-values"
  secret="$(dirname "$@")/$(basename -s .txt "$@")"
  echo "Secret: ${secret}"
  # Get the filename without extension
  # e.g. "pihole-helm-values"
  secret_name=$(basename "${secret}")
  echo "Secret Name: ${secret_name}"
  # Extract the Kubernetes namespace from the secret path
  # e.g. default
  namespace="$(echo "${secret}" | awk -F /deployments/ '{ print $2; }' | awk -F / '{ print $1; }')"
  echo "Namespace: ${namespace}"
  # Create secret and put it in the applications deployment folder
  # e.g. "deployments/default/pihole/pihole-helm-values.yaml"
  envsubst < "$@" > values.yaml \
    | \
  kubectl -n "${namespace}" create secret generic "${secret_name}" \
    --from-file=values.yaml --dry-run -o json \
    | \
  kubeseal --format=yaml --cert="$PUB_CERT" \
    > \
      "${secret}.yaml"
  # Clean up temp file
  rm values.yaml

  echo "Done"
}

#
# Helm Secrets
#

# kseal "${REPO_ROOT}/deployments/default/pihole/pihole-helm-values.txt"

#
# Generic Secrets
#

# Cloudflare DDNS
kubectl create secret generic cloudflare-ddns \
  --from-literal=api-key="$CF_APIKEY" \
  --from-literal=user="$CF_USER" \
  --from-literal=zones="$CF_ZONES" \
  --from-literal=hosts="$CF_HOSTS" \
  --from-literal=record-types="$CF_RECORDTYPES" \
  --namespace default --dry-run -o json \
  | \
kubeseal --format=yaml --cert="$PUB_CERT" \
    > "$REPO_ROOT"/deployments/default/cloudflare-ddns/sealed.yaml

# # NginX Basic Auth - default Namespace
# kubectl create secret generic nginx-basic-auth-devin \
#   --from-literal=auth="$DEVIN_AUTH" \
#   --namespace default --dry-run -o json \
#   | \
# kubeseal --format=yaml --cert="$PUB_CERT" \
#     > "$REPO_ROOT"/deployments/kube-system/nginx/sealed-basic-auth-devin.yaml

# # NginX Basic Auth - kube-system Namespace
# kubectl create secret generic nginx-basic-auth-devin \
#   --from-literal=auth="$DEVIN_AUTH" \
#   --namespace kube-system --dry-run -o json \
#   | \
# kubeseal --format=yaml --cert="$PUB_CERT" \
#     > "$REPO_ROOT"/deployments/kube-system/nginx/sealed-basic-auth-kube-system.yaml




