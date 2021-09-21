locals {
  bind9_conf = templatefile("${path.module}/templates/bind9_conf.tpl", {
    VNET_ADDRESS = var.vnet_address
    OPENVPN_ADDRESS = var.openvpn_address
    AZURE_PRIVATE_DNS_IP = var.azure_dns_service_ip
  })
  rsa_vars = templatefile("${path.module}/templates/rsa_vars.tpl", {
    CA_COUNTRY = var.openvpn_ca_values.country
    CA_PROVINCE = var.openvpn_ca_values.province
    CA_CITY = var.openvpn_ca_values.city
    CA_ORGANIZATION = var.openvpn_ca_values.organization
    CA_EMAIL = var.openvpn_ca_values.email
  })
  openvpn_server_conf = templatefile("${path.module}/templates/openvpn_server.tpl", {
    OPENVPN_PORT = var.openvpn_port
    OPENVPN_PROTOCOL = var.openvpn_protocol
    OPENVPN_ADDRESS = replace(var.openvpn_address, "//\\d+/", "")
    OPENVPN_ADDRESS_MASK = cidrnetmask(var.openvpn_address)
    VNET_ROUTES = {
      for v in var.openvpn_routes : v.route => v.mask
    }
    PRIVATE_DNS_IP = azurerm_network_interface.openvpn.private_ip_address
  })
  openvpn_client_conf = templatefile("${path.module}/templates/openvpn_client.tpl", {
    OPENVPN_SERVER = azurerm_public_ip.openvpn.ip_address
    OPENVPN_PORT = var.openvpn_port
    OPENVPN_PROTOCOL = var.openvpn_protocol
  })
  iptables_sh = templatefile("${path.module}/templates/iptables_sh.tpl", {
    OPENVPN_SERVER = azurerm_public_ip.openvpn.ip_address
    OPENVPN_PORT = var.openvpn_port
    OPENVPN_PROTOCOL = var.openvpn_protocol
    OPENVPN_ADDRESS = var.openvpn_address
    IP = azurerm_network_interface.openvpn.private_ip_address
  })
}

variable "resource_group_name" {}

variable "vnet_location" {}

variable "vnet_address" {}

variable "subnet_address"{}

variable "subnet_id" {}

variable "azure_dns_service_ip" {
  default = "168.63.129.16"
}

variable "openvpnserver_vm_user" {
  default = "adminuser"
}

variable "openvpnserver_vm_size" {
  default = "Standard_B2s"
}

variable "openvpnserver_vm_user_ssh_path" {}

variable "openvpnserver_vm_user_ssh_private_key_path" {}

variable "openvpn_address" {
  default = "10.8.0.0/16"
}

variable "openvpn_ca_values" {
  default = {
    country = "BR"
    province = "SP"
    city = "Itu"
    organization = "CodeFeeling"
    email = "contato@ecodefeeling.com.br"
  } 
}

variable "openvpn_port" {
  default = "1194"
}

variable "openvpn_protocol" {
  default = "udp"
}

variable "openvpn_routes" {
  default = []
}