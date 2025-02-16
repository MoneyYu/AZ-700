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

## LAB-05-A-PEERING
resource "azurerm_virtual_network" "lab01a01" {
  name                = "${local.lab01a_name}-vnet-01-${local.random_str}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab01a01" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab01a01.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "lab01a01" {
  name                = "${local.lab01a_name}-pip-01-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${local.lab01a_name}-pip-01-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab01a01" {
  name                = "${local.lab01a_name}-nsg-01-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab01a01" {
  name                        = "RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.lab01a01.name
}

resource "azurerm_network_interface" "lab01a01" {
  name                = "${local.lab01a_name}-nic-01-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab01a_name}-ipconfig-01-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab01a01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab01a01.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_network_security_group_association" "lab01a01" {
  subnet_id                 = azurerm_subnet.lab01a01.id
  network_security_group_id = azurerm_network_security_group.lab01a01.id
}

resource "azurerm_windows_virtual_machine" "lab01a01" {
  name                  = "${local.lab01a_name}-vm01-${local.random_str}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab01a01.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab01a_name}-osdisk-01-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab01a_name}-vm01-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab01a01script" {
  name                       = "${local.lab01a_name}-script-01-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab01a01.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_network" "lab01a02" {
  name                = "${local.lab01a_name}-vnet-02-${local.random_str}"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab01a02" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab01a02.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_public_ip" "lab01a02" {
  name                = "${local.lab01a_name}-pip-02-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${local.lab01a_name}-pip-02-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab01a02" {
  name                = "${local.lab01a_name}-nsg-02-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab01a02" {
  name                        = "RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.lab01a02.name
}

resource "azurerm_network_interface" "lab01a02" {
  name                = "${local.lab01a_name}-nic-02-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab01a_name}-ipconfig-02-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab01a02.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab01a02.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_network_security_group_association" "lab01a02" {
  subnet_id                 = azurerm_subnet.lab01a02.id
  network_security_group_id = azurerm_network_security_group.lab01a02.id
}

resource "azurerm_windows_virtual_machine" "lab01a02" {
  name                  = "${local.lab01a_name}-vm02-${local.random_str}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab01a02.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab01a_name}-osdisk-02-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab01a_name}-vm02-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab01a02script" {
  name                       = "${local.lab01a_name}-script-02-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab01a02.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_network" "lab01a03" {
  name                = "${local.lab01a_name}-vnet-03-${local.random_str}"
  address_space       = ["10.3.0.0/16"]
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab01a03" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab01a03.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_public_ip" "lab01a03" {
  name                = "${local.lab01a_name}-pip-03-${local.random_str}"
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${local.lab01a_name}-pip-03-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab01a03" {
  name                = "${local.lab01a_name}-nsg-03-${local.random_str}"
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab01a03" {
  name                        = "RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.lab01a03.name
}

resource "azurerm_network_interface" "lab01a03" {
  name                = "${local.lab01a_name}-nic-03-${local.random_str}"
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab01a_name}-ipconfig-03-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab01a03.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab01a03.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_network_security_group_association" "lab01a03" {
  subnet_id                 = azurerm_subnet.lab01a03.id
  network_security_group_id = azurerm_network_security_group.lab01a03.id
}

resource "azurerm_windows_virtual_machine" "lab01a03" {
  name                  = "${local.lab01a_name}-vm03-${local.random_str}"
  location              = "eastasia"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab01a03.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab01a_name}-osdisk-03-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab01a_name}-vm03-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab01a03script" {
  name                       = "${local.lab01a_name}-script-03-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab01a03.id

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

## LAB-01-NAT
resource "azurerm_subnet" "lab01b" {
  name                 = "nat-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab01.name
  address_prefixes     = ["10.10.2.0/24"]
}

# Public IP address for NAT gateway
resource "azurerm_public_ip" "lab01bnat" {
  name                = "${local.lab01b_name}-nat-pip-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NAT Gateway
resource "azurerm_nat_gateway" "lab01b" {
  name                = "${local.lab01b_name}-nat-gw-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Associate NAT Gateway with Public IP
resource "azurerm_nat_gateway_public_ip_association" "lab01bnat" {
  nat_gateway_id       = azurerm_nat_gateway.lab01b.id
  public_ip_address_id = azurerm_public_ip.lab01bnat.id
}

# Associate NAT Gateway with Subnet
resource "azurerm_subnet_nat_gateway_association" "lab01b" {
  subnet_id      = azurerm_subnet.lab01b.id
  nat_gateway_id = azurerm_nat_gateway.lab01b.id
}

# Create public IP for virtual machine
resource "azurerm_public_ip" "lab01bvm" {
  name                = "${local.lab01b_name}-nat-vm-pip-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "lab01b" {
  name                = "${local.lab01b_name}-nat-nsg-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = chomp(data.http.myip.response_body)
    destination_port_range     = "3389"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "lab01b" {
  name                = "${local.lab01b_name}-nat-vm-nic-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.lab01b_name}-nat-vm-config-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab01b.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab01bvm.id
  }

  tags = {
    environment = local.group_name
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "lab01b" {
  network_interface_id      = azurerm_network_interface.lab01b.id
  network_security_group_id = azurerm_network_security_group.lab01b.id
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "lab01b" {
  name                  = "${local.lab01b_name}-nat-vm-${local.random_str}"
  location              = "eastasia"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.lab01b.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab01b_name}-osdisk-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab01b_name}-vm-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab01bscript" {
  name                       = "${local.lab01b_name}-script-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab01b.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}
