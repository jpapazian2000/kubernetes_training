variable "project" { }

variable "region" {
  default = "europe-west3"
}

variable "zone" {
    default = "europe-west3-c"
}
variable "owner" { }
variable "se-region" {}
variable "purpose" {}
variable "ttl" {}
variable "terraform" {}
variable "hc-internet-facing" {}
variable "prefix" {}

variable "subnet_prefix" {}

variable "machine_type" {}

variable "ssh_keys" {}

variable "ssh_user" {
    default = "jerome"
}
