resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_name
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = [var.vnet_address]
}

resource "azurerm_subnet" "subnet" {
  name = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_virtual_network" "vnet2" {
  name = var.vnet2_name
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space = [var.vnet2_address]
}

resource "azurerm_subnet" "subnet2" {
  name = var.subnet2_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = [var.subnet2_address]
}


resource "azurerm_public_ip" "openvpn" {
  name = "openvpn_public_ip"
  location =  azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
}

resource "azurerm_network_security_group" "openvpn" {
  name                = "${var.vnet_name}-openvpn-server"
  location            = var.location
  resource_group_name =  azurerm_resource_group.rg.name
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
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_ip_forwarding = true
  ip_configuration {
    name = "openvpnserver"
    subnet_id = azurerm_subnet.subnet.id
    public_ip_address_id = azurerm_public_ip.openvpn.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.subnet_address, 4)
  }
}

resource "azurerm_network_interface_security_group_association" "openvpn" {
  network_interface_id      = azurerm_network_interface.openvpn.id
  network_security_group_id = azurerm_network_security_group.openvpn.id
}

resource "azurerm_network_interface" "vm" {
  name = "vm"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_ip_forwarding = true
  ip_configuration {
    name = "vm"
    subnet_id = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address = cidrhost(var.subnet2_address, 10)
  }
}

resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                      = "${var.vnet_name}-to-${var.vnet2_name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
}

resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                      = "${var.vnet2_name}-to-${var.vnet_name}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}