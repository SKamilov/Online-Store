resource "yandex_vpc_network" "momo_net" {
  name = "momo-net"
}

resource "yandex_vpc_subnet" "momo_subnet" {
  name           = "momo-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.momo_net.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}