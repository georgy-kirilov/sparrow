terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_droplets" "existing" {
  filter {
    key    = "name"
    values = [var.droplet_name]
  }
}

resource "digitalocean_droplet" "vm" {
  count    = length(data.digitalocean_droplets.existing.droplets) == 0 ? 1 : 0
  name     = var.droplet_name
  region   = var.region
  size     = var.size
  image    = var.image
  ssh_keys = [var.ssh_key_fingerprint]
  tags     = ["auto","terraform"]
}

locals {
  droplet = length(data.digitalocean_droplets.existing.droplets) > 0
    ? data.digitalocean_droplets.existing.droplets[0]
    : digitalocean_droplet.vm[0]
}
