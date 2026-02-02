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

source "proxmox-iso" "centos10" {
  proxmox_url              = var.proxmox_url
  username                 = var.token_id
  token                    = var.token_secret
  insecure_skip_tls_verify = true

  node     = "proxmox"
  vm_id    = 9003
  vm_name  = "centos10-stream-golden"
  os       = "l26"

  memory   = 2048
  cores    = 2
  sockets  = 1
  cpu_type = "host"

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

  # ISO already uploaded to Proxmox
  iso_file          = "local:iso/CentOS-Stream-10-latest-x86_64-dvd1.iso"
  iso_storage_pool  = "local"
  unmount_iso       = true

  # Kickstart from Packer HTTP
  http_directory = "http"
  boot_wait      = "10s"

  boot_command = [
    "<esc><wait>",
    "linux inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/cent10-ks.cfg ip=dhcp<enter>"
  ]

  ssh_username = "root"
  ssh_password = "anilankem"
  ssh_timeout  = "40m"

  qemu_agent = true
}

build {
  sources = ["source.proxmox-iso.centos10"]

  provisioner "shell" {
    inline = [
      "dnf -y update",
      "dnf -y install qemu-guest-agent cloud-init sudo",
      "systemctl enable qemu-guest-agent",
      "systemctl enable cloud-init",

      # Golden image cleanup
      "cloud-init clean",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",
      "rm -rf /var/lib/cloud/*"
    ]
  }
}
