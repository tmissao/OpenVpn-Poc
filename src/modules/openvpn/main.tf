resource "azurerm_linux_virtual_machine" "openvpn" {
  name = "server"
  admin_username = var.openvpnserver_vm_user
  location = var.vnet_location
  resource_group_name = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.openvpn.id]
  size = var.openvpnserver_vm_size
  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  os_disk {
    caching = "None"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username   = var.openvpnserver_vm_user
    public_key = file(var.openvpnserver_vm_user_ssh_path)
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "null_resource" "setup_server" {
  triggers = {
    variables = filebase64sha256("${path.module}/scripts/variables.sh")
    packages = filebase64sha256("${path.module}/scripts/packages.sh")
    bind9 = filebase64sha256("${path.module}/templates/bind9_conf.tpl")
    server = azurerm_linux_virtual_machine.openvpn.id
    vnet_address = var.vnet_address
    openvpn_address = var.openvpn_address
    azure_dns_service_ip = var.azure_dns_service_ip
  }
  connection {
    type     = "ssh"
    user     = var.openvpnserver_vm_user
    host     = azurerm_public_ip.openvpn.ip_address
    private_key = file(var.openvpnserver_vm_user_ssh_private_key_path)
  }
  provisioner "file" {
    source = "${path.module}/scripts/variables.sh"
    destination = "variables.sh"
  }
  provisioner "file" {
    source = "${path.module}/scripts/packages.sh"
    destination = "packages.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 700 packages.sh variables.sh",
      "./variables.sh",
      "./packages.sh",
    ]
  }
  provisioner "file" {
    content = local.bind9_conf
    destination = "/tmp/named.conf.options"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/named.conf.options /etc/bind/named.conf.options",
      "sudo systemctl enable named",
      "sudo systemctl restart bind9"
    ]
  }
  depends_on = [ azurerm_linux_virtual_machine.openvpn ]
}

resource "null_resource" "setup_openvpn_server_ca" {
  triggers = {
    ca = filebase64sha256("${path.module}/scripts/certificate_authority.sh")
    rsa_values = filebase64sha256("${path.module}/templates/rsa_vars.tpl")
    ca_values = join(";", values(var.openvpn_ca_values))
    server = azurerm_linux_virtual_machine.openvpn.id
    setupserver = null_resource.setup_server.id
  }
  connection {
    type     = "ssh"
    user     = var.openvpnserver_vm_user
    host     = azurerm_public_ip.openvpn.ip_address
    private_key = file(var.openvpnserver_vm_user_ssh_private_key_path)
  }
  provisioner "file" {
    content = local.rsa_vars
    destination = "/tmp/rsa_values"
  }
  provisioner "file" {
    source = "${path.module}/scripts/certificate_authority.sh"
    destination = "certificate_authority.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 700 certificate_authority.sh",
      "./certificate_authority.sh",
    ]
  }
  depends_on = [ azurerm_linux_virtual_machine.openvpn, null_resource.setup_server]
}

resource "null_resource" "setup_openvpn" {
  triggers = {
    baseconf = filebase64sha256("${path.module}/templates/openvpn_client.tpl")
    serverconf = filebase64sha256("${path.module}/templates/openvpn_server.tpl")
    iptables = filebase64sha256("${path.module}/templates/iptables_sh.tpl")
    openvpn = filebase64sha256("${path.module}/scripts/openvpn.sh")
    vpn_client = filebase64sha256("${path.module}/scripts/create_vpn_client.sh")
    openvpn_port = var.openvpn_port
    openvpn_protocol = var.openvpn_protocol
    openvpn_address = var.openvpn_address
    vnet_routes = join(";", [ for v in var.openvpn_routes: v.route ])
    private_dns_ip = azurerm_network_interface.openvpn.private_ip_address
    server = azurerm_linux_virtual_machine.openvpn.id
    setupserver = null_resource.setup_server.id
    casetup = null_resource.setup_openvpn_server_ca.id
  }
  connection {
    type     = "ssh"
    user     = var.openvpnserver_vm_user
    host     = azurerm_public_ip.openvpn.ip_address
    private_key = file(var.openvpnserver_vm_user_ssh_private_key_path)
  }
  provisioner "file" {
    content = local.openvpn_server_conf
    destination = "/tmp/server.conf"
  }
  provisioner "file" {
    content = local.openvpn_client_conf
    destination = "/tmp/base.conf"
  }
  provisioner "file" {
    source = "${path.module}/scripts/openvpn.sh"
    destination = "openvpn.sh"
  }
  provisioner "file" {
    source = "${path.module}/scripts/create_vpn_client.sh"
    destination = "/tmp/create_vpn_client.sh"
  }
  provisioner "file" {
    content = local.iptables_sh
    destination = "iptables_sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 700 openvpn.sh iptables_sh",
      "./openvpn.sh",
      "./iptables_sh"
    ]
  }
  depends_on = [ 
    azurerm_linux_virtual_machine.openvpn, 
    null_resource.setup_server,
    null_resource.setup_openvpn_server_ca
  ]
}