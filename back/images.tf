resource "proxmox_download_file" "debian_cloud" {
	content_type = "import"
  datastore_id = "local"
  node_name = "pve"
  url = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  file_name = "debian-13-genericcloud-amd64.qcow2"
	
}
