resource "azurerm_private_dns_zone" "privatelink_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_link" {
  name                  = var.vnet_name
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_link2" {
  name                  = var.vnet2_name
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet2.id
  registration_enabled = false
}

resource "azurerm_private_endpoint" "blobstorage" {
  name                    = var.storage_account_name
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  subnet_id               = azurerm_subnet.subnet.id

  private_service_connection {
    name                              = "blob-${var.storage_account_name}"
    private_connection_resource_id    = azurerm_storage_account.storage.id
    is_manual_connection              = false
    subresource_names                 = ["blob"]
  }
}

resource "azurerm_private_dns_a_record" "storage" {
  name                = var.storage_account_name
  zone_name           = azurerm_private_dns_zone.privatelink_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.blobstorage.private_service_connection[0].private_ip_address]
}
