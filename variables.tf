variable "node_name" {
	type = string
	description = "Имя ноды"
}

variable "pve_token" {
	type = string
	sensitive = true
	description = "Токен PVE-ноды"
}

variable "vm_name" {
	type = string
	description = "Имя VM"
}

variable "password_hash" {
	type = string
	sensitive = true
	description = "Хеш пароля (openssl passwd -6)"
}
