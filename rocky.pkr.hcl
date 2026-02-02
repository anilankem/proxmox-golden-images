packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1.2"
    }
  }
}

variable "proxmox_url" {}
variable "token_id" {}
variable "token_secret" {}

source "proxmox-iso" "rocky" {
  proxmox_url              = var.proxmox_url
  username                 = var.token_id
  token                    = var.token_secret
  insecure_skip_tls_verify = true

  node    = "proxmox"
  vm_id   = 9002
  vm_name = "rocky-9-golden"

  # ✅ NEW names in 1.2.x
  cpu {
    type    = "host"
    sockets = 1
    cores   = 2
  }

  memory = 2048
  os     = "other"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    interface    = "scsi"
    storage_pool = "local-lvm"
    size         = "20G"
  }

  scsi_controller = "virtio-scsi-pci"

  iso {
    storage_pool = "local"
    file         = "Rocky-9-latest-x86_64-boot.iso"
  }

  ssh_username = "root"
  ssh_password = "rocky"
  ssh_timeout  = "30m"
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
