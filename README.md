## HypriotOS

> All these commands are run from your computer, not the RPi.

### Downloads the Flash tool

```bash
sudo curl -L \
    https://github.com/hypriot/flash/releases/download/2.3.0/flash \
    -o /usr/local/bin/flash

sudo chmod +x /usr/local/bin/flash
```

### Download and extract the image

```bash
curl -L \
    https://github.com/hypriot/image-builder-rpi/releases/download/v1.11.4/hypriotos-rpi-v1.11.4.img.zip \
    -o ~/Downloads/hypriotos-rpi-v1.11.4.img.zip

unzip ~/Downloads/hypriotos-rpi-v1.11.4.img.zip -d ~/Downloads/
```

### Configure and Flash

> All these commands are run from your computer, not the RPi.

Update `config.txt` or `user-data-*.yml` as you see fit, add more `user-data-*.yml` files if you have more hosts.

```bash
# Replace pik3s01 with the file and hostname
flash \
    --bootconf setup/hypriotos/config.txt \
    --userdata setup/hypriotos/user-data-pik3s01.yml \
    --hostname pik3s01 \
    ~/Downloads/hypriotos-rpi-v1.11.4.img
```

## Ansible

```bash
ansible-playbook -i inventory setup/ansible/playbook.yml
```

## k3s

I will be using [k3sup](https://github.com/alexellis/k3sup) in order to provision our k3s cluster

### k3sup

> All these commands are run from your computer, not the RPi.

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
    --k3s-extra-args '--no-deploy servicelb --no-deploy traefik'

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
