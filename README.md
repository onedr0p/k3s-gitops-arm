# homelab-gitops (ARM Edition)

## Install Kubernetes

All Commands here are run on the Master Node

```bash
# Install kubeadm
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo apt-get update
sudo apt-get install -qy kubeadm

# Install Kubernetes
#
# Note the `kubeadm join` command in the output, you will need this to add workers to your Cluster
#
kubeadm config images pull
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Use the Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Check if everything is golden (if not reset and try again)
kubectl get all --all-namespaces

# Reset
sudo kubeadm reset
rm -rf $HOME/.kube/config
```

## Join Worker Nodes

All commands below are run on the Worker Nodes

```bash
# Install kubeadm
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo apt-get update
sudo apt-get install -qy kubeadm

# Join node to the Cluster
sudo kubeadm join ...
```

kubectl label node <node-name> node-role.kubernetes.io/worker=worker

## Taint Worker Nodes

```bash
# List Nodes
kubectl get nodes

# Taint Node
kubectl taint nodes <node-name> arm=true:NoExecute
```

## Tiller

```bash
# Install Tiller
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller

# Install Tiller
helm init --tiller-image=jessestuart/tiller:v2.14.3-arm --service-account tiller \
    --override 'spec.template.spec.tolerations[0].key'='arm' \
    --override 'spec.template.spec.tolerations[0].operator'='Exists'

# Upgrade Tiller
helm init --upgrade --tiller-image=jessestuart/tiller:v2.15.0-arm --service-account tiller \
    --override 'spec.template.spec.tolerations[0].key'='arm' \
    --override 'spec.template.spec.tolerations[0].operator'='Exists'

# Delete Tiller Deployment
kubectl delete deployment tiller-deploy --namespace kube-system
```

## Flux and Helm Operator

```bash
# Add Flux Charts
helm repo add fluxcd https://charts.fluxcd.io

# Install Flux
helm upgrade --install flux \
    --values flux/flux/flux-values.yaml \
    --namespace flux \
    fluxcd/flux

# Install Helm Operator
helm upgrade --install helm-operator \
    --values flux/helm-operator/flux-helm-operator-values.yaml \
    --namespace flux \
    fluxcd/helm-operator

# Delete Flux and Helm Operator
helm delete --purge helm-operator; \
helm delete --purge flux; \
kubectl delete crd helmreleases.flux.weave.works; \
kubectl delete crd helmreleases.helm.fluxcd.io
```
