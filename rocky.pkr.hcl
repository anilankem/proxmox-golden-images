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

source "proxmox-iso" "rocky" {
  proxmox_url  = var.proxmox_url
  username     = var.token_id
  token        = var.token_secret
  insecure_skip_tls_verify = true
  cpu          = "host"
  node         = "pve"
  vm_id        = 9002
  vm_name      = "rocky-9-golden"

  # MUST match what exists on Proxmox
  iso_file     = "local:iso/Rocky-9-latest-x86_64-boot.iso"
  unmount_iso  = true

  cores        = 2
  memory       = 2048
  scsi_controller = "virtio-scsi-pci"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # local-lvm = raw only
  disks {
    type         = "scsi"
    storage_pool = "local-lvm"
    disk_size    = "20G"
    format       = "raw"
  }

  ssh_username  = "root"
  ssh_password  = "rocky"
  ssh_timeout   = "30m"
}

build {
  sources = ["source.proxmox-iso.rocky"]

  provisioner "shell" {
    inline = [
      "dnf -y update",
      "dnf -y install openssh-server qemu-guest-agent cloud-init sudo",
      "systemctl enable sshd",
      "systemctl enable qemu-guest-agent",

      "cloud-init clean",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",
      "rm -rf /var/lib/cloud/*",

      "shutdown -h now"
    ]
  }
}
