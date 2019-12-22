# Ansible

> All these commands are run from your computer, not the RPi.

## Copy and update inventory and vars.yml

```bash
# Update inventory with your RPi IP addresses and hostnames
cp setup/ansible/inventory.example setup/ansible/inventory
# Update ansible_user to the user you used when you flashed Ubuntu
cp setup/ansible/vars.example.yml setup/ansible/vars.yml
```

## 1. Ensure RPis are online

> **Note**: Prefix with watch command to view realtime

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible \
    -i setup/ansible/inventory \
    k3s_cluster -m ping
```

## 2. Run playbook

> **Note**: Run this when all RPis are online

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible-playbook \
    -i setup/ansible/inventory \
    setup/ansible/playbook.yml
```

## 3. Provision USB drive

> **Note**: Run this when all RPis are online
>
> **Important**: Running this requires a USB drive inserted into each Pi, this playbook will format the ENTIRE flash storage

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible-playbook \
    -i setup/ansible/inventory \
    setup/ansible/playbook-usbdrive.yml
```

## Check Temp of all RPis

> **Note**: This should be below 70.0'C for good performance

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible \
    all -i setup/ansible/inventory -m shell -a "/opt/vc/bin/vcgencmd measure_temp"
```

## Check overclock value of all RPis

> **Note**: This should be 175000

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible \
    all -i setup/ansible/inventory -m shell -a "cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
```

## Reboot the RPis

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible -b \
    all -i setup/ansible/inventory -m shell -a "/sbin/shutdown -r now"
```

## Shutdown the RPis

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible -b \
    all -i setup/ansible/inventory -m shell -a "/sbin/shutdown -h now"
```

## Uninstall k3s

```bash
# master and workers
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible -b \
      all -i setup/ansible/inventory -m shell -a "/usr/local/bin/k3s-killall.sh"

# master
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible -b \
      all -i setup/ansible/inventory -m shell -a "/usr/local/bin/k3s-uninstall.sh"

# workers
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible -b \
      all -i setup/ansible/inventory -m shell -a "/usr/local/bin/k3s-agent-uninstall.sh"
```
