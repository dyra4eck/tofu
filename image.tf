resource "proxmox_download_file" "debian-cloud" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.node_name
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}

resource "proxmox_download_file" "alma-cloud" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.node_name
  url          = "https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2"
}
