# Packer + VMware Workstation — Windows Server 2019 Image Build and Troubleshooting

**Date:** 9 October 2026 (UK time)  
**Platform:** Kali Linux host → VMware Workstation → Windows Server 2019 Evaluation VM  
**Result:** ✅ Packer build successful; generated VM started independently and Administrator login succeeded  
**Build duration:** 8 minutes 23 seconds (successful run)

> **Scope:** This documents what we did and observed during the initial Windows Server 2019 Packer proof of concept. It includes confirmed fixes and distinguishes those from settings that still warrant verification. **Do not paste real passwords into the note or commit secrets to Git.**

## 1. Objective

Build a Windows Server 2019 VMware image automatically with HashiCorp Packer using an existing local ISO, unattended Windows installation, and WinRM for Packer communication. Run it independently of the Ubuntu image build and retain the resulting VMware VM files for testing.

## 2. Environment and inputs

| Item | Value / result |
|---|---|
| Host | Kali Linux |
| Packer | v1.16.1 |
| VMware Workstation | 17.6.3, build 24583834 |
| `vmrun` | `/usr/bin/vmrun` |
| VMware Packer plugin | v2.1.6 (`github.com/vmware/vmware`) |
| Working directory | `~/packer-vmware-lab` |
| Local ISO | `/home/YOUR_USERNAME/Downloads/Server2019.iso` |
| ISO format | Bootable ISO 9660, volume `SSS_X64FREE_EN-US_DV9` |
| Installation image | `sources/install.wim` (about 4.4 GB) |
| Selected edition | **Index 2 — Windows Server 2019 Standard Evaluation (Desktop Experience)** |
| VM name | `packer-windows2019` |
| VM resources | 2 vCPU, 4096 MB RAM, 61,440 MB virtual disk |
| Firmware | EFI/UEFI (`firmware = "efi"`) |
| Virtual NIC | `e1000e` |
| Virtual disk controller | **SATA** (`disk_adapter_type = "sata"`) — key fix |
| Packer communicator | WinRM |
| Output directory | `output-windows2019` |

### Installation edition selection

Mounted and inspected the ISO:

```bash
sudo mkdir -p /mnt/win2019iso
sudo mount -o loop,ro ~/Downloads/Server2019.iso /mnt/win2019iso
ls -lh /mnt/win2019iso/sources/install.*
wiminfo /mnt/win2019iso/sources/install.wim
```

The WIM contained four editions:

| Index | Edition |
|---|---|
| 1 | Standard Evaluation — Server Core |
| **2** | **Standard Evaluation — Desktop Experience (chosen)** |
| 3 | Datacenter Evaluation — Server Core |
| 4 | Datacenter Evaluation — Desktop Experience |

The ISO showed Windows Server build **17763.3650**. The ISO is an **evaluation** edition, so evaluation licensing applies.

## 3. Build setup

Created these files in the project directory:

- `windows2019.pkr.hcl` — Packer VMware builder, hardware, ISO, floppy attachments, EFI, WinRM, boot and shutdown settings.
- `Autounattend.xml` — Windows unattended setup, image **Index 2**, English locale, UEFI/GPT disk partitions, local Administrator setup and first-logon command.
- `setup-winrm.ps1` — Enabled Windows PowerShell remoting/WinRM for Packer to connect.

Key configuration fragments from the final approach:

```hcl
source "vmware-iso" "windows2019" {
  iso_url              = "/home/YOUR_USERNAME/Downloads/Server2019.iso"
  iso_checksum         = "sha256:<actual-local-ISO-SHA256>"
  vm_name              = "packer-windows2019"
  guest_os_type        = "windows2019srv-64"
  network_adapter_type = "e1000e"
  output_directory     = "output-windows2019"

  firmware          = "efi"
  cpus              = 2
  memory            = 4096
  disk_size         = 61440
  disk_adapter_type = "sata"

  floppy_files = ["Autounattend.xml", "setup-winrm.ps1"]

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = "<temporary-lab-password>"
  winrm_timeout  = "45m"
  winrm_use_ssl  = false

  # EFI boot settings were adjusted during troubleshooting.
  # Preserve the exact currently working boot_command from your local file.
  shutdown_command = "shutdown /s /t 10 /f"
  shutdown_timeout = "15m"
  headless         = false
}
```

**Note:** This is a **configuration excerpt**, not a complete copy of the final HCL. The exact last-used `boot_command` wasn't captured after the user confirmed boot worked. Do not treat any earlier candidate key sequence as definitively proven. The final HCL on the Kali host is the source of truth.

### ISO checksum

Initially the builder used `iso_checksum = "none"` for a validation-only configuration. Before building, we generated the actual SHA-256 checksum and configured Packer to use it:

