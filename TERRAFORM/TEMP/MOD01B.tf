## LAB-01-B-NAT
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

  tags = {
    environment = local.group_name
  }
}

# NAT Gateway
resource "azurerm_nat_gateway" "lab01b" {
  name                = "${local.lab01b_name}-nat-gw-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
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

  tags = {
    environment = local.group_name
  }
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

  tags = {
    environment = local.group_name
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

  # depends_on = [
  #   azurerm_network_interface.lab01b
  # ]

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
