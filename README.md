# Packer + VMware Workstation Lab

Infrastructure image automation using **HashiCorp Packer** with VMware Workstation. This repository is organised by operating system so Windows and Linux builds can evolve independently.

## Projects

| Folder | Status | Description |
|---|---|---|
| [windows-lab/](windows-lab/) | Windows Server 2019 build completed in the original lab | Packer `vmware-iso` build, unattended setup, WinRM automation and troubleshooting |
| `linux-lab/` | Planned | Space for the Ubuntu/Linux Packer configuration and Ansible provisioning |

## Windows Server 2019

Start with [windows-lab/README.md](windows-lab/README.md) for requirements, build commands, security notes and validation. The detailed EFI boot and disk-controller troubleshooting history is in [windows-lab/docs/TROUBLESHOOTING.md](windows-lab/docs/TROUBLESHOOTING.md).

```bash
git clone https://github.com/smtabakoglu/packer-vmware-lab.git
cd packer-vmware-lab/windows-lab
bash scripts/build.sh /absolute/path/to/Server2019.iso
```

**Lab only.** Windows evaluation installation media is not included. Do not commit guest credentials, unattended answer files containing passwords, VM output disks, ISO images or secrets. The Windows lab uses HTTP/Basic WinRM only in a trusted isolated environment; harden images before non-lab use.
