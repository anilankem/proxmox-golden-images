packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = ">= 1.1.0"
    }
  }
}

variable "proxmox_url" {}
variable "token_id" {}
variable "token_secret" {}

source "proxmox" "rocky" {
  proxmox_url = var.proxmox_url
  username    = var.token_id
  token       = var.token_secret
  insecure_skip_tls_verify = true

  node        = "pve"
  vm_id       = "9002"
  vm_name     = "rocky-9-golden"

  iso_file    = "local:iso/Rocky-9-latest-x86_64-boot.iso"

  cores       = 2
  memory      = 2048
  scsi_controller = "virtio-scsi-pci"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    type    = "scsi"
    storage = "local-lvm"
    size    = "20G"
  }

  cloud_init = true
  qemu_agent = true
}

build {
  sources = ["source.proxmox.rocky"]

  provisioner "shell" {
    inline = [
      "dnf -y update",
      "dnf -y install openssh-server qemu-guest-agent cloud-init sudo",
      "systemctl enable sshd",
      "systemctl enable qemu-guest-agent",
      "systemctl start sshd",
      "systemctl start qemu-guest-agent",

      # Clean for template
      "cloud-init clean",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",
      "rm -rf /var/lib/cloud/*",

      "shutdown -h now"
    ]
  }
}
