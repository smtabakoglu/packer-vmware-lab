# Linux Lab

Ubuntu Server Packer builds and future VMware infrastructure automation, separate from [Windows Lab](../windows-lab/).

## Projects

| Path | Purpose | Status |
|---|---|---|
| [ubuntu-2204/](ubuntu-2204/) | Packer `vmware-iso` and Ubuntu 22.04.2 autoinstall | Reconstructed from the successful October 2026 lab; requires retest |
| [ansible/](ansible/) | Read-only Ubuntu verification playbook | New starter; not run against user's VM |
| [terraform/](terraform/) | VMware Workstation provider investigation | Provider data-source HTTP 404 outstanding; no apply verified |

**Security:** VM disks, ISOs, local autoinstall password hash and local inventory should not be committed. The Packer files use ignored generated user-data, and the build script prompts for a temporary password.
