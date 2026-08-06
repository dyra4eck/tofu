output "vms" {
	description = "name -> VMID + ipv4"
  value = {
    for name, vm in proxmox_virtual_environment_vm.this : name => {
			vm_id = vm.vm_id
			ipv4 = vm.ipv4_addresses
		}
  }
}
