resource "proxmox_virtual_environment_file" "dns_register" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.template_node_name

  source_raw {
    file_name = "dns-register.yaml"
    data      = <<-EOF
      #cloud-config
      runcmd:
	- [ sh, -c, 'nmcli con up "$(nmcli -t -f NAME con show --active | head -1)" || systemctl restart NetworkManager' ] 
    EOF
  }
}
