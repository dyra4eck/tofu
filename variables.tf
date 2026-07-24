variable "node_name" {
  type        = string
  description = "Имя ноды"
}

variable "pve_token" {
  type        = string
  sensitive   = true
  description = "Токен PVE-ноды"
}

variable "vms" {
  type = map(object({
    vm_id   = number
    ip      = string
    vlan_id = number
  }))
  description = "map для VM: ключ = hostname, значение = параметры"
}

variable "password_hash" {
  type        = string
  sensitive   = true
  description = "Хеш пароля (openssl passwd -6)"
}

variable "ssh_key_files" {
  type        = list(string)
  description = "Публичные ключи"
  default     = ["~/.ssh/id_ed25519.pub", "~/.ssh/ansible-prod.pub"]
}
