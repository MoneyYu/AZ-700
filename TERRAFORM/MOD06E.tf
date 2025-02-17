## LAB-06-E-FIREWALL-Manager
resource "azurerm_virtual_wan" "lab06e" {
  name                           = "${local.lab06e_name}-vwan-${local.random_str}"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  allow_branch_to_branch_traffic = true
  disable_vpn_encryption         = false

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_hub" "lab06e" {
  name                = "${local.lab06e_name}-vwan-hub-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_wan_id      = azurerm_virtual_wan.lab06e.id
  address_prefix      = "10.20.0.0/23"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_hub_connection" "lab06e" {
  name                      = "${local.lab06e_name}-hub-conn-${local.random_str}"
  virtual_hub_id            = azurerm_virtual_hub.lab06e.id
  remote_virtual_network_id = azurerm_virtual_network.lab06e.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.lab06e.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.lab06e.id]
      labels          = ["VNet"]
    }
  }
}

resource "azurerm_public_ip" "lab06e" {
  name                = "${local.lab06e_name}-hub-pip-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_firewall_policy" "lab06e" {
  name                     = "${local.lab06e_name}-fw-policy-${local.random_str}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Premium"
  threat_intelligence_mode = "Alert"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "lab06e" {
  name               = "${local.lab06e_name}-fw-policy-rule-col-${local.random_str}"
  firewall_policy_id = azurerm_firewall_policy.lab06e.id
  priority           = 300
  application_rule_collection {
    name     = "DefaultApplicationRuleCollection"
    action   = "Allow"
    priority = 100
    rule {
      name        = "Allow-MSFT"
      description = "Allow access to Microsoft.com"
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      destination_fqdns = ["*.microsoft.com"]
      terminate_tls     = false
      source_addresses  = ["*"]
    }
  }
}

resource "azurerm_firewall" "lab06e" {
  name                = "${local.lab06e_name}-fw-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_Hub"
  sku_tier            = "Premium"

  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.lab06e.id
    public_ip_count = 1
  }

  firewall_policy_id = azurerm_firewall_policy.lab06e.id

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_network" "lab06e" {
  name                = "${local.lab06e_name}-vnet-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab06eworkload" {
  name                 = "subnet-workload"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab06e.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "lab06ejump" {
  name                 = "subnet-jump"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab06e.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_network_interface" "lab06eworkload" {
  name                = "${local.lab06e_name}-nic-workload-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-workload"
    subnet_id                     = azurerm_subnet.lab06eworkload.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_public_ip" "lab06ejump" {
  name                = "${local.lab06e_name}-pip-jump-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface" "lab06ejump" {
  name                = "${local.lab06e_name}-nic-jump-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-jump"
    subnet_id                     = azurerm_subnet.lab06ejump.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab06ejump.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab06eworkload" {
  name                = "${local.lab06e_name}-nsg-workload-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab06ejump" {
  name                = "${local.lab06e_name}-nsg-jump-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface_security_group_association" "lab06eworkload" {
  network_interface_id      = azurerm_network_interface.lab06eworkload.id
  network_security_group_id = azurerm_network_security_group.lab06eworkload.id
}

resource "azurerm_network_interface_security_group_association" "lab06ejump" {
  network_interface_id      = azurerm_network_interface.lab06ejump.id
  network_security_group_id = azurerm_network_security_group.lab06ejump.id
}

resource "azurerm_windows_virtual_machine" "lab06eworkload" {
  name                  = "${local.lab06e_name}-vm-workload-${local.random_str}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = local.vm_size
  admin_username        = local.user_name
  admin_password        = local.user_passowrd
  network_interface_ids = [azurerm_network_interface.lab06eworkload.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"

  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_virtual_machine" "lab06ejump" {
  name                  = "${local.lab06e_name}-vm-jump-${local.random_str}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = local.vm_size
  admin_username        = local.user_name
  admin_password        = local.user_passowrd
  network_interface_ids = [azurerm_network_interface.lab06ejump.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_route_table" "lab06e" {
  name                          = "${local.lab06e_name}-rt-table-${local.random_str}"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = true

  route {
    name           = "jump-to-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_route_table_association" "lab06ejump" {
  subnet_id      = azurerm_subnet.lab06ejump.id
  route_table_id = azurerm_route_table.lab06e.id
}

resource "azurerm_virtual_hub_route_table" "lab06e" {
  name           = "${local.lab06e_name}-hub-rt-table-${local.random_str}"
  virtual_hub_id = azurerm_virtual_hub.lab06e.id

  route {
    name              = "workload-SNToFirewall"
    destinations_type = "CIDR"
    destinations      = ["10.10.1.0/24"]
    next_hop_type     = "ResourceId"
    next_hop          = azurerm_firewall.lab06e.id
  }
  
  route {
    name              = "InternetToFirewall"
    destinations_type = "CIDR"
    destinations      = ["0.0.0.0/0"]
    next_hop_type     = "ResourceId"
    next_hop          = azurerm_firewall.lab06e.id
  }

  labels = ["VNet"]
}
