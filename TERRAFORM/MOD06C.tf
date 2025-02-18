## LAB-06-C-BASTION
resource "azurerm_virtual_network" "lab06c" {
  name                = "${local.lab06c_name}-vnet-${local.random_str}"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab06c" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab06c.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "lab06cbastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab06c.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "lab06c" {
  subnet_id                 = azurerm_subnet.lab06c.id
  network_security_group_id = azurerm_network_security_group.lab06c.id
}

resource "azurerm_subnet_network_security_group_association" "lab06cbastion" {
  subnet_id                 = azurerm_subnet.lab06cbastion.id
  network_security_group_id = azurerm_network_security_group.lab06c.id
}

resource "azurerm_network_security_group" "lab06c" {
  name                = "${local.lab06c_name}-nsg-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "GatewayManager"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Internet-Bastion-PublicIP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OutboundVirtualNetwork"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "OutboundToAzureCloud"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_public_ip" "lab06c" {
  name                = "${local.lab06c_name}--bastion-pip-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_bastion_host" "lab06c" {
  name                   = "${local.lab06c_name}-bastion-${local.random_str}"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  sku                    = "Standard"
  file_copy_enabled      = true
  ip_connect_enabled     = true
  shareable_link_enabled = true
  tunneling_enabled      = true

  ip_configuration {
    name                 = "${local.lab06c_name}-bastion-ipconfig-${local.random_str}"
    subnet_id            = azurerm_subnet.lab06cbastion.id
    public_ip_address_id = azurerm_public_ip.lab06c.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface" "lab06c" {
  name                = "${local.lab06c_name}-nic-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab06c_name}-nic-ipconfig-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab06c.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_virtual_machine" "lab06c" {
  name                  = "${local.lab06c_name}-vm-${local.random_str}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab06c.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab06c_name}-osdisk-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab06c_name}-vm-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab06cscript" {
  name                       = "${local.lab06c_name}-script-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab06c.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}
