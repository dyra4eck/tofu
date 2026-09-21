# Стенды на Proxmox через OpenTofu

Создание, удаление и архивация стендов на кластере Proxmox VE.
ВМ клонируются из подготовленных cloud-init шаблонов (RedOS 8 и Astra Linux 1.8) и настраиваются через cloud-init.

Всё управление - через пайплайн GitLab CI. Руками `tofu` локально запускать **не нужно и не стоит**: state лежит в GitLab, и локальный запуск разъедется с тем, что видит CI.

---
## Как это работает

```
GitLab CI -> tofu clone -> VM из шаблона 351 / 352
                 |
                 |- cloud-init: пользователь, ключи, сеть, hostname
                 |- growpart:   корень растягивается до заданного размера
                 |- vendor-data: переполучение DHCP → регистрация в DNS
```

Один стенд — одна VM и один отдельный state. Адрес state формируется из короткого имени хоста: `stand-<HOST>`, где `HOST` — это часть `STAND_FQDN` до первой точки.
 Поэтому стенды не мешают друг другу, а повторный запуск пайплайна с тем же `STAND_FQDN` изменяет существующую вм, а не создаёт вторую.

---
## Запуск

Пайплайн запускается только вручную: из веб-интерфейса (Run pipeline), через API или триггером. На push в ветку выполняется лишь `validate`.

### Создать или изменить стенд

```sh
curl -X POST \
  -F token="$TRIGGER_TOKEN" \
  -F ref=main \
  -F "variables[STAND_FQDN]=<name>.insyres.ru" \
  -F "variables[STAND_OS]=astra" \
  -F "variables[STAND_MEMORY]=16" \
  -F "variables[STAND_CORES]=6" \
  -F "variables[STAND_DISK]=200" \
  http://gitlab/api/v4/projects/29/trigger/pipeline
```

Отработает `plan`, покажет, что будет сделано. `apply` — кнопка в пайплайне, автоматически не применяется никогда.

### Удалить стенд

```sh
curl -X POST \
  -F token="$TRIGGER_TOKEN" \
  -F ref=main \
  -F "variables[STAND_FQDN]=test-astra.insyres.ru" \
  -F "variables[STAND_ACTION]=destroy" \
  http://gitlab/api/v4/projects/29/trigger/pipeline
```

Для `destroy`, `archive` и `unarchive` нужен только `STAND_FQDN` —
параметры железа игнорируются, они читаются из state или из конфига ВМ.

---

## Переменные пайплайна

### Обязательные при создании

| Переменная     | Смысл                                                                                  | Пример            |
| -------------- | -------------------------------------------------------------------------------------- | ----------------- |
| `STAND_FQDN`   | Полное имя стенда. Короткая часть станет hostname и именем VM, она же определяет state | `test.insyres.ru` |
| `STAND_OS`     | Какой шаблон клонировать: `astra` или `redos`                                          | `astra`           |
| `STAND_CORES`  | Ядер                                                                                   | `6`               |
| `STAND_MEMORY` | Памяти **в гигабайтах** (в tfvars уйдёт ×1024), не больше 50                           | `16`              |
| `STAND_DISK`   | Диск в гигабайтах. **Не меньше размера диска шаблона**                                 | `200`             |

### Необязательные

| Переменная          | По умолчанию        | Смысл                                     |
| ------------------- | ------------------- | ----------------------------------------- |
| `STAND_ACTION`      | пусто (создание)    | `destroy` / `archive` / `unarchive`       |
| `STAND_IP`          | `dhcp`              | Статика в формате `10.205.209.50/24`      |
| `STAND_GATEWAY`     | **-**               | Обязателен вместе со статикой             |
| `STAND_VLAN_ID`     | `209`               | VLAN гостевой сети                        |
| `STAND_MAC_ADDRESS` | генерируется        | Задавать только если нужен конкретный MAC |
| `STAND_NODE_NAME`   | `pve03`             | Допустимы `pve` и `pve03`                 |
| `STAND_POOL_ID`     | `NONAME`            | Пул Proxmox                               |
| `STAND_ON_BOOT`     | `false`             | Автостарт при загрузке ноды               |
| `STAND_STARTED`     | `true`              | Запускать ли после создания               |
| `STAND_PROTECTION`  | `false`             | Запрет удаления средствами PVE            |
| `STAND_BACKUP`      | `true`              | Включать диск в бэкапы                    |
| `STAND_TAGS`        | **-**               | Через запятую, добавляются к тегу `tf`    |
| `STAND_DESCRIPTION` | «руками не трогать» | Текст в описании VM                       |

### Переменные проекта (заводятся в Settings → CI/CD)

| Переменная                | Смысл                                                    |
| ------------------------- | -------------------------------------------------------- |
| `PROXMOX_VE_API_TOKEN`    | Токен API Proxmox в формате `user@realm!tokenid=uuid`    |
| `ASTRA_TEMPLATE_ID`       | VMID шаблона Astra (сейчас `352`)                        |
| `REDOS_TEMPLATE_ID`       | VMID шаблона RedOS (сейчас `351`)                        |
| `STAND_PASSWORD_HASH_B64` | Хеш пароля пользователя `admin`, закодированный в base64 |

Пароль передаётся именно хешем (`openssl passwd -6`), а base64 — чтобы
символы `$` не съедались шеллом при экспорте.

---

## Стадии

| Стадия                               | Что делает                                    | Запуск        |
| ------------------------------------ | --------------------------------------------- | ------------- |
| `validate`                           | `tofu fmt -check`, `tofu validate`            | автоматически |
| `plan`                               | Собирает `pipeline.auto.tfvars`, считает план | автоматически |
| `apply`                              | Применяет сохранённый план                    | **вручную**   |
| `destroy:plan` / `destroy:apply`     | План удаления и удаление                      | apply вручную |
| `archive:plan` / `archive:apply`     | Бэкап в PBS, затем удаление ВМ                | apply вручную |
| `unarchive:plan` / `unarchive:apply` | Поиск бэкапа, восстановление, импорт в state  | apply вручную |

Архивация — ВМ уходит в PBS с пометкой по имени хоста, потом поднимается обратно тем же
`unarchive`. При восстановлении делается попытка занять прежний VMID.

---

## Шаблоны

| VMID  | ОС                          | Диск |
| ----- | --------------------------- | ---- |
| `351` | RedOS 8                     | 50G  |
| `352` | Astra Linux SE 1.8.1 «Орёл» | 52G  |

Размер диска шаблона — это **минимум** для любого клона. Задать `STAND_DISK`
меньше нельзя: диск клонируется целиком и может быть только расширен.
Уменьшение не поддерживает ни Proxmox, ни провайдер.

`LVMStor` - обычный LVM без thin-провижининга.

### Состав шаблона RedOS 8
Клон готового шаблона 1000.
Дополнительно установлено: `cloud-init`, `cloud-guest-utils`, `qemu-guest-agent`, `growpart`.

### Состав шаблона Astra 1.8

Установлено: `cloud-init`, `cloud-guest-utils`, `qemu-guest-agent`, `chrony`, консольные утилиты, SSH-сервер. Без графики, без ufw, без средств виртуализации.

Уровень защищённости — **«Орёл»** (базовый).

Разметка: одна таблица msdos, один первичный раздел ext4 на весь диск с флагом загрузочного, без swap и без LVM. Это обязательное условие работы `growpart` - он растягивает только последний раздел.

### Правки, без которых cloud-init не работает

`/etc/systemd/system/cloud-init-main.service.d/10-fix-ordering.conf`

```ini
[Unit]
DefaultDependencies=no
Conflicts=shutdown.target
Before=shutdown.target
```

В сборке cloud-init 24.3 для Astra у `cloud-init-main.service` объявлен `Before=sysinit.target`, но не отключены неявные зависимости. 
Systemd видит кольцо, выбрасывает задание на запуск — главный процесс не стартует, сокеты в `/run/cloud-init/share/` не создаются, все стадии завершаются с кодом 0. 
Внешне это выглядит как `cloud-init status: not started` и полное отсутствие инициализации.

`/etc/cloud/cloud.cfg.d/99-pve-datasource.cfg`

```yaml
datasource_list: [ NoCloud, ConfigDrive, None ]
```

Proxmox отдаёт конфигурацию как NoCloud (том с меткой `cidata` на `ide2`).

### Снипеты vendor-data

Лежат на ноде в `/var/lib/vz/snippets/`, подключаются через vendor_data_file_id` в зависимости от `stand_os`.

`dns-register-astra.yaml` переполучает DHCP-аренду, чтобы сервер зарегистрировал имя в зоне. 
Он **жёстко завязан на имя интерфейса `eth0`** - именно такое имя получает Astra после generalize. 
Если при пересборке шаблона интерфейс окажется `ens18`, снипет уйдёт в ветку `systemctl restart networking`, и стенд не появится в DNS. Ошибки при этом не будет.

---

## Пересборка шаблона

Шаблон нельзя запустить и поправить. Любое изменение - это новая сборка.

1. Создать VM с нужным диском, `machine=q35`, `scsihw=virtio-scsi-single`, сетью на `vmbr0` с тегом 209.
2. Установить систему по правилам разметки и состава выше.
3. Поставить пакеты, положить drop-in systemd и файл datasource.
4. Настроить chrony на `srv-ins-dc1.insyres.ru`.
5. Подключить cloud-init диск, агента и serial:
   ```sh
   qm set <VMID> --ide2 LVMStor:cloudinit --agent enabled=1 --serial0 socket
   ```
6. Обезличить образ:
   ```sh
	 # на ноде
   qm set <VMID> --delete ciuser,cipassword,ipconfig0

   # в шаблоне
   sudo cloud-init clean --logs --machine-id
   sudo rm -f /etc/ssh/ssh_host_*
   sudo find /var/log -type f -exec truncate -s 0 {} \;
   sudo rm -rf /var/log/journal/* /tmp/* /var/tmp/*
   sudo rm -f /root/.bash_history ~/.bash_history
   sudo shutdown -h now
   ```
   После этого машину **не включать**: при первой же загрузке systemd сгенерирует machine-id, sshd создаст host-ключи, и обезличивание откатится.
7. `qm template <VMID>` и обновить `ASTRA_TEMPLATE_ID` / `REDOS_TEMPLATE_ID`.

---

## Локальный запуск

Не нужен. Если всё же понадобилось посмотреть план без CI:

```sh
tofu init -backend=false
tofu validate
tofu fmt -check -recursive -diff
```

Полноценный `plan` локально потребует доступа к state в GitLab и
`TF_VAR_pve_token`. Применять локально **нельзя** - разъедется с CI.
