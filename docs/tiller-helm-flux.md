# Helm, Tiller and Flux

> All these commands are run from your computer, not the RPi.

## Label worker nodes

```bash
# List Nodes
kubectl get nodes

# Label Node
kubectl label node <node-name> node-role.kubernetes.io/worker=worker
```

## Install Helm2 or Helm3

```bash
# Helm v2 (For use with Tiller)
brew install helm@2
# Helm v3 (Tiller component deprecated)
brew install helm
```

## Tiller

```bash
# Install Tiller
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --tiller-image=jessestuart/tiller:v2.14.3-arm --service-account tiller

# Upgrade Tiller
helm init --upgrade --tiller-image=jessestuart/tiller:v2.15.0-arm --service-account tiller

# View Tiller logs
kubectl -n kube-system describe deployment.apps/tiller-deploy
kubectl -n kube-system logs tiller-deploy-([a-z\-]+)
kubectl -n kube-system describe pod/tiller-deploy-([a-z\-]+)

# Delete Tiller Deployment
kubectl -n kube-system delete deployment tiller-deploy ; \
kubectl -n kube-system delete service tiller-deploy
```

## Flux and Helm Operator

```bash
# Add Flux Charts
helm repo add fluxcd https://charts.fluxcd.io

# Install Flux
helm upgrade --install flux \
    --values deployments/flux/flux/flux-values.yaml \
    --namespace flux \
    fluxcd/flux

# Get your SSH Key and add to your GitHub Profile
kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

# Install Helm Operator
helm upgrade --install helm-operator \
    --values deployments/flux/helm-operator/flux-helm-operator-values.yaml \
    --namespace flux \
    fluxcd/helm-operator

#
# Something went wrong?
#

# Debugging
kubectl -n flux logs deployment.apps/flux
kubectl -n flux logs deployment.apps/helm-operator

# Delete Flux and Helm Operator (Run twice)
helm delete --purge helm-operator ; \
helm delete --purge flux ; \
kubectl delete crd helmreleases.flux.weave.works ; \
kubectl delete crd helmreleases.helm.fluxcd.io
```
