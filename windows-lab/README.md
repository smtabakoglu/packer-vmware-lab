# Packer + VMware Workstation — Windows Server 2019

A GitHub-ready record of a **successful Windows Server 2019 Standard Evaluation (Desktop Experience)** VMware image build using Packer on Kali Linux, plus scripts for repeating the local lab build.

> **Proof of concept / lab only.** The WinRM setup deliberately uses HTTP/Basic authentication and a temporary Administrator password. Do **not** expose the VM to untrusted networks or publish generated answer files, credentials, or VM disks. The generated image must be hardened before broader use.

## Verified environment

| Component | Value |
|---|---|
| Host | Kali Linux |
| Packer | 1.16.1 |
| VMware Workstation | 17.6.3 (build 24583834) |
| VMware Packer plugin | 2.1.6 |
| ISO | Windows Server 2019 Evaluation, provided locally by user |
| Image index | **2** — Standard Evaluation, Desktop Experience |
| Resources | 2 vCPU, 4 GB RAM, 60 GB virtual disk |
| Firmware | EFI / UEFI |
| Network adapter | `e1000e` |
| Virtual disk adapter | **`sata`** — fixes missing disk in Windows Setup |
| Result | Build successful **8m 23s**, VM independently booted and Administrator login succeeded |

## Repository layout

```text
packer-vmware-lab/
├── README.md
└── windows-lab/
    ├── windows2019.pkr.hcl
    ├── Autounattend.xml.template
    ├── setup-winrm.ps1
    ├── scripts/
    │   ├── build.sh
    │   └── render-unattend.py
    ├── docs/
    │   └── TROUBLESHOOTING.md
    ├── .gitignore
    └── README.md
```

## Requirements

Install VMware Workstation, Packer and its VMware plugin, and Python 3. Ensure VMware networking is configured and the VM runs only on a trusted, isolated lab network. You also need a legitimately obtained **Windows Server 2019 Evaluation ISO**. Neither the ISO nor the built VM is included in this repository.

Confirm tools:

```bash
packer version
vmware -v
which vmrun
```

## Build

Clone or unpack the repository, then run:

```bash
cd packer-vmware-lab/windows-lab
bash scripts/build.sh /absolute/path/to/Server2019.iso
```

The script:

1. Prompts for a temporary lab Administrator password (input hidden) unless `PKR_VAR_admin_password` is already set.
2. Calculates `sha256:<digest>` from the ISO; passes it and the ISO path to Packer.
3. Renders a local password-bearing `Autounattend.xml` with file mode `0600`. This file is **gitignored**.
4. Runs `packer init`, `packer fmt`, `packer validate` and `packer build -on-error=abort`.
5. Removes the generated local answer file on exit, even after failed runs. **Important:** a failed VM may still contain credentials, and `-on-error=abort` can preserve its disks. Clean them up securely.

**Caution:** `Autounattend.xml` wipes **Disk 0 inside the target VMware VM**. Never use it against a machine containing important data. Running another build in the same directory while `output-windows2019/` exists will fail until the previous output is explicitly moved or removed. Do not delete a good VM by mistake.

### EFI boot caveat

This repository uses a **candidate** Packer EFI `boot_wait` / `boot_command` sequence from troubleshooting. We confirmed that the eventual VM booted and the build succeeded, but the *exact final working key sequence was not captured*. If your EFI CD/DVD prompt times out, compare these values against the **known-working local** `windows2019.pkr.hcl` before adjusting. See the troubleshooting guide. On reboots after Windows Setup has copied files, do **not** press any key to boot the ISO again.

## Verify the build

```bash
find output-windows2019 -maxdepth 1 -type f \( -name '*.vmx' -o -name '*.vmdk' \) -ls
vmware output-windows2019/packer-windows2019.vmx
```

After logging in, PowerShell checks:

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsVersion, OsBuildNumber
Get-Service WinRM
Get-Service VMTools -ErrorAction SilentlyContinue
Get-NetIPConfiguration
Get-Disk
```

The above PowerShell checks were recommended after the successful build but **their output was not supplied** in the original session.

## Security and licensing

- Never commit `Autounattend.xml`, Packer variables containing passwords, ISO images, or VM disks. Check `git status` before pushing.
- A temporary password will be embedded in a local unattended answer file and can remain inside the Windows guest/VM artifacts. Treat generated images as sensitive.
- Restrict network access during the POC; disable HTTP/Basic WinRM after use or replace with a secure managed authentication scheme.
- Remove auto-login credentials, rotate Administrator credentials and generalize with Sysprep when required before cloning.
- Windows Server **Evaluation** use is subject to Microsoft licensing restrictions.
- The original successful Packer build did **not** verify VMware Tools installation, post-install updates, Sysprep, or production hardening.

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the APT, NIC validation, EFI CD-ROM boot, invisible virtual disk, SATA fix and complete build/verification timeline.

## GitHub layout

The Windows build is maintained inside [`windows-lab/`](../windows-lab/) so that Linux builds can be added separately under `linux-lab/`. Do not commit licensed ISO images, generated VMware files, or `Autounattend.xml`; the local `.gitignore` excludes these.

