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
  description = "Absolute path to locally owned Ubuntu Server 22.04.2 ISO"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the ISO in sha256:<hex> format"
}

variable "ssh_password" {
  type        = string
  sensitive   = true
  description = "Temporary lab password for the packer account"
}

source "vmware-iso" "ubuntu2204" {
  iso_url      = var.iso_path
  iso_checksum = var.iso_checksum

  vm_name          = "ubuntu-2204-packer"
  output_directory = "output/ubuntu-2204"
  guest_os_type    = "ubuntu-64"
  firmware         = "bios"

  cpus                 = 2
  memory               = 4096
  disk_size            = 30720
  network              = "nat"
  network_adapter_type = "vmxnet3"

  http_directory = "http"

  ssh_username = "packer"
  ssh_password = var.ssh_password
  ssh_timeout  = "45m"

  # Reconstructed from earlier lab notes. GRUB timings were not preserved
  # as a final working copy; compare with your local successful HCL.
  boot_wait = "5s"
  boot_command = [
    "c<wait2s>",
    "linux /casper/vmlinuz autoinstall 'ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ---<enter><wait2s>",
    "initrd /casper/initrd<enter><wait2s>",
    "boot<enter>"
  ]

  # Lab-only: password is provided at runtime, never in the repository.
  # Avoid single quotes in the temporary password because this is a shell string.
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  shutdown_timeout = "15m"
  headless         = false
}

build {
  sources = ["source.vmware-iso.ubuntu2204"]

  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "command -v vmware-toolbox-cmd && vmware-toolbox-cmd -v || true",
      "echo 'Packer Ubuntu provisioning completed'"
    ]
  }
}
