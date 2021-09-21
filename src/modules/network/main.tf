resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_name
  location = var.vnet_location
  resource_group_name = var.resource_group_name
  address_space = [var.vnet_address]
}

resource "azurerm_subnet" "subnet" {
  name = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address]
  enforce_private_link_endpoint_network_policies = var.subnet_enforce_private_link_endpoint_network_policies
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  for_each = var.linked_dns_domains
  name                  = var.vnet_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.key
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled = each.value.registration_enabled
}