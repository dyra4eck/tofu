output "containers_ip" {
  value = {
    for name, ct in proxmox_virtual_environment_container.this : name => ct.ipv4 # this - это имя
  }
}

#output "debian_vm_ip" {
#	value = proxmox_virtual_environment_vm.debian_vm.ipv4_addresses[1]
#}
