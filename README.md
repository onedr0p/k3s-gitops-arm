# homelab-gitops (ARM Edition)

Build a Kubernetes (k3s) cluster with RPis and utilize GitOps for managing cluster state.

## Hardware and software

Hardware requirements for this tutorial:

- 3x RPi4 (recommended 4GB RAM) and at least 32GB SD Cards

Software requirements for this tutorial:

- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [hypriot/flash](https://github.com/hypriot/flash)
- [alexellis/k3sup](https://github.com/alexellis/k3sup)

## Directory layout

```bash
.
│   # Flux will only scan and deploy from this directory
├── ./deployments
│   # Initial setup of the cluster
└── ./setup
│   ├── ./ansible
│   └── ./hypriotos
│   # flux, helm-operator, and velero ARM Dockerfiles
└── ./docker-arm
```

## Network configuration

|IP|Function|
|---|---|
|192.168.1.1|Router|
|192.168.1.15|DNS Server running PiHole|
|192.168.42.1/27|k3s cluster CIDR, VLAN 42|
|192.168.42.23|k3s master (pik3s00)|
|192.168.42.24|k3s worker (pik3s01)|
|192.168.42.25|k3s worker (pik3s02)|

## 1. UniFi Security Gateway / MetalLB

### MetalLB w/ USG and using BGP load balancing

According to [MetalLBs wesite](https://metallb.universe.tf/concepts/bgp/):

> In BGP mode, each node in your cluster establishes a BGP peering session with your network routers, and uses that peering session to advertise the IPs of external cluster services.

Moreover:

> Assuming your routers are configured to support multipath, this enables true load-balancing: the routes published by MetalLB are equivalent to each other, except for their nexthop. This means that the routers will use all nexthops together, and load-balance between them.

BGP load balancing requires setting up a new network with a VLAN for the k3s cluster and altering the USG via the CLI. Afterwards, make sure you also update [metallb.yaml](deployments/kube-system/metallb/metallb.yaml) with the IP addresses you choose.

See [unifi-security-gateway.md](docs/1-unifi-security-gateway.md)

### MetalLB w/o BPG

If you want to use MetalLB with an existing network you will need to change [metallb.yaml](deployments/kube-system/metallb/metallb.yaml), see comments in that file.

## 2. HypriotOS

This documentation walks thru the steps of flashing a SD Card with HypriotOS

See [hypriotos.md](docs/2-hypriotos.md)

## 3. Ansible

This documentation walks you thru the steps of provisioning your RPis with Ansible.

See [ansible.md](docs/3-ansible.md)

## 4. Install k3s on your RPis

I will be using [k3sup](https://github.com/alexellis/k3sup) in order to provision our k3s cluster.

### Manual

See [k3sup.md](docs/4-k3sup.md)

### Automated

See [bootstrap-cluster.sh](setup/bootstrap-cluster.sh)

## 5. Tiller & Helm

### Manual

See [tiller-helm.md](docs/5-tiller-helm.md)

### Automated

See [bootstrap-cluster.sh](setup/bootstrap-cluster.sh)

## Opinionated RPi related hardware

- [Samsung 128GB EVO Plus Class 10 Micro SDXC](https://smile.amazon.com/gp/product/B06XFHQGB9/ref=ppx_yo_dt_b_asin_title_o01_s00?ie=UTF8&psc=1)
- [AUKEY Quick Charge 3.0 6-Port USB Wall Charger](https://smile.amazon.com/gp/product/B01F20J4PE/ref=ppx_yo_dt_b_asin_title_o06_s00?ie=UTF8&psc=1)
- [AUKEY USB C Cable Short](https://smile.amazon.com/gp/product/B0746C244X/ref=ppx_yo_dt_b_asin_title_o06_s00?ie=UTF8&psc=1)
- [Cablecc Mini Size 5Gbps Super Speed USB 3.0 to Micro SD SDXC TF Card Reader Adapter](https://smile.amazon.com/gp/product/B01787LD3K/ref=ppx_yo_dt_b_asin_title_o08_s00?ie=UTF8&psc=1)
- [Samsung MUF-256AB/AM FIT Plus 256GB - 300MB/s USB 3.1 Flash Drive](https://smile.amazon.com/gp/product/B07D7Q41PM/ref=ppx_yo_dt_b_asin_title_o01_s00?ie=UTF8&psc=1)
- [Vilros Raspberry Pi 4 Heavy Duty Aluminum Alloy Pi Cooling Case](https://smile.amazon.com/gp/product/B07XVPH79R/ref=ppx_yo_dt_b_asin_title_o00_s01?ie=UTF8&psc=1) or [Flirc Raspberry Pi 4 Case](https://smile.amazon.com/Flirc-Raspberry-Pi-Case-Silver/dp/B07WG4DW52/ref=sr_1_3)