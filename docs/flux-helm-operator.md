# Helm, Tiller and Flux

> All these commands are run from your computer, not the RPi.

## Label worker nodes

```bash
# List Nodes
kubectl get nodes

# Label Node
kubectl label node <node-name> node-role.kubernetes.io/worker=worker
```

## Install Helm

```bash
# Helm v3 (Tiller component deprecated)
brew install helm
```

## Flux and Helm Operator

```bash
# Create Namespace
kubectl apply -f deployments/flux/namespace.yaml

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
