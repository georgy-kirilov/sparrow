provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "vm" {
  name     = var.droplet_name
  region   = var.region
  size     = var.size
  image    = var.image
  ssh_keys = [var.ssh_key_fingerprint]
  tags     = ["auto", "terraform"]
}
