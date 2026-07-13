resource "proxmox_virtual_environment_file" "cloud_init" {
	content_type = "snippets"
	datastore_id = "local"
	node_name = var.node_name

	source_raw {
		data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
			vm_name = var.vm_name
			ssh_key = trimspace(file("~/.ssh/id_ed25519.pub"))
			password_hash = var.password_hash
		})
		file_name = "user-data.yaml"
	}
}
