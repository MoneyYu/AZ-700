## LAB-04-A-LOAD-BALANCER
resource "azurerm_virtual_network" "lab04a" {
  name                = "${local.lab04a_name}-vnet-${local.random_str}"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab04a" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab04a.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_public_ip" "lab04a" {
  name                = "${local.lab04a_name}-lb-pip-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.lab04a_name}-lb-pip-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_lb" "lab04a" {
  name                = "${local.lab04a_name}-lb-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lab04a.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_lb_backend_address_pool" "lab04a" {
  loadbalancer_id = azurerm_lb.lab04a.id
  name            = "BackendPool"
}

resource "azurerm_lb_probe" "lab04a" {
  loadbalancer_id     = azurerm_lb.lab04a.id
  name                = "probe"
  port                = 80
  interval_in_seconds = 5
}

resource "azurerm_lb_rule" "lab04a" {
  loadbalancer_id                = azurerm_lb.lab04a.id
  name                           = "rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lab04a.id]
  probe_id                       = azurerm_lb_probe.lab04a.id
  disable_outbound_snat          = true
}

resource "azurerm_network_security_group" "lab04a" {
  name                = "${local.lab04a_name}-nsg-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab04a" {
  name                        = "HTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "80"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.lab04a.name
}

resource "azurerm_network_interface" "lab04a01" {
  name                = "${local.lab04a_name}-nic-01-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab04a_name}-nic-ipconfig-01-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab04a.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_network_security_group_association" "lab04a" {
  subnet_id                 = azurerm_subnet.lab04a.id
  network_security_group_id = azurerm_network_security_group.lab04a.id
}

resource "azurerm_network_interface_backend_address_pool_association" "lab04a01" {
  network_interface_id    = azurerm_network_interface.lab04a01.id
  ip_configuration_name   = "${local.lab04a_name}-nic-ipconfig-01-${local.random_str}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lab04a.id
}

resource "azurerm_windows_virtual_machine" "lab04a01" {
  name                  = "${local.lab04a_name}-vm01-${local.random_str}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab04a01.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab04a_name}-osdisk-01-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab04a_name}-vm01-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab04a01script" {
  name                       = "${local.lab04a_name}-script-01-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab04a01.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface" "lab04a02" {
  name                = "${local.lab04a_name}-nic-02-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab04a_name}-nic-ipconfig-02-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab04a.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "lab04a02" {
  network_interface_id    = azurerm_network_interface.lab04a02.id
  ip_configuration_name   = "${local.lab04a_name}-nic-ipconfig-02-${local.random_str}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lab04a.id
}

resource "azurerm_windows_virtual_machine" "lab04a02" {
  name                  = "${local.lab04a_name}-vm02-${local.random_str}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab04a02.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab04a_name}-osdisk-02-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab04a_name}-vm02-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab04a02script" {
  name                       = "${local.lab04a_name}-script-02-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab04a02.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}
