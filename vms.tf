locals {
	ssh_keys = [ for p in var.ssh_key_files : trimspace(file(pathexpand(p)))]
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each  = var.vms
 
  name      = each.key
  node_name = var.node_name
  vm_id     = each.value.vm_id
  pool_id = var.pool_id
	description = "руками не трогать 0_o"
	tags = var.default_tags

	machine = "q35"
	scsi_hardware = "virtio-scsi-single"
	on_boot = var.on_boot

	stop_on_destroy = true

	clone {
		vm_id = var.template_vm_id
		node_name = var.template_node_name
		full = true
	}

	cpu {
		cores = each.value.cores
		sockets = each.value.sockets
		type = var.cpu_type
	}

	memory {
		dedicated = each.value.memory
	}

  disk {
    datastore_id = var.datastore_disk
    interface    = "scsi0"
    file_format  = "raw"
    size         = each.value.disk
		iothread = true
  }

  agent {
    enabled = true
  }

  initialization {
		datastore_id = var.datastore_disk

    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = each.value.ip == "dhcp" ? null : each.value.gateway
      }
    }

    dynamic "dns" {
			for_each = length(var.dns_servers) > 0 ? [1] : []
			content {
	      domain  = var.dns_domain
  	    servers = var.dns_servers
			}
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init[each.key].id
  }

  network_device {
    bridge  = var.network_bridge
    vlan_id = var.network_vlan_id
		firewall = var.network_firewall
		model = "virtio"
  }

	lifecycle {
		precondition {
			condition = (
				each.value.vm_id >= var.vm_id_range[0] &&
				each.value.vm_id <= var.vm_id_range[1]
			)
			error_message = "VMID ${each.value.vm_id} вышло за выделенный диапазон ${var.vm_id_range[0]}-${var.vm_id_range[1]}
		}
	}
}
