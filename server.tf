data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "xrdp-vm" {
  name        = "xrdp"
  folder_id   = var.folder_id
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 4
    memory = 8

  }
  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-ssd"
      size     = 100
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.xrdp-subnet-a.id
    nat       = true
  }

  metadata = {
    user-data = templatefile("cloud-init.tmpl.yaml", {
      user = var.user,
      ssh_key = file(var.public_key_path)
    })
    serial-port-enable = 1
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${var.user}:${var.xrdp_password}' | sudo chpasswd",
      "sudo apt-get update",
      "sudo apt-get install xrdp -y",
      "sudo systemctl enable xrdp",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install ubuntu-desktop -y",
      "sudo ufw allow 3389/tcp",
      "sudo /etc/xrdp/startwm.sh",
      "sudo /etc/init.d/xrdp restart"
    ]
    connection {
      type = "ssh"
      user = var.user
      private_key = file(var.private_key_path)
      host = self.network_interface[0].nat_ip_address
    }
  }

  timeouts {
    create = "15m"
  }
}

