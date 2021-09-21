variable "vnet_name" {
  default = "vnet"
}

variable "vnet_address" {
  default = "10.10.0.0/16"
}

variable "vnet_location" {
  default = "East US"
}

variable "subnet_name" {
  default = "default"
}

variable "subnet_address" {
  default = "10.10.0.0/24"
}

variable "subnet_enforce_private_link_endpoint_network_policies" {
  default = false
}

variable "linked_dns_domains" {
  default = {}
}

variable "resource_group_name" {}