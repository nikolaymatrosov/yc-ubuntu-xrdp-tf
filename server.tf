data "yandex_compute_image" "ubuntu-20-04" {
  family = "ubuntu-2004-lts"
}

data "template_file" "cloud_init" {
  template = file("cloud-init.tmpl.yaml")
  vars = {
    user = var.user
    ssh_key = file(var.public_key_path)
  }
}

resource "yandex_compute_instance" "xrdp-vm" {
  name = "xrdp"
  folder_id = var.folder_id
  platform_id = "standard-v2"
  zone = "ru-central1-a"

  resources {
    cores = 4
    memory = 8

  }
  boot_disk {
    mode = "READ_WRITE"
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu-20-04.id
      type = "network-ssd"
      size = 100
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.xrdp-subnet-a.id
    nat = true
  }

  metadata = {
    user-data = data.template_file.cloud_init.rendered
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
    create = "10m"
  }
}

