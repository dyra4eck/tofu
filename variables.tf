### подключение

variable "pve_endpoint" {
  type        = string
  description = "url api proxmox"
}

variable "pve_token" {
  type        = string
  sensitive   = true
  description = "api токен"
}

variable "pve_insecure" {
  type        = bool
  default     = true
  description = "хз хуйня какая-то"
}

variable "node_name" {
  type        = string
  description = "Имя ноды"
}

### изолирование

variable "pool_id" {
  type        = string
  description = "пул вмок"
}

variable "vm_id_range" {
  type        = list(number)
  description = "диапазон vmid"

  validation {
    condition     = length(var.vm_id_range) == 2 && var.vm_id_range[0] < var.vm_id_range[1]
    error_message = "vm_id_range должен быть между [min, max]"
  }
}

### source

variable "template_vm_id" {
  type        = number
  description = "vmid cloud-init шаблона"
}

variable "template_node_name" {
  type        = string
  default     = null
  description = "нода шаблона"
}

### сеть + datastore

variable "datastore_disk" {
  type        = string
  default     = "LVMStor"
  description = "диск"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr0"
  description = "vmbr0"
}

variable "network_vlan_id" {
  type        = number
  default     = 209
  description = "vlan стендов"
}

variable "network_firewall" {
  type        = bool
  default     = true
  description = "firewall=1"
}

variable "dns_domain" {
  type        = list(string)
  default     = []
  description = "пустой - резолв из dhcp"
}

### железо

variable "cpu_type" {
  type        = string
  default     = "x86-64-v2-AES"
  description = "как в шаблоне 100"
}

variable "on_boot" {
  type        = bool
  default     = false
  description = "автостарт при загрузке ноды"
}

### сами тачки

variable "vms" {
  description = "map для vm: ключ = hostname"

  type = map(object({
    vm_id   = number
    ip      = optional(string, "dhcp")
    gateway = optional(string)
    cores   = optional(number, 3)
    sockets = optional(number, 2)
    memory  = optional(number, 8192)
    disk    = optional(number, 50)
  }))
  # validation потом добавлю
}

variable "default_tags" {
  type    = list(string)
  default = ["tf"]
}

variable "ssh_key_files" {
  type        = list(string)
  description = "public ключи"
  default     = ["~/.ssh/id_ed25519.pub", "~/.ssh/ansible-prod.pub"]
}
