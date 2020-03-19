#!/usr/bin/env bash

# Modified with credit to: billimek@github

#
# Running this script is dependent on your Ansible inventory file
# Ensure you have the right IPs and hostnames in the right section
#

#
# @CHANGEME - Update USER to your RPi SSH user
#
USER="devin"
K3S_VERSION="v1.17.3+k3s1"

REPO_ROOT=$(git rev-parse --show-toplevel)
ANSIBLE_INVENTORY="${REPO_ROOT}"/ansible/inventory

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "curl"
need "ssh"
need "kubectl"
need "helm"
need "k3sup"
need "ansible-inventory"
need "jq"

K3S_MASTER=$(ansible-inventory -i ${ANSIBLE_INVENTORY} --list | jq -r '.k3s_master[] | @tsv')
K3S_WORKERS=$(ansible-inventory -i ${ANSIBLE_INVENTORY} --list | jq -r '.k3s_worker[] | @tsv')

message() {
  echo -e "\n######################################################################"
  echo "# ${1}"
  echo "######################################################################"
}

k3sMasterNode() {
    message "Installing k3s master to ${K3S_MASTER}"
    k3sup install --ip "${K3S_MASTER}" \
        --k3s-version "${K3S_VERSION}" \
        --user "${USER}" \
        --k3s-extra-args "--no-deploy servicelb --no-deploy traefik --no-deploy metrics-server --default-local-storage-path /k3s-local-storage"
    mkdir -p ~/.kube
    mv ./kubeconfig ~/.kube/config
    sleep 10
}

ks3WorkerNodes() {
    for worker in $K3S_WORKERS; do
        message "Joining ${worker} to ${K3S_MASTER}"
        k3sup join --ip "${worker}" \
            --server-ip "${K3S_MASTER}" \
            --k3s-version "${K3S_VERSION}" \
            --user "${USER}"
            ## Does not work :(
            #--k3s-extra-args "--node-label role.node.kubernetes.io/worker=worker"

        sleep 10

        message "Labeling ${worker} as node-role.kubernetes.io/worker=worker"
        hostname=$(ansible-inventory -i ${ANSIBLE_INVENTORY} --list | jq -r --arg k3s_worker "$worker" '._meta[] | .[$k3s_worker].hostname')
        kubectl label node ${hostname} node-role.kubernetes.io/worker=worker
    done
}

installFlux() {
    message "Installing flux"

    kubectl apply -f "${REPO_ROOT}"/deployments/flux/namespace.yaml

    helm repo add fluxcd https://charts.fluxcd.io
    helm repo update
    helm upgrade --install flux --values "${REPO_ROOT}"/deployments/flux/flux/flux-values.yaml --namespace flux fluxcd/flux
    helm upgrade --install helm-operator --values "${REPO_ROOT}"/deployments/flux/helm-operator/helm-operator-values.yaml --namespace flux fluxcd/helm-operator

    FLUX_READY=1
    while [ ${FLUX_READY} != 0 ]; do
        echo "Waiting for flux pod to be fully ready..."
        kubectl -n flux wait --for condition=available deployment/flux
        FLUX_READY="$?"
        sleep 5
    done
    sleep 5
}

addDeployKey() {
    # grab output the key
    FLUX_KEY=$(kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2)

    message "Adding the key to github automatically"
    "${REPO_ROOT}"/hack/add-repo-key.sh "${FLUX_KEY}"
}

k3sMasterNode
ks3WorkerNodes
installFlux
addDeployKey

sleep 5
message "All done!"
kubectl get nodes -o=wide
