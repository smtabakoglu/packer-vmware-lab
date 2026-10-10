# Ubuntu Server 22.04.2 — Packer + VMware Workstation

Reconstructed, credential-safe **Packer `vmware-iso`** project based on the successful Ubuntu lab from the other Packer-project conversation (October 2026). The local source files themselves were not uploaded to the conversation, so this is a reconstruction of the reported configuration **not a byte-for-byte copy of the final working files**. See [the chronological troubleshooting notes](docs/TROUBLESHOOTING.md) before rebuilding.

## Confirmed from the original lab

| Setting | Value |
|---|---|
| Build host | Kali Linux |
| Packer | 1.16.1 (upgraded from old 1.6.6) |
| VMware Workstation | 17.6.3 |
| VMware Packer plugin | 2.1.6 |
| ISO used | `ubuntu-22.04.2-live-server-amd64.iso` (local download; not uploaded) |
| Local working folder | `~/Projects/mt-packer26/ubuntu2404` (folder name predates ISO switch) |
| VM name | `ubuntu-2204-packer` |
| VM output | `output/ubuntu-2204/ubuntu-2204-packer.vmx` |
| Resources | 2 vCPU, 4096 MB RAM, 30720 MB disk |
| Firmware and network | BIOS, NAT, `vmxnet3` |
| Installation mechanism | Autoinstall, Packer HTTP NoCloud seed, SSH `packer` |
| Build result | Ubuntu VM was built; VMware REST API could subsequently see it |

## Files

- `ubuntu2204.pkr.hcl`: VMware ISO builder, SSH communicator and basic shell provisioning
- `http/user-data.template`: Autoinstall answer file with password-hash placeholder
- `http/meta-data`: NoCloud metadata file, intentionally empty
- `scripts/render-user-data.py`: Uses `openssl passwd -6 -stdin` to generate the salted hash locally
- `scripts/build.sh`: Prompts for temporary password, computes ISO SHA-256, validates/builds, removes generated user-data
- `docs/TROUBLESHOOTING.md`: Error and fix history, unresolved update-stage caveat

## Build (Kali host)

From the repository root:

```bash
cd linux-lab/ubuntu-2204
bash scripts/build.sh "$HOME/Downloads/ubuntu-22.04.2-live-server-amd64.iso"
```

Prerequisites: VMware Workstation, `vmrun`, Packer with the VMware plugin, `python3`, `openssl`, and the Ubuntu Server ISO. The script requests a **new temporary password** without echoing input, then generates a **gitignored** `http/user-data` file, computes the local ISO checksum, and runs `packer init`, `packer validate`, and `packer build`.

**Warning:** The `storage: direct` autoinstall configuration destroys the selected VM's disk contents. **Do not** use this answer file on a machine with valuable data. Do not use `-force` without confirming that old build output can be destroyed.

### What still needs re-testing

- The precise **final successful GRUB/boot key timing** from the local Packer HCL was not preserved in available chat history; the checked-in sequence is a reconstruction.
- The original installation reported an `unattended-upgrades` failure. `refresh-installer: { update: false }` prevents **installer self-refresh**, but is **not** equivalent to disabling Ubuntu security package updates. In documented Ubuntu autoinstall schema, `updates` accepts `security` or `all`, **not** `none`. This example intentionally avoids a misleading `updates: none` key. A repeat build may still need investigation if the mirror is unavailable. See troubleshooting notes.
- This repository does **not** include the original VM output or credentials, and this reconstructed source has not yet been run on your Kali system.

## Verification

```bash
find output/ubuntu-2204 -type f \( -name '*.vmx' -o -name '*.vmdk' \) -ls
vmware output/ubuntu-2204/ubuntu-2204-packer.vmx
```

Once booted in Ubuntu:

```bash
lsb_release -a
cloud-init status --long
ip -br address
systemctl is-active ssh
vmware-toolbox-cmd -v || true
```

## Security

The generated `http/user-data` contains a reusable salted **password hash**. It is sensitive even though it is not plaintext. Do not push it, share build logs containing secrets, or push your actual VM disks; the `.gitignore` excludes these files. Use a password specific to this throwaway lab, rotate or disable it afterwards, and prefer SSH keys for longer-lived systems. Avoid storing the temporary plaintext password in shell history, process command lines, or GitHub.

## Follow-on work

- [Ansible](../ansible/) includes an **unexecuted, read-only starter playbook** for this Ubuntu VM.
- [Terraform integration status](../terraform/README.md) records the VMware REST API and provider findings, including the still-unresolved Terraform data-source 404. **No Terraform apply is claimed.**
