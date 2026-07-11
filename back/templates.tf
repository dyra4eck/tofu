resource "proxmox_download_file" "templates" {
    for_each = var.templates

    content_type = "vztmpl"     # тип "шаблон контейнера"
    datastore_id = "local"      # в pve хранится здесь
    node_name = "pve"           # имя ноды
    url = each.value            
    overwrite_unmanaged = true
}