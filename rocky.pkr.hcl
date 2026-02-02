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

  node     = "proxmox"
  vm_id    = 9002
  vm_name  = "rocky-9-golden"
  os       = "other"
  memory   = 2048

  cpu_type = "host"
  cores    = 2
  sockets  = 1
  numa     = false

  scsi_controller = "virtio-scsi-pci"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    type         = "scsi"
    storage_pool = "local-lvm"
    disk_size    = "20G"
    format       = "raw"
  }

  boot_iso {
    type     = "scsi"
    iso_file = "local:iso/Rocky-9-latest-x86_64-minimal.iso"
    unmount  = true
  }

  # 🔥 Kickstart magic
  http_directory = "http"
  boot_wait      = "5s"

  boot_command = [
    "<tab> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>"
  ]

  ssh_username = "root"
  ssh_password = "rocky"
  ssh_timeout  = "30m"
}

build {
  sources = ["source.proxmox-iso.rocky"]

provisioner "shell" {
  expect_disconnect = true

  inline = [
    "dnf -y update",
    "dnf -y install qemu-guest-agent cloud-init sudo",
    "cloud-init clean",
    "truncate -s 0 /etc/machine-id",
    "rm -f /var/lib/dbus/machine-id",
    "rm -rf /var/lib/cloud/*",
    "shutdown -h now"
    ]
  }
}
