resource "proxmox_virtual_environment_vm" "test" {
	name = var.vm_name
	node_name = var.node_name
	vm_id = 100

	cpu {
		cores = 1
		type ="host"
	}

	memory {
		dedicated = 1024
	}

	disk {
		datastore_id = "local-lvm"
		import_from = proxmox_download_file.debian-cloud.id
		interface = "scsi0"
		file_format = "raw"
		size = 4
	}

	network_device {
		bridge = "vmbr0"
	}
	
	agent {
		enabled = true
	}

	initialization {
		ip_config {
			ipv4 {
				address = "192.168.100.50/24"
				gateway = "192.168.100.1"
			}
		}

		dns {
			servers = ["10.205.251.2"]
		}

		user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
	}

	tags = [ "devops", "sandbox" ]
}
