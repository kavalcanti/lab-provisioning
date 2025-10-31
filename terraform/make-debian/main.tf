terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.85.0"
    }
  }
}


provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent    = true
    username = var.proxmox_ssh_user
    node {
      name    = var.proxmox_node
      address = var.proxmox_node_ip
    }
  }
}

resource "proxmox_virtual_environment_vm" "debian_vm" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id  
  

  clone {
    vm_id = var.template_id
    full  = var.clone_full
  }

  started = true

  agent {
    enabled = var.enable_qemu_agent
  }

  cpu {
    cores   = var.vm_cores
    sockets = var.vm_sockets
  }

  memory {
    dedicated = var.vm_memory
  }

  disk {
    datastore_id = var.datastore_disk
    interface    = var.disk_interface
    size         = var.vm_disk_size
    discard      = var.disk_discard
    file_format  = "qcow2"
  }

  # Cloud-init configuration
  initialization {
    datastore_id = var.datastore_cloudinit
    
    # Network configuration
    ip_config {
      ipv4 {
        address = var.network_mode == "dhcp" ? "dhcp" : var.network_ip
        gateway = var.network_mode == "static" ? var.network_gateway : null
      }
    }

    # Inline cloud-init user data (no separate file needed)
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  network_device {
    bridge = var.network_bridge
    model  = var.network_model
  }

  boot_order = [var.disk_interface]
  
  serial_device {}
}

# Cloud-init configuration stored as snippet
resource "proxmox_virtual_environment_file" "cloud_config" {
  node_name    = var.proxmox_node
  content_type = "snippets"
  datastore_id = var.datastore_snippets

  source_raw {
    data = <<-EOF
    #cloud-config
    # Set root password explicitly
    chpasswd:
      expire: false
      list: |
        root:${var.root_password}

    # SSH Configuration
    ssh_pwauth: ${var.ssh_pwauth}
    disable_root: ${var.disable_root}
    
    # Configure SSH daemon directly via cloud-init
    ssh:
      PasswordAuthentication: ${var.ssh_pwauth ? "yes" : "no"}
      PermitRootLogin: ${var.disable_root ? "no" : "yes"}
      ChallengeResponseAuthentication: no
    
    # Backup: Force SSH config changes
    runcmd:
      - echo "root:${var.root_password}" | chpasswd
      - sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
      - sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
      - systemctl restart sshd
      - systemctl start qemu-guest-agent
      - systemctl enable qemu-guest-agent
    
    packages:
      - python3
      - python3-apt
      - qemu-guest-agent
    
    package_update: ${var.package_update}
    package_upgrade: ${var.package_upgrade}
    EOF

    file_name = "cloud-init-${var.vm_name}.yaml"
  }
}
