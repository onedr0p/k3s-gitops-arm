# homelab-gitops (ARM Edition)

Tutorial on how to get a Kubernete Cluster up and running on your Raspberry Pis

References:
- https://medium.com/nycdev/k8s-on-pi-9cc14843d43
- https://itnext.io/building-a-kubernetes-cluster-on-raspberry-pi-and-low-end-equipment-part-1-a768359fbba3
- https://medium.com/developingnodes/setting-up-kubernetes-cluster-on-raspberry-pi-15cc44f404b5

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
sudo kubeadm init --token-ttl=0 --pod-network-cidr=10.42.0.0/16
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# View Kubernetes objects and wait for them to come active
kubectl get all --all-namespaces

#
# Something went wrong?
#

# Debuging
kubectl get events -w

# Reset
echo 'y' | sudo kubeadm reset ; \
rm -rf $HOME/.kube/config ; \
iptables -P INPUT ACCEPT ; \
iptables -P FORWARD ACCEPT ; \
iptables -P OUTPUT ACCEPT ; \
iptables -t nat -F ; \
iptables -t mangle -F ; \
iptables -F ; \
iptables -X ; \
ip link delete flannel.1 ; \
ip link delete cni0 ; \
systemctl restart docker
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

## Apply Weave CNI

```bash
# Update to the latest Kernel
sudo rpi-update

# Reboot
sudo reboot

# Apply Weave CNI
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

#
# Something went wrong?
#

# Debuging
kubectl exec -n kube-system weave-net-ptkb8 -c weave -- /home/weave/weave --local status
kubectl exec -n kube-system pod/weave-net-mgklj -c weave -- /home/weave/weave --local status ipam

## Apply Flannel CNI
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

## Taint and label Worker Nodes

```bash
# List Nodes
kubectl get nodes

# Label Node
kubectl label node <node-name> node-role.kubernetes.io/worker=worker

## Taint Node
# kubectl taint nodes <node-name> arch=arm:NoExecute

## Remove Taint
# kubectl taint nodes <node-name> arch-

# View all nodes and thier taints
# kubectl get nodes -o json | jq '.items[].spec.taints'
```

## Tiller

```bash
# Install Tiller
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --tiller-image=jessestuart/tiller:v2.14.3-arm --service-account tiller
    # --override 'spec.template.spec.tolerations[0].key'='node-role.kubernetes.io/master' \
    # --override 'spec.template.spec.tolerations[0].effect'='NoSchedule'
#     --override 'spec.template.spec.tolerations[0].key'='arm' \
#     --override 'spec.template.spec.tolerations[0].operator'='Equal' \
#     --override 'spec.template.spec.tolerations[0].value'='true' \
#     --override 'spec.template.spec.tolerations[0].effect'='NoExecute'

# Upgrade Tiller
helm init --upgrade --tiller-image=jessestuart/tiller:v2.15.0-arm --service-account tiller
#     --override 'spec.template.spec.tolerations[0].key'='node-role.kubernetes.io/master' \
#     --override 'spec.template.spec.tolerations[0].effect'='NoSchedule'

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

## Other Debugging

```bash
kubectl -n flux logs pod/helm-operator-857544fb55-zprms

# E1020 17:56:52.250466 1 memcache.go:134] couldn't get resource list for metrics.k8s.io/v1beta1: the server is currently unable to handle the request

kubectl delete apiservice v1beta1.metrics.k8s.io
```
