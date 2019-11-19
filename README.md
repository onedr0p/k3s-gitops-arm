# homelab-gitops (ARM Edition)

Directory Structure

```bash
.
│   # Flux will only scan and deploy from this directory
├── ./deployments
│   # Initial setup of the cluster
└── ./setup
    ├── ./ansible
    └── ./hypriotos
```

> Note: My local shell is [Fish](https://fishshell.com/), some of these commands are specific to the Fish Shell

## HypriotOS

> All these commands are run from your computer, not the RPi.

### Downloads the Flash tool

```bash
sudo curl -L \
    "https://github.com/hypriot/flash/releases/download/2.3.0/flash" \
    -o /usr/local/bin/flash

sudo chmod +x /usr/local/bin/flash
```

### Download and extract the image

```bash
curl -L \
    "https://github.com/hypriot/image-builder-rpi/releases/download/v1.11.4/hypriotos-rpi-v1.11.4.img.zip" \
    -o ~/Downloads/hypriotos-rpi-v1.11.4.img.zip

unzip ~/Downloads/hypriotos-rpi-v1.11.4.img.zip -d ~/Downloads/
```

### Configure and Flash

Update `config.txt` or `user-data-*.yml` as you see fit, add more `user-data-*.yml` files if you have more hosts. My `config.txt` disables hdmi, audio, wifi and bluetooth.

To use WiFi see [this](https://johnwyles.github.io/posts/setting-up-kubernetes-and-openfaas-on-a-raspberry-pi-cluster-using-hypriot/) blog post and adjust the `config.txt` and `user-data-*.yml` accordingly.

```bash
# Replace pik3s01 in the --userdata and --hostname flags
flash \
    --bootconf setup/hypriotos/config.txt \
    --userdata setup/hypriotos/user-data-pik3s01.yml \
    --hostname pik3s01 \
    ~/Downloads/hypriotos-rpi-v1.11.4.img
```

## Ansible

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible-playbook \
    -i setup/ansible/inventory \
    setup/ansible/playbook.yml
```

## k3s

> All these commands are run from your computer, not the RPi.

I will be using [k3sup](https://github.com/alexellis/k3sup) in order to provision our k3s cluster

### k3sup

```bash
# Install k3sup locally
cd ~/Downloads
curl -sLS https://get.k3sup.dev | sh
sudo cp k3sup /usr/local/bin/
k3sup --help

# Install k3s on master node
k3sup install --ip 192.168.1.181 \
    --k3s-version v1.0.0 \
    --user devin \
    --k3s-extra-args '--no-deploy servicelb --no-deploy traefik --no-deploy metrics-server'

# Make kubeconfig accessable globally
mkdir ~/.kube
mv ~/Downloads/kubeconfig ~/.kube/config

# Join worker nodes into the cluster
k3sup join --ip 192.168.1.182 \
    --server-ip 192.168.1.181 \
    --k3s-version v1.0.0 \
    --user devin

k3sup join --ip 192.168.1.183 \
    --server-ip 192.168.1.181 \
    --k3s-version v1.0.0 \
    --user devin

# You should be able to see all your nodes
kubectl get nodes
```

## Kubernetes

> All these commands are run from your computer, not the RPi.

### Label worker nodes

```bash
# List Nodes
kubectl get nodes

# Label Node
kubectl label node <node-name> node-role.kubernetes.io/worker=worker
```

### Tiller

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

### Flux and Helm Operator

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

### Other Debugging

```bash
kubectl -n flux logs pod/helm-operator-857544fb55-zprms

# E1020 17:56:52.250466 1 memcache.go:134] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request

kubectl delete apiservice v1beta1.metrics.k8s.io
```
