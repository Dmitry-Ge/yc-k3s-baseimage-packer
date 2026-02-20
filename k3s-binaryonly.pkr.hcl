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
  default = "k3s-universal-debian12-{{timestamp}}"
}

# Версия K3s, которую хотим установить
variable "k3s_version" {
  type    = string
  default = "v1.28.5+k3s1"
}

source "yandex" "k3s-universal" {
  folder_id                = var.folder_id
  service_account_key_file = var.service_account_key_file
  subnet_id                = var.subnet_id
  zone                     = var.zone
  image_name               = var.image_name
  image_family             = "k3s-universal"
  source_image_family      = "debian-12"
  ssh_username             = "debian"
  # disk_size                = 10000
  disk_type                = "network-nvme"
  
  metadata = {
    ssh-keys = "debian:${file("${path.root}/id_rsa.pub")}"
  }
}

build {
  sources = ["source.yandex.k3s-universal"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl",
      
      # Скачиваем конкретную версию бинарного файла напрямую
      # Это чище, чем запускать install.sh, так как не создается никаких служб
      "sudo curl -sfL https://github.com/k3s-io/k3s/releases/download/${var.k3s_version}/k3s -o /usr/local/bin/k3s",
      
      # Делаем файл исполняемым
      "sudo chmod +x /usr/local/bin/k3s",
      
      # Создаем ссылку kubectl (удобно, чтобы k3s kubectl работало или просто kubectl)
      "sudo ln -s /usr/local/bin/k3s /usr/local/bin/kubectl",
      
      # Создаем базовую директорию для конфигов (но пустую)
      "sudo mkdir -p /etc/rancher/k3s",
      
      # Очищаем кэш и логи
      "sudo apt-get clean",
      "sudo rm -rf /var/cache/apt/*",
      "sudo truncate -s 0 /var/log/*log || true"
    ]
  }
}


# see cloud-config for master and worker examples

