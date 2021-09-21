output vnet_id {
  value = azurerm_virtual_network.vnet.id
}

output vnet_name {
  value = azurerm_virtual_network.vnet.name
}

output vnet_route {
  value =  {
    route = replace(var.vnet_address, "//\\d+/", "")
    mask = cidrnetmask(var.vnet_address) 
  }
}

output subnet_id {
  value = azurerm_subnet.subnet.id
}