packer {
  required_plugins {
    vmware = {
      source  = "github.com/vmware/vmware"
      version = "~> 2.1"
    }
  }
}

variable "iso_path" {
  type        = string
  description = "Absolute path to the local Windows Server 2019 ISO."
}

variable "iso_checksum" {
  type        = string
  description = "SHA-256 checksum in the form sha256:<hex>."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Temporary local Administrator/WinRM password (set via PKR_VAR_admin_password)."
}

source "vmware-iso" "windows2019" {
  iso_url      = var.iso_path
  iso_checksum = var.iso_checksum

  vm_name              = "packer-windows2019"
  guest_os_type        = "windows2019srv-64"
  network_adapter_type = "e1000e"
  disk_adapter_type    = "sata"
  output_directory     = "output-windows2019"

  firmware  = "efi"
  cpus      = 2
  memory    = 4096
  disk_size = 61440

  floppy_files = [
    "Autounattend.xml",
    "setup-winrm.ps1"
  ]

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = var.admin_password
  winrm_timeout  = "45m"
  winrm_use_ssl  = false

  # Candidate timing from the troubleshooting session. EFI prompt timing varies
  # across VMware hosts; confirm against your own *working* local build settings.
  boot_wait = "2s"
  boot_command = [
    "<spacebar>",
    "<wait1s>",
    "<spacebar>",
    "<wait1s>",
    "<spacebar>"
  ]

  shutdown_command = "shutdown /s /t 10 /f"
  shutdown_timeout = "15m"
  headless         = false
}

build {
  sources = ["source.vmware-iso.windows2019"]
}
