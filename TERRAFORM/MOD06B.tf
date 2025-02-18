## LAB-06-B-NSG
resource "azurerm_network_security_group" "lab06b" {
  name                = "${local.lab06b_name}-nsg-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Demo"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "123"
    destination_port_range     = "123"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = local.group_name
  }
}