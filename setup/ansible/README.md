# k3s and Gluster Raspberry Pi 4 Setup with Ansible

Bootstraped k3s cluster backed by a GlusterFS storage class.

It's **important** to only run the `ansible/init` playbooks once if you are already using this in _production_. See the `ansible/up` folder inorder to upgrade `k3s` or `gluster`.

## Pi Requirements

* 2+ Raspberry Pi 4 for k3s
* 3 Raspberry Pi 4 for GlusterFS
  * Each Pi must have a USB drive attached for data storage
* Each Pi is connected to a network switch via a ethernet cord

## Playbooks

The initial playbook will:

* Boot: enable cgroups, disable WiFi, disable Bluetooth, disable IPv6, disable HDMI, disable audio
* Network: Set static IP, set DNS servers, set hostname, set hosts DNS names, use legacy IP tables
* System: upgrade system, upgrade packages, random timed auto upgrades, install common packages, set timezone, disable swap, installs node_exporter
* User: create new user, install and activate neofetch

and more!

In order to run these playbooks you will need to install `sshpass` see [here](https://gist.github.com/arunoda/7790979) for instructions on how to install it

### Pre-flight Playbook instructions

* Place the current IP addresses of the Pis to provision in the `inventory` file
* Use the helper script `get-ip-from-mac-addr.sh` to get the current IPs of your Pis, fill in the MAC addresses of your Pis
  * Script requires `arp-scan`
  * `sudo apt-get install arp-scan`
  * `brew install arp-scan`
* Update `vars.yml`
  * Mac addresses of your Pis and set each `hostname` and `ip` to the desired values
* Run playbook: `ansible-playbook playbook-preflight.yml -k`

When successfull the Pis will be rebooted and the new IP addresses will be set. At this point you can continue...

### Kubernetes Playbook instructions

* Update the `inventory` file to the **new IP addresses** that you set to in the initial playbook
* (Optional) Update `gluster_version` in `vars.yml`
