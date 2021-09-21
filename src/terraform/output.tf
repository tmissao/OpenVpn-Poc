output "openvpn" {
  value = module.openvpn
}

output "storage_account_endpoind" {
  value = azurerm_private_dns_a_record.storage.fqdn
}

output "vnet_route" {
  value = [module.network1.vnet_route, module.network2.vnet_route]
}