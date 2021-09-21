resource "azurerm_public_ip" "openvpn" {
  name = "openvpn"
  location =  var.vnet_location
  resource_group_name = var.resource_group_name
  allocation_method = "Static"
}

resource "azurerm_network_security_group" "openvpn" {
  name                = var.vnet_location
  location            = var.vnet_location
  resource_group_name =  var.resource_group_name
  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "openvpntpc"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.openvpn_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "openvpnudp"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = var.openvpn_port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "https"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "openvpn" {
  name = "openvpnserver"
  location = var.vnet_location
  resource_group_name = var.resource_group_name
  enable_ip_forwarding = true
  ip_configuration {
    name = "openvpnserver"
    subnet_id = var.subnet_id
    public_ip_address_id = azurerm_public_ip.openvpn.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.subnet_address, 6)
  }
}

resource "azurerm_network_interface_security_group_association" "openvpn" {
  network_interface_id      = azurerm_network_interface.openvpn.id
  network_security_group_id = azurerm_network_security_group.openvpn.id
}