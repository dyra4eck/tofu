resource "proxmox_download_file" "debian-cloud" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.node_name
  url          = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
}
