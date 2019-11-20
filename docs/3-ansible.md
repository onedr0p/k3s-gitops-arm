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

## Run playbook

```bash
env ANSIBLE_CONFIG=setup/ansible/ansible.cfg ansible-playbook \
    -i setup/ansible/inventory \
    setup/ansible/playbook.yml
```
