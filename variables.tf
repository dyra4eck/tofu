variable "node_name" {
	type = string
	description = "Имя ноды"
}

variable "pve_token" {
	type = string
	sensitive = true
	description = "Токен PVE-ноды"
}

variable "vms" {
	type = map(object({
		vm_id = number
		ip = string
	}))
	description = "map для VM: ключ = hostname, значение = параметры""
}

variable "password_hash" {
	type = string
	sensitive = true
	description = "Хеш пароля (openssl passwd -6)"
}
