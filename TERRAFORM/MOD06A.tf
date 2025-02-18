## LAB-06-A-DDOS
resource "azurerm_network_ddos_protection_plan" "lab06a" {
  name                = "${local.lab06a_name}-ddos-plan-${local.random_str}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_network" "lab06a" {
  name                = "${local.lab06a_name}-vnet-${local.random_str}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["172.17.0.0/16"]

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.lab06a.id
    enable = true
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab06a" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab06a.name
  address_prefixes     = ["172.17.0.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "lab06a" {
  subnet_id                 = azurerm_subnet.lab06a.id
  network_security_group_id = azurerm_network_security_group.lab06a.id
}

resource "azurerm_network_security_group" "lab06a" {
  name                = "${local.lab06a_name}-nsg-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab06a" {
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
  network_security_group_name = azurerm_network_security_group.lab06a.name
}
