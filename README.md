# Packer + VMware Workstation Lab

Infrastructure image automation using **HashiCorp Packer** with VMware Workstation. This repository is organised by operating system so Windows and Linux builds can evolve independently.

## Projects

| Folder | Status | Description |
|---|---|---|
| [windows-lab/](windows-lab/) | Windows Server 2019 built and verified in the original lab | Packer `vmware-iso` build, unattended setup, WinRM automation and troubleshooting |
| [linux-lab/](linux-lab/) | Ubuntu 22.04.2 originally built; source reconstructed | [Ubuntu Packer](linux-lab/ubuntu-2204/), [Ansible starter](linux-lab/ansible/) and [Terraform investigation](linux-lab/terraform/) |

## Windows Server 2019

Start with [windows-lab/README.md](windows-lab/README.md) for requirements, build commands, security notes and validation. The detailed EFI boot and disk-controller troubleshooting history is in [windows-lab/docs/TROUBLESHOOTING.md](windows-lab/docs/TROUBLESHOOTING.md).

```bash
git clone https://github.com/smtabakoglu/packer-vmware-lab.git
cd packer-vmware-lab/windows-lab
bash scripts/build.sh /absolute/path/to/Server2019.iso
```

## Ubuntu Server 22.04.2

See [linux-lab/ubuntu-2204/README.md](linux-lab/ubuntu-2204/README.md) for the reconstructed Packer VMware build and [troubleshooting history](linux-lab/ubuntu-2204/docs/TROUBLESHOOTING.md). The original Ubuntu VM build succeeded; these published source files reconstruct the earlier discussion and have not yet been re-run.

```bash
cd packer-vmware-lab/linux-lab/ubuntu-2204
bash scripts/build.sh "$HOME/Downloads/ubuntu-22.04.2-live-server-amd64.iso"
```

Ansible has a [new, read-only verification example](linux-lab/ansible/). The [Terraform notes](linux-lab/terraform/) record an unresolved VMware provider data-source HTTP 404; **no successful Terraform apply is claimed**.

**Lab only.** VM install media, VM disks, credential-bearing answer files and local secrets are excluded. Always review a Packer plan/build and use isolated networks; harden images before non-lab use.
