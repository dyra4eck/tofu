resource "proxmox_virtual_environment_container" "this" {
	for_each = var.containers	
	node_name 	 = "pve" 	# имя узла в ProxmoxVE
	vm_id		 = each.value.vm_id
	unprivileged = true
	
	initialization {
		hostname = each.value.hostname
		ip_config {
			ipv4 {
				address = "dhcp"
			}
		}

		user_account {
			password = var.root_password
			keys		 = [trimspace(file("~/.ssh/id_ed25519.pub"))]
		}
	}

	disk {
		datastore_id = "local-lvm"	# это херня в ProxmoxVE — здесь будет корневая ФС контейнера
		size		 = each.value.disk_size
	}

	network_interface {
		name = "veth0"
	}

	operating_system {
		template_file_id = proxmox_download_file.templates[each.value.template].id
		type			 = each.value.type
	}
}

resource "proxmox_virtual_environment_vm" "debian_vm" {
	name = "mip-prod-git-v16"
	description = "prod stand for mip"
	tags = ["mip", "prod"]

	node_name = "pve"
	vm_id = 122

	disk {
		import_from = proxmox_download_file.debian_cloud.id
		interface = "virtio0"
		datastore_id = "local-lvm"
		size = 4
	}

	initialization {
		ip_config {
			ipv4 {
				address = "192.168.122.140/24"
				gateway = "192.168.122.1"
			}
		}

		dns {
			servers = ["192.168.122.1", "1.1.1.1"]
		}

		user_account {
			username = "admin"
			password = "P@ssw0rd"
			keys = [trimspace(file("~/.ssh/id_ed25519.pub"))]
		}
	}

	cpu {
		cores = 1
		type = "host"
	}

	memory {
		dedicated = 512
	}

	agent {
		enabled = false
	}

	stop_on_destroy = true

	network_device {
		bridge = "vmbr0"
	}
}

