resource "proxmox_virtual_environment_vm" "test" {
  for_each  = var.vms
  name      = each.key
  node_name = var.node_name
  vm_id     = each.value.vm_id

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 8192
  }

	clone {
		vm_id = 100
	}

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    file_format  = "raw"
    size         = 60
  }

  agent {
    enabled = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = "192.168.100.1"
      }
    }

    dns {
      domain  = "insyres.ru"
      servers = ["10.205.251.2"]
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init[each.key].id
  }

  network_device {
    bridge  = "vmbr1"
    vlan_id = each.value.vlan_id
  }

  tags = ["devops", "sandbox"]
}
