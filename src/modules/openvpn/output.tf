output "openvpn_public_ip" {
  value = azurerm_public_ip.openvpn.ip_address
}

output "openvpn_private_ip" {
  value = azurerm_network_interface.openvpn.private_ip_address
}