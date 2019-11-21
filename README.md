# homelab-gitops (ARM Edition)

> Note: My local shell is [Fish](https://fishshell.com/), some of the commands throughout these docs are specific to the Fish Shell

Hardware Requirements for this tutorial:

- 3x RPi4 and at least 32GB SD Cards
- Network switch and ethernet cords

Software Requirements for this tutorial:

- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [hypriot/flash](https://github.com/hypriot/flash)
- [alexellis/k3sup](https://github.com/alexellis/k3sup)

Directory layout:

```bash
.
│   # Flux will only scan and deploy from this directory
├── ./deployments
│   # Initial setup of the cluster
└── ./setup
    ├── ./ansible
    └── ./hypriotos
```

## My configuration

- 192.168.1.1 is my routers IP
- 192.168.1.15 is my DNS server (dedicated RPi for PiHole)
- 192.168.42.1/27 is my Cluster CIDR
- 192.168.42.1 is my routers IP for VLAN 42
- 192.168.42.23 is the k3s masters IP (pik3s00)
- 192.168.42.24 is a k3s workers IP (pik3s01)
- 192.168.42.25 is a k3s workers IP (pik3s02)
- 192.168.42.26 is a k3s workers IP (pik3s03)

## 1. UniFi Security Gateway / MetalLB

### MetalLB w/ USG and using BGP load balancing

According to [MetalLBs wesite](https://metallb.universe.tf/concepts/bgp/):

> In BGP mode, each node in your cluster establishes a BGP peering session with your network routers, and uses that peering session to advertise the IPs of external cluster services.

Moreover:

> Assuming your routers are configured to support multipath, this enables true load-balancing: the routes published by MetalLB are equivalent to each other, except for their nexthop. This means that the routers will use all nexthops together, and load-balance between them.

See [unifi-security-gateway.md](docs/1-unifi-security-gateway.md)

BGP load balancing requires setting up a new network with a VLAN for the k3s cluster and altering the USG via the CLI. Afterwards, make sure you also update [metallb.yaml](deployments/kube-system/metallb/metallb.yaml) with the IP addresses you choose.

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

See [k3sup.md](docs/4-k3sup.md)

## 5. Tiller & Helm

See [tiller-helm.md](docs/5-tiller-helm.md)
