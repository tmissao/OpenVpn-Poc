variable "project_name" { 
  default = "openvpn" 
}

variable "location" {
  default = "East US"
}

variable "azure_dns_service_ip" {
  default = "168.63.129.16"
}

variable "vnet_name" {
  default = "openpvn-vnet"
}

variable "vnet_address" {
  default = "20.20.0.0/16"
}

variable "subnet_name" {
  default = "default"
}

variable "subnet_address" {
  default = "20.20.0.224/27"
}

variable "vnet2_name" {
  default = "openpvn-pair-vnet"
}

variable "vnet2_address" {
  default = "30.30.0.0/16"
}

variable "subnet2_name" {
  default = "default"
}

variable "subnet2_address" {
  default = "30.30.0.0/24"
}

variable "openvpnserver_vm_user" {
  default = "adminuser"
}

variable "openvpnserver_vm_user_ssh_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "openvpnserver_vm_user_ssh_private_key_path" {
  default = "~/.ssh/id_rsa"
}

variable "openvpn_protocol" {
  default = "udp"
}

variable "openvpn_port" {
  default = "1194"
}

variable "openvpn_address" {
  default = "10.10.5.0/24"
}

variable "openvpn_ca_values" {
  default = {
    country = "BR"
    province = "SP"
    city = "Sao Paulo"
    organization = "Acqio"
    email = "contato@esfera5.com.br"
  }
}

variable "openvpnserver_vm_size" {
  default = "Standard_B2s"
}

variable "private_dns_name" {
  default = "vpn.internal"
}

variable "storage_account_name" {
  default = "missaoprivateaccess"
}
variable "storage_account_tier" {
  default = "Standard"
}
variable "storage_account_kind" {
  default = "StorageV2"
}
variable "storage_account_replication_type" {
  default = "LRS"
}