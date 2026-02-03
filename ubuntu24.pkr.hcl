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

source "proxmox-iso" "ubuntu24" {
  proxmox_url = var.proxmox_url
  username    = var.token_id
  token       = var.token_secret
  insecure_skip_tls_verify = true

  node    = "proxmox"
  vm_id   = 9004
  vm_name = "ubuntu24-golden"
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


  # ✅ Disk (v1.2 syntax)
  disks {
    type         = "scsi"
    storage_pool = "local-lvm"
    disk_size    = "20G"
    format       = "raw"
  }
 

  # ✅ ISO (v1.2 syntax)
  boot_iso {
    type     = "scsi"
    iso_file = "local:iso/ubuntu-24.iso"
    unmount  = true
  }

  http_directory = "http"
  boot_wait = "25s"

  boot_command = [
  "<esc><wait>",
  "e<wait>",
  "<down><down><down><down><end>",
  " autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
  "<f10>"
]


  ssh_username = "root"
  ssh_password = "anilankem"
  ssh_timeout  = "40m"

  qemu_agent = true
}

build {
  sources = ["source.proxmox-iso.ubuntu24"]

provisioner "shell" {
  inline = [
    "export DEBIAN_FRONTEND=noninteractive",
    "apt-get update",
    "apt-get -y upgrade",
    "apt-get -y install qemu-guest-agent cloud-init sudo",
    "cloud-init clean",
    "truncate -s 0 /etc/machine-id",
    "rm -f /var/lib/dbus/machine-id",
    "rm -rf /var/lib/cloud/*"
  ]
}
}