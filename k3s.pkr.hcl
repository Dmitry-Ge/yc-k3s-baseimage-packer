#packer {
#  required_plugins {
#    yandex = {
#      version = ">= 1.1.0"
#      source  = "github.com/yandex-cloud/packer-plugin-yandex"
#    }
#  }
#}

variable "folder_id" {
 type    = string
 default = env("YC_FOLDER_ID")
}

variable "service_account_key_file" {
 type    = string
 default = env("YC_SA_KEY_FILE")
}

variable "subnet_id" {
 type    = string
 default = env("YC_SUBNET_ID")
}

variable "zone" {
 type    = string
 default = "ru-central1-a"
}

variable "image_name" {
  type    = string
  default = "k3s-agent-debian12-{{timestamp}}"
}

# Конфигурация источника (образа)
source "yandex" "k3s-agent" {
  folder_id              = var.folder_id
  # service_account_key_file = var.service_account_key_file
  subnet_id              = var.subnet_id
  zone                   = var.zone
  image_name             = var.image_name
  image_family           = "k3s-agent"
  source_image_family    = "debian-12"
  ssh_username           = "debian"
  use_ipv4_nat           = "true"
  # disk_size              = 10000 # MB
  disk_type              = "network-nvme"

  # Метаданные для доступа по SSH во время сборки
  # metadata = {
  #   ssh-keys = "debian:${file("${path.root}/id_rsa.pub")}"
  # }
}

# Процесс сборки
build {
  sources = ["source.yandex.k3s-agent"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y curl apt-transport-https ca-certificates",

      # Скачиваем скрипт установки k3s
      "curl -sfL https://get.k3s.io -o /tmp/install.sh",
      "chmod +x /tmp/install.sh",

      # Устанавливаем k3s в режиме агента
      # ВАЖНО: INSTALL_K3S_SKIP_START=true предотвращает запуск службы во время сборки.
      # Это нужно, чтобы при запуске новой VM из образа сгенерировались уникальные сертификаты.
      "sudo INSTALL_K3S_SKIP_START=true K3S_URL=https://10.131.0.10:6443 K3S_TOKEN=my_str0ng_s3cret_k3y /tmp/install.sh agent",

      # Включаем службу, чтобы она стартовала при загрузке реальной VM
      "sudo systemctl enable k3s-agent",

      # Очищаем логи и кэш для уменьшения размера образа
      "sudo journalctl --rotate",
      "sudo journalctl --vacuum-time=1s",
      "sudo apt-get clean",
      "sudo rm -rf /tmp/install.sh"
    ]
  }
}

