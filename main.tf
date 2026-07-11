terraform {
	required_providers {
		proxmox = { source = "bpg/proxmox", version = "~> 0.111" }
	}
}

provider "proxmox" {
	endpoint = "https://192.168.100.2:8006/"
	api_token = var.pve_token
	insecure = true
	ssh { 
		agent = true
		username = "root"
	}
}
