resource "yandex_vpc_network" "vpc-xrdp" {
  name = "vpc-xrdp"
}

resource "yandex_vpc_subnet" "xrdp-subnet-a" {
  name           = "xrdp-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc-xrdp.id
  v4_cidr_blocks = ["10.240.1.0/24"]
}
