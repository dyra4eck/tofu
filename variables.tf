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

### user

variable "vm_username" {
  type    = string
  default = "admin"
}

variable "password_hash" {
  type      = string
  sensitive = true
  default   = null
}

variable "dns_servers" {
  type    = list(string)
  default = []
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
  type        = string
  default     = null
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
    # --- обязательно -----------------------------------
    vm_id = number

    # --- размещение -----------------------------------
    node_name = optional(string) # null -> var.node_name
    pool_id   = optional(string) # null -> var.pool_id

    # --- сеть ------------------------------------------
    ip          = optional(string, "dhcp")
    gateway     = optional(string) # только для статики
    vlan_id     = optional(number) # null -> var.network_vlan_id
    mac_address = optional(string)

    # --- железо ----------------------------------------
    cores   = optional(number, 3)
    sockets = optional(number, 2)
    memory  = optional(number, 8192)
    disk    = optional(number, 50) # только >= 50

    # --- поведение -------------------------------------
    on_boot    = optional(bool)        # null -> var.on_boot ток чето не работает нихуя, они все равно запускаются
    started    = optional(bool, true)  # false = не запускать после создания
    protection = optional(bool, false) # true = запрет на удаление в pve
    backup     = optional(bool, false)

    # --- tags -----------------------------------------
    tags        = optional(list(string), []) # доавбление к default_tags
    description = optional(string)           # null -> дефолтный текст
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

variable "migrate_on_node_change" {
  type        = bool
  default     = true
  description = "при смене node_name вм мигрирует, вместо пересоздания"
}
