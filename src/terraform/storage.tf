data "azurerm_client_config" "current" {}

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

resource "azurerm_role_assignment" "openvpn" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_virtual_machine.openvpn.identity.0.principal_id
}

resource "azurerm_role_assignment" "vm" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_virtual_machine.vm.identity.0.principal_id
}