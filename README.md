# homelab-gitops (ARM Edition)

Tutorial on how to get a Kubernete Cluster up and running on your Raspberry Pis

References:
- https://medium.com/nycdev/k8s-on-pi-9cc14843d43
- https://itnext.io/building-a-kubernetes-cluster-on-raspberry-pi-and-low-end-equipment-part-1-a768359fbba3

## Improve productivity on your local machine

```bash
function k --wraps kubectl -d 'kubectl shorthand'
```

- https://github.com/jorgebucaran/fisher
- https://github.com/evanlucas/fish-kubectl-completions

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

# View Kubernetes objects and wait for them to come active
kubectl get all --all-namespaces

# Use the Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Check if everything is golden (if not reset and try again)
kubectl get all --all-namespaces

#
# Something went wrong?
#

# Debuging
kubectl get events -w

# Reset
sudo kubeadm reset
rm -rf $HOME/.kube/config
```

## Join Worker Nodes

All commands here are run on the Worker Nodes

```bash
# Install kubeadm
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
sudo apt-get update
sudo apt-get install -qy kubeadm

# Join node to the Cluster
sudo kubeadm join ...
```

## Copy kubeconfig to your local machine

```bash
mkdir -p ~/.kube
scp devin@192.168.1.181:~/.kube/config ~/.kube/config

# Test connection
kubectl get pods --all-namespaces
```

## Taint and label Worker Nodes

```bash
# List Nodes
kubectl get nodes

# Label Node
kubectl label node <node-name> node-role.kubernetes.io/worker=worker

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

# View Tiller logs
kubectl logs -n kube-system tiller-deploy-([a-z\-]+)

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

# Get your SSH Key and add to your GitHub Profile
kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

# Install Helm Operator
helm upgrade --install helm-operator \
    --values flux/helm-operator/flux-helm-operator-values.yaml \
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

## Gluster and Heketi

**This section is very opinionated**

I currently have Gluster cluster of Raspberry Pis and I am deploying Heketi that already existing bare cluster. If you're doing the same make sure you update `topology.json` with your Gluster Hostnames, IPs & block devices. I use a modified `gk-deploy` script and `yaml` files to accomplish this task.

My block device is a Samsung 256GB USB3 drive and it's block location is `/dev/sda`

```bash
cd setup/gluster

# Install Heketi and Provision the Gluster block devices
./gk-deploy -v \
    --admin-key admin \
    --user-key user \
    --ssh-user devin \
    --ssh-port 22 \
    --ssh-keyfile $HOME/.ssh/id_rsa \
    --namespace heketi-gluster \
    topology.json

#
# Something went wrong?
#

# Debuging
kubectl describe pod/heketi-storage-copy-job-([a-z\-]+)
kubectl get pod heketi-storage-copy-job-([a-z\-]+) --output=yaml

# Remove Kubernetes objects
kubectl -n heketi-gluster delete deployment.apps/heketi service/heketi ; \
kubectl -n heketi-gluster delete serviceaccount -n default heketi-service-account ; \
kubectl -n heketi-gluster delete secret heketi-config-secret ; \
kubectl -n heketi-gluster delete clusterrolebindings heketi-sa-view ; \
kubectl -n heketi-gluster delete job.batch/heketi-storage-copy-job ; \
kubectl -n heketi-gluster delete secret/heketi-config-secret ; \
kubectl -n heketi-gluster delete service/deploy-heketi

# Completely reset Gluster cluster and wipe all data (run this command on all nodes in the Gluster cluster)
echo 'y' | gluster volume stop heketidbstorage ; \
echo 'y' | gluster volume delete heketidbstorage ; \
umount /var/lib/heketi/mounts/vg_*/* ; \
lvscan | grep 'vg_' | awk '{print $2}' | xargs -n 1 lvremove -y ; \
vgscan | grep 'vg_' | awk '{print $4}' | xargs -n 1 vgremove -y ; \
rm -rf /var/lib/heketi/mounts/* ; \
wipefs -a /dev/sda ; \
systemctl restart glusterd ; \
sed -i '$d' /etc/fstab
```
