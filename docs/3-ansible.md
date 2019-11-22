# Ansible

Current tasks of Ansible:

- Upgrade all packages
- Install some common packages (e.g. htop, jq, dnsutils)
- Update minor networking configuration
- Add Docker `daemon.json` with some few custom changes
- Install [azlux/log2ram](https://github.com/azlux/log2ram)
- And finally reboots the RPis

> All these commands are run from your computer, not the RPi.

## Copy and update inventory and vars.yml

```bash
cp setup/ansible/inventory.example setup/ansible/inventory
cp setup/ansible/vars.example.yml setup/ansible/vars.yml
```

## 1. Ensure RPis are online

> Note: prefix with watch command to view realtime

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible \
    -i setup/ansible/inventory \
    k3s_cluster -m ping
```

## 2. Run playbook

> Note: Run this when all RPis are online

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible-playbook \
    -i setup/ansible/inventory \
    setup/ansible/playbook.yml
```

## Check Temp of all RPis

> Note: This should be below 70.0'C for good performance

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible \
    all -i setup/ansible/inventory -m shell -a "/opt/vc/bin/vcgencmd measure_temp"
```

## Check overclock value of all RPis

> Note: This should be 175000

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible \
    all -i setup/ansible/inventory -m shell -a "cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
```

## Reboot the RPis

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible -b \
    all -i setup/ansible/inventory -m shell -a "/sbin/shutdown -r now"
```