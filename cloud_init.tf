resource "proxmox_virtual_environment_file" "cloud_init" {
  for_each     = var.vms
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
      vm_name       = each.key
      ssh_keys      = local.ssh_keys
      password_hash = var.password_hash
    })
    file_name = "user-data-${each.key}.yaml"
  }
}
