# Ansible

Current roles of Ansible, adjust as you see fit.

> Note: This is strictly for my set up and likely won't work 100% for you.

```bash
roles
│   # Configure Docker
├── docker
│   # Install log2ram
├── log2ram
│   # Upgrade all packages, install packages
├── packages
│   # Wipe the USB Thumb drive and format with ext4 filesystem
├── usbdrive
│   # Install and configure Neofetch
└── user
```

> All these commands are run from your computer, not the RPi.

## Copy and update inventory and vars.yml

```bash
# Update inventory with your RPi IP addresses and hostnames
cp setup/ansible/inventory.example setup/ansible/inventory
# Update ansible_user to the user you used when you flashed HypriotOS
cp setup/ansible/vars.example.yml setup/ansible/vars.yml
```

## 1. Ensure RPis are online

> Note: Prefix with watch command to view realtime

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

## Shutdown the RPis

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible -b \
    all -i setup/ansible/inventory -m shell -a "/sbin/shutdown -h now"
```