```bash
sha256sum ~/Downloads/Server2019.iso
```

### Unattended setup

`Autounattend.xml` specified:

- Windows PE locale `en-US`.
- `/IMAGE/INDEX` = `2`.
- UEFI/GPT partitions: EFI System Partition (260 MB), MSR (16 MB), NTFS Windows partition (remaining space).
- Disk `0`, `WillWipeDisk=true` — **destructive to Disk 0 of the target VM**.
- A temporary Administrator password and one-time automatic login.
- First-logon execution of `A:\setup-winrm.ps1` from Packer's virtual floppy.

The WinRM script enabled remoting and WinRM HTTP/Basic access on port 5985. **This was suitable only for an isolated proof-of-concept lab, not production.**

## 4. Issues encountered and resolutions

### Issue A — APT 404 while installing `wimtools`

**Symptom:**

```text
Err: Failed to fetch ... libwim15t64 ... 404 Not Found
Err: Failed to fetch ... wimtools ... 404 Not Found
```

**Cause:** Kali APT's package index referenced versions no longer present on the current mirror (likely stale package metadata).

**Resolution:**

```bash
sudo apt update
sudo apt install -y wimtools
wiminfo /mnt/win2019iso/sources/install.wim
```

We did **not** need a full OS upgrade. `wiminfo` subsequently worked and identified the four Windows images.

### Issue B — Packer validation failed: missing network adapter type

**Symptom:**

```text
'network_adapter_type' is required; must be one of vmxnet3, e1000e, e1000
```

**Cause:** The VMware Packer plugin required an explicit virtual NIC type.

**Fix:** Added this inside the `vmware-iso` source block:

```hcl
network_adapter_type = "e1000e"
```

Then validated with:

```bash
packer fmt .
packer validate .
```

**Result:** Configuration valid.

### Issue C — VMware EFI boot prompt timed out

**Symptoms observed:**

- VM opened at the blue **EFI Boot Manager** instead of starting Windows Setup.
- It exposed an entry such as **EFI VMware Virtual IDE CDROM Drive (IDE 0:0)**.
- On another attempt, firmware advanced to:

```text
EFI Floppy... No compatible bootloader found.
EFI Network...
```

- Windows installation media prompted **Press any key to boot from CD or DVD...**, but the automated keypress missed the short window.
- Packer proceeded to `Waiting for WinRM to become available...`, even though Windows Setup had not started.

**Diagnosis:** EFI boot selection/keypress timing was unreliable. Earlier candidate commands included `<spacebar>` and a sequence using `<down><down><enter>`, `<wait5s>`, `<spacebar>`. The latter did not reliably select the CD/DVD at first.

**Recovery during troubleshooting:** Manually selected the EFI CD-ROM entry and acknowledged the CD/DVD boot prompt; Windows Setup loaded.

**Outcome:** After further boot-timing adjustment and retry, the user confirmed **Error 1 was fixed**, and the eventual build succeeded. **The final exact `boot_wait`/`boot_command` values were not supplied in the conversation**, so retrieve them from the current `windows2019.pkr.hcl` rather than copying an unverified candidate from this note.

**Important:** After Windows Setup's first reboot, **do not press a key to boot from the ISO again**; let the installed OS boot from its disk.

### Issue D — Windows Setup `<DiskConfiguration>` failed

**Symptom (repeated on two installation attempts):**

```text
The installation was canceled.
Windows could not apply the unattend answer file's
<DiskConfiguration> setting.
```

**Initial suspicion:** UEFI/GPT XML partition schema, but simply substituting essentially the same partition XML did not address the failure.

**Decisive diagnostic:** Opened Command Prompt from Windows PE and ran:

```cmd
diskpart
list disk
list volume
exit
```

**Observed:**

```text
There are no fixed disks to show.
```

Only the optical installation volume was present (DVD-ROM around 5,390 MB). Windows Setup therefore had **no visible hard disk** on which to apply its partition instructions.

**Root cause at the level verified:** Windows PE could not see the Packer-created VMware virtual hard disk with the initial storage controller configuration. We did not obtain a lower-level controller driver trace.

**Fix:** Added explicitly to the `vmware-iso` builder:

```hcl
disk_adapter_type = "sata"
```

This presents a SATA/AHCI-style virtual disk to Windows Setup, supported by the Windows Server 2019 installer.

**Result:** The subsequent Packer run completed successfully. This strongly confirms that changing the VMware storage controller resolved the disk-detection blocker; no partition-layout change was established as necessary.

### Issue E — VM/keyboard handling during troubleshooting

