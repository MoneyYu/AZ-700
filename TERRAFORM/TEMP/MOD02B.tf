# LAB-02-B-VWAN
locals {
  lab02b_loc_01 = "japaneast"
  lab02b_loc_02 = "japanwest"
  lab02b_loc_03 = "eastasia"
  lab02b_vm_size = "Standard_D2s_v5"
}

resource "azurerm_virtual_network" "lab02b01" {
  name                = "${local.lab02b_name}-vnet01-jpe-${local.random_str}"
  address_space       = ["10.11.1.0/24"]
  location            = local.lab02b_loc_01
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab02b01" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab02b01.name
  address_prefixes     = ["10.11.1.0/27"]
}

resource "azurerm_virtual_network" "lab02b02" {
  name                = "${local.lab02b_name}-vnet02-jpw-${local.random_str}"
  address_space       = ["10.12.1.0/24"]
  location            = local.lab02b_loc_02
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab02b02" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab02b02.name
  address_prefixes     = ["10.12.1.0/27"]
}

resource "azurerm_virtual_network" "lab02b03" {
  name                = "${local.lab02b_name}-vnet03-ea-${local.random_str}"
  address_space       = ["10.13.1.0/24"]
  location            = local.lab02b_loc_03
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab02b03" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab02b03.name
  address_prefixes     = ["10.13.1.0/27"]
}

resource "azurerm_virtual_wan" "lab02b" {
  name                = "${local.lab02b_name}-vwan-${local.random_str}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_hub" "lab02b01" {
  name                = "${local.lab02b_name}-hub01-jpe-${local.random_str}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.lab02b_loc_01
  virtual_wan_id      = azurerm_virtual_wan.lab02b.id
  address_prefix      = "10.11.0.0/24"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_hub" "lab02b02" {
  name                = "${local.lab02b_name}-hub02-jpw-${local.random_str}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.lab02b_loc_02
  virtual_wan_id      = azurerm_virtual_wan.lab02b.id
  address_prefix      = "10.12.0.0/24"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_hub" "lab02b03" {
  name                = "${local.lab02b_name}-hub03-ea-${local.random_str}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.lab02b_loc_03
  virtual_wan_id      = azurerm_virtual_wan.lab02b.id
  address_prefix      = "10.13.0.0/24"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_hub_connection" "lab02b01" {
  name                      = "${local.lab02b_name}-vnet01-conn-jpe-${local.random_str}"
  virtual_hub_id            = azurerm_virtual_hub.lab02b01.id
  remote_virtual_network_id = azurerm_virtual_network.lab02b01.id
}

resource "azurerm_virtual_hub_connection" "lab02b02" {
  name                      = "${local.lab02b_name}-vnet02-conn-jpw-${local.random_str}"
  virtual_hub_id            = azurerm_virtual_hub.lab02b02.id
  remote_virtual_network_id = azurerm_virtual_network.lab02b02.id
}

resource "azurerm_virtual_hub_connection" "lab02b03" {
  name                      = "${local.lab02b_name}-vnet03-conn-ea-${local.random_str}"
  virtual_hub_id            = azurerm_virtual_hub.lab02b03.id
  remote_virtual_network_id = azurerm_virtual_network.lab02b03.id
}

resource "azurerm_network_security_group" "lab02b01" {
  name                = "${local.lab02b_name}-nsg01-jpe-${local.random_str}"
  location            = local.lab02b_loc_01
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab02b02" {
  name                = "${local.lab02b_name}-nsg02-jpw-${local.random_str}"
  location            = local.lab02b_loc_02
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab02b03" {
  name                = "${local.lab02b_name}-nsg03-ea-${local.random_str}"
  location            = local.lab02b_loc_03
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface" "lab02b01" {
  name                = "${local.lab02b_name}-nic01-jpe-${local.random_str}"
  location            = local.lab02b_loc_01
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab02b_name}-ipconfig-01-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02b01.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_network_security_group_association" "lab02b01" {
  subnet_id                 = azurerm_subnet.lab02b01.id
  network_security_group_id = azurerm_network_security_group.lab02b01.id
}

resource "azurerm_network_interface" "lab02b02" {
  name                = "${local.lab02b_name}-nic02-jpw-${local.random_str}"
  location            = local.lab02b_loc_02
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab02b_name}-ipconfig-02-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02b02.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_network_security_group_association" "lab02b02" {
  subnet_id                 = azurerm_subnet.lab02b02.id
  network_security_group_id = azurerm_network_security_group.lab02b02.id
}

resource "azurerm_network_interface" "lab02b03" {
  name                = "${local.lab02b_name}-nic03-ea-${local.random_str}"
  location            = local.lab02b_loc_03
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab02b_name}-ipconfig-03-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02b03.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_network_security_group_association" "lab02b03" {
  subnet_id                 = azurerm_subnet.lab02b03.id
  network_security_group_id = azurerm_network_security_group.lab02b03.id
}

