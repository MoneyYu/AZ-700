## LAB-01-VNET
resource "azurerm_virtual_network" "lab01" {
  name                = "${local.lab01_name}-vnet-${local.random_str}"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

## LAB-01-DNS
resource "azurerm_dns_zone" "lab01" {
  name                = "${local.lab01_name}-public-dns-${local.random_str}.com"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_private_dns_zone" "lab01" {
  name                = "${local.lab01_name}-private-dns-${local.random_str}.local"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "lab01" {
  name                  = "${local.lab01_name}-zone-link-${local.random_str}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.lab01.name
  virtual_network_id    = azurerm_virtual_network.lab01.id
  registration_enabled  = true

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab01" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab01.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_interface" "lab01" {
  name                = "${local.lab01_name}-nic-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_servers         = ["8.8.8.8", "8.8.4.4"]

  ip_configuration {
    name                          = "${local.lab01_name}-nic-ipconfig-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab01.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_virtual_machine" "lab01" {
  name                  = "${local.lab01_name}-vm-${local.random_str}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab01.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab01_name}-osdisk-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab01_name}-vm-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab01script" {
  name                       = "${local.lab01_name}-vm-script-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab01.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

## LAB-01-ROUTE-TABLE
resource "azurerm_route_table" "lab01" {
  name                = "${local.lab01_name}-routes-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name           = "${local.lab01_name}-route-${local.random_str}"
    address_prefix = "10.0.0.0/16"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    environment = local.group_name
  }
}