# Ansible for Ubuntu Packer VM (starter)

The later Packer project conversation selected **Ansible** as a next step, after creating the Ubuntu VM. The playbook here is a **new read-only starter**, not a claim that Ansible provisioning was executed in the earlier chat.

Copy `inventory.ini.example` to `inventory.ini`, replace the example IP address with the actual IP of the Ubuntu VM, and run:

```bash
ansible -i inventory.ini packer_ubuntu -m ping --ask-pass
ansible-playbook -i inventory.ini verify.yml --ask-pass
```

Requirements: Ansible on the host, SSH enabled on the Ubuntu VM, and a valid login. This example does not update packages or modify the operating system.
