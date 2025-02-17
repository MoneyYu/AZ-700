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

  subnet {
    name           = "default"
    address_prefix = "172.17.0.0/24"
  }

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.lab06a.id
    enable = true
  }

  tags = {
    environment = local.group_name
  }
}
