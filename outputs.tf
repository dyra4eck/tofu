output "vm_ips" {
	value = {
		for name, vm in proxmox_virtual_environment_vm.test: name => vm.ipv4_addresses
	}
}
