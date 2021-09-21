resource "azurerm_storage_account" "storage" {
  name                      = var.storage_account_name
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = azurerm_resource_group.rg.location
  account_tier              = var.storage_account_tier
  account_kind              = var.storage_account_kind
  account_replication_type  = var.storage_account_replication_type
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  allow_blob_public_access  = false
  network_rules {
    default_action             = "Deny"
    bypass                = [ "AzureServices" ]
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "storage_client" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_private_endpoint" "blobstorage" {
  name                    = var.storage_account_name
  resource_group_name     = azurerm_resource_group.rg.name
  location                = azurerm_resource_group.rg.location
  subnet_id               = module.network1.subnet_id

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