terraform {
  required_providers {
    proxmox = { source = "bpg/proxmox", version = "~> 0.111" }
  }
}

provider "proxmox" {
  endpoint  = var.pve_endpoint
  api_token = var.pve_token
  insecure  = var.pve_insecure
}