resource "azurerm_windows_virtual_machine" "lab02b01" {
  name                  = "${local.lab02b_name}-vm01-${local.random_str}"
  location              = local.lab02b_loc_01
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab02b01.id]
  size                  = local.lab02b_vm_size

  os_disk {
    name                 = "${local.lab02b_name}-osdisk-01-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02b_name}-vm01-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02b01script" {
  name                       = "${local.lab02b_name}-script-01-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02b01.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_virtual_machine" "lab02b02" {
  name                  = "${local.lab02b_name}-vm02-${local.random_str}"
  location              = local.lab02b_loc_02
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab02b02.id]
  size                  = local.lab02b_vm_size

  os_disk {
    name                 = "${local.lab02b_name}-osdisk-02-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02b_name}-vm02-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02b02script" {
  name                       = "${local.lab02b_name}-script-02-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02b02.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_virtual_machine" "lab02b03" {
  name                  = "${local.lab02b_name}-vm03-${local.random_str}"
  location              = local.lab02b_loc_03
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab02b03.id]
  size                  = local.lab02b_vm_size

  os_disk {
    name                 = "${local.lab02b_name}-osdisk-03-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02b_name}-vm03-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02b03script" {
  name                       = "${local.lab02b_name}-script-03-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02b03.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_vpn_server_configuration" "lab02b01" {
  name                     = "${local.lab02b_name}-vpnsvr01-jpe-${local.random_str}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = local.lab02b_loc_01
  vpn_authentication_types = ["Certificate"]
  vpn_protocols            = ["IkeV2", "OpenVPN"]

  client_root_certificate {
    name             = "P2SRootCert"
    public_cert_data = <<EOF
MIIC6TCCAdGgAwIBAgIQXqUDrgdRmZVBz5E3J+jz1TANBgkqhkiG9w0BAQsFADAW
MRQwEgYDVQQDDAtQMlNSb290Q2VydDAgFw0yMTExMjgxMzUyMTdaGA8yMDk5MTIz
MDE2MDAwMFowFjEUMBIGA1UEAwwLUDJTUm9vdENlcnQwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDFZcgHM2zSyBYUWmi/N4y9BZeqIbLaVJXJbICAcCww
cgnR7LLtBe607mWCkOupTVlkg61Yf64bn5H0R7mkXAChA9vuk0NaHxvhkCsSQQoc
4GOfXjYXvuwHM8bGvT4Wk2sMLPCK03xj+RX6KskVqmjXesG0/4qCoQcY3JsgJGhL
QRCX4KD5hYopD0PU54SIQU5vxr7kb9+evx1pDpOI7tLdon02DGZ7J7yi8+3+qkFN
JlPdCPZNqvyNdKpIIWl4RKadfzrOirAzHtvvBN455eEbuH/qPGC8OiIYGeSTS04K
VPOYosKJDEXlnTmbo0ySUvRgqTmXJdpDkWKa8l5u6zodAgMBAAGjMTAvMA4GA1Ud
DwEB/wQEAwICBDAdBgNVHQ4EFgQUHdp6ZhvCBDsQQUIahU2dy0omt50wDQYJKoZI
hvcNAQELBQADggEBAMUh/0XrddTmI7VjJjSc01WVThx82r/IXVsNfl+ed13h3+Rp
1r3FELUTiozyYIUus70uiMf+qXDdPI3I7lPRMENoQNCxEyPhdD5awc12TBRP/c8W
QwqTA9lhoERvQ6oDQqZIGcARHFdq0qk1Ci/ZDDw1Oq70xSFhSZqMo2VDwKtuh2gT
pgEzE0JQpt9OOUI1EzLrx/nun6t/wxAXSyLev+0rt9dNr0MSD8DfqtFYiQWL5C44
nitvjgOQlGGE5LAR061qUaSwc3CMSOniaDjASGXVmF55lIEFeCg+yg/5Na7IVRCb
+ZNNQGtMCTBWZI7WJ9A8PwdhFw6412aBK9AKsvk=
EOF
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_point_to_site_vpn_gateway" "lab02b01" {
  name                        = "${local.lab02b_name}-p2s-vpngw01-jpe-${local.random_str}"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = local.lab02b_loc_01
  virtual_hub_id              = azurerm_virtual_hub.lab02b01.id
  vpn_server_configuration_id = azurerm_vpn_server_configuration.lab02b01.id
  scale_unit                  = 1
  connection_configuration {
    name = "${local.lab02b_name}-p2s-config01-jpe-${local.random_str}"

    vpn_client_address_pool {
      address_prefixes = [
        "10.11.2.0/24"
      ]
    }
  }

  tags = {
    environment = local.group_name
  }
}
