variable "do_token" {
  type      = string
  sensitive = true
}

variable "ssh_key_fingerprint" {
  type = string
}

variable "droplet_name" {
  type = string
}

variable "region" {
  type    = string
  default = "fra1"
}

variable "size" {
  type    = string
  default = "s-1vcpu-2gb"
}

variable "image" {
  type    = string
  default = "ubuntu-22-04-x64"
}