A proposed VMware keyboard shortcut caused an unexpected VM reboot. Avoid relying on that shortcut. When Windows Setup needs diagnosis, capture the console using the VMware UI and, when available, Windows PE Command Prompt (Shift+F10 / keyboard-specific equivalent). Do not reboot unnecessarily before collecting `diskpart` and Panther logs.

### Issue F — Cleaning failed build output

The previous failed VM output was removed before rebuilding:

```bash
cd ~/packer-vmware-lab
rm -rf -- output-windows2019
```

**Caution:** This removes the generated VM files in that directory. It must never be run against a needed image. We retained the three project configuration files.

For troubleshooting, `-on-error=abort` can help preserve build artifacts if Packer itself detects a build failure; in cases where Packer simply waits for WinRM, the VM may require manual inspection before terminating the process.

## 5. Successful build and verification

The successful terminal output included:

```text
Build 'vmware-iso.windows2019' finished after 8 minutes 23 seconds.
Wait completed after 8 minutes 23 seconds
Builds finished. The artifacts of successful builds are:
--> vmware-iso.windows2019: VM files in directory: output-windows2019
```

Packer detached the installation ISO, unmounted the floppy, disabled VNC and saved VMware VM artifacts.

Verified output files:

```bash
find output-windows2019 -maxdepth 1 \
  -type f \( -name '*.vmx' -o -name '*.vmdk' \) -ls
```

Files included:

```text
output-windows2019/packer-windows2019.vmx
output-windows2019/disk.vmdk
output-windows2019/disk-s001.vmdk ... disk-s016.vmdk
```

The split VMDK files are normal parts of a VMware virtual disk; keep the full set together.

Independent boot verification:

```bash
vmware output-windows2019/packer-windows2019.vmx
```

**Observed outcome:** Windows Server 2019 booted, and the user successfully logged in with the Administrator account. This confirms the resulting image is bootable outside the active Packer process.

## 6. Reusable workflow for the next Windows image

1. Confirm ISO, edition and image index with `wiminfo`.
2. Set VMware guest OS type and explicitly set supported `network_adapter_type`.
3. Use an appropriate Windows-visible disk controller; **SATA worked for Server 2019 in this lab**.
4. Use `Autounattend.xml` with correct image index and matching firmware/partition scheme.
5. Configure/verify EFI boot prompt handling. Do not assume Packer's keypress is timed correctly on every cold boot.
6. Ensure first-logon provisioning enables the WinRM communicator.
7. Calculate and set ISO SHA-256; run `packer fmt .`, `packer init .`, `packer validate .`.
8. Build, observe VMware console and save diagnostic logs if Setup fails.
9. Verify output artifacts and independently boot/log in to the VM.
10. Harden/generalize the image before treating it as a reusable template.

## 7. Post-build checks still to do

The build and interactive login succeeded, but these checks were **suggested, not yet verified**:

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsVersion, OsBuildNumber
Get-Service WinRM
Get-Service VMTools -ErrorAction SilentlyContinue
Get-NetIPConfiguration
Get-Disk
```

Before production or broader reuse:

- Remove plaintext lab credentials from `Autounattend.xml`, HCL files and image; rotate the local Administrator password.
- Disable WinRM Basic + unencrypted HTTP, or replace with approved secure WinRM HTTPS/authentication, and tighten firewall rules.
- Remove auto-logon and other temporary setup behaviors.
- Decide whether to install/verify VMware Tools and required Windows updates; updates were intentionally not part of this initial POC.
- Consider Sysprep/generalization if distributing cloned machines requiring unique identities.
- Review Windows Server Evaluation licensing and activation.
- Keep build config under version control **without secrets**; add generated output and sensitive files to `.gitignore` as appropriate.

## 8. Quick reference commands

```bash
# Working directory
cd ~/packer-vmware-lab

# Validate
packer fmt .
packer init .
packer validate .

# Build (force replaces a prior output — use with caution)
packer build -force -on-error=abort .

# Check generated image
find output-windows2019 -maxdepth 1 \
  -type f \( -name '*.vmx' -o -name '*.vmdk' \) -ls

# Launch generated VM
vmware output-windows2019/packer-windows2019.vmx

# Confirm final boot settings actually used
grep -nE 'boot_wait|boot_command|firmware|disk_adapter_type|network_adapter_type' windows2019.pkr.hcl
```

---

**Final result:** ✅ Successfully built a bootable Windows Server 2019 Standard Evaluation (Desktop Experience) VMware VM with Packer. Two main blockers were EFI boot prompt handling and a Windows Setup disk-detection failure. The proven disk fix was **`disk_adapter_type = "sata"`**. Independent Windows login succeeded.
