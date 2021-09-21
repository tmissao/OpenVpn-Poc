resource "azurerm_resource_group" "rg" {
  name = var.project_name
  location = var.location
}

resource "azurerm_private_dns_zone" "dns" {
  name                = var.private_dns_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = var.vnet_name
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_link2" {
  name                  = var.vnet2_name
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dns.name
  virtual_network_id    = azurerm_virtual_network.vnet2.id
  registration_enabled = true
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = file("${path.module}/scripts/init.cfg")
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/setup.sh", {
      USER = var.openvpnserver_vm_user
      OPENVPN_ADDRESS = var.openvpn_address
      OPENVPN_PROTOCOL = var.openvpn_protocol
      OPENVPN_PORT = var.openvpn_port
      RSA_CA_VALUES = base64encode(templatefile("${path.module}/templates/rsa_vars.tpl", {
        CA_COUNTRY = "BR"
        CA_PROVINCE = "SP"
        CA_CITY = "Sao Paulo"
        CA_ORGANIZATION = "Acqio"
        CA_EMAIL = "contato@esfera5.com.br"
      }))
      OPENVPN_SERVER_CONF_VALUES = base64encode(templatefile("${path.module}/templates/openvpn_server.tpl", {
        OPENVPN_PORT = var.openvpn_port
        OPENVPN_PROTOCOL = var.openvpn_protocol
        OPENVPN_ADDRESS = replace(var.openvpn_address, "//\\d+/", "")
        OPENVPN_ADDRESS_MASK = cidrnetmask(var.openvpn_address)
        VNET_ROUTES = {
          replace(var.vnet_address, "//\\d+/", "") = cidrnetmask(var.vnet_address)
          replace(var.vnet2_address, "//\\d+/", "") = cidrnetmask(var.vnet2_address)
        }
        PRIVATE_DNS_IP = azurerm_network_interface.openvpn.private_ip_address
      }))
      OPENVPN_CLIENT_CONF_VALUES = base64encode(templatefile("${path.module}/templates/openvpn_client.tpl", {
        OPENVPN_SERVER = azurerm_public_ip.openvpn.ip_address
        OPENVPN_PORT = var.openvpn_port
        OPENVPN_PROTOCOL = var.openvpn_protocol
      }))
      BIND9_VALUES = base64encode(templatefile("${path.module}/templates/bind9_conf.tpl", {
        VNET_ADDRESS = var.vnet_address
        OPENVPN_ADDRESS = var.openvpn_address
        AZURE_PRIVATE_DNS_IP = var.azure_dns_service_ip
      }))
    })
  }
}

resource "azurerm_linux_virtual_machine" "openvpn" {
  name = "server"
  admin_username = var.openvpnserver_vm_user
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
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
    content = templatefile("${path.module}/templates/bind9_conf.tpl", {
        VNET_ADDRESS = var.vnet_address
        OPENVPN_ADDRESS = var.openvpn_address
        AZURE_PRIVATE_DNS_IP = var.azure_dns_service_ip
      })
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
  }
  connection {
    type     = "ssh"
    user     = var.openvpnserver_vm_user
    host     = azurerm_public_ip.openvpn.ip_address
    private_key = file(var.openvpnserver_vm_user_ssh_private_key_path)
  }
  provisioner "file" {
    content = templatefile("${path.module}/templates/rsa_vars.tpl", {
        CA_COUNTRY = var.openvpn_ca_values.country
        CA_PROVINCE = var.openvpn_ca_values.province
        CA_CITY = var.openvpn_ca_values.city
        CA_ORGANIZATION = var.openvpn_ca_values.organization
        CA_EMAIL = var.openvpn_ca_values.email
      })
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
    vnet_routes = join(";", [var.vnet_address, var.vnet2_address])
    private_dns_ip = azurerm_network_interface.openvpn.private_ip_address
    server = azurerm_linux_virtual_machine.openvpn.id
  }
  connection {
    type     = "ssh"
    user     = var.openvpnserver_vm_user
    host     = azurerm_public_ip.openvpn.ip_address
    private_key = file(var.openvpnserver_vm_user_ssh_private_key_path)
  }
  provisioner "file" {
    content = templatefile("${path.module}/templates/openvpn_server.tpl", {
      OPENVPN_PORT = var.openvpn_port
      OPENVPN_PROTOCOL = var.openvpn_protocol
      OPENVPN_ADDRESS = replace(var.openvpn_address, "//\\d+/", "")
      OPENVPN_ADDRESS_MASK = cidrnetmask(var.openvpn_address)
      VNET_ROUTES = {
        replace(var.vnet_address, "//\\d+/", "") = cidrnetmask(var.vnet_address)
        replace(var.vnet2_address, "//\\d+/", "") = cidrnetmask(var.vnet2_address)
      }
      PRIVATE_DNS_IP = azurerm_network_interface.openvpn.private_ip_address
    })
    destination = "/tmp/server.conf"
  }
  provisioner "file" {
    content = templatefile("${path.module}/templates/openvpn_client.tpl", {
        OPENVPN_SERVER = azurerm_public_ip.openvpn.ip_address
        OPENVPN_PORT = var.openvpn_port
        OPENVPN_PROTOCOL = var.openvpn_protocol
    })
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
    content = templatefile("${path.module}/templates/iptables_sh.tpl", {
        OPENVPN_SERVER = azurerm_public_ip.openvpn.ip_address
        OPENVPN_PORT = var.openvpn_port
        OPENVPN_PROTOCOL = var.openvpn_protocol
        OPENVPN_ADDRESS = var.openvpn_address
        IP = azurerm_network_interface.openvpn.private_ip_address
    })
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
    azurerm_linux_virtual_machine.openvpn, null_resource.setup_server,
    null_resource.setup_openvpn_server_ca
  ]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "vm"
  admin_username = var.openvpnserver_vm_user
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm.id]
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