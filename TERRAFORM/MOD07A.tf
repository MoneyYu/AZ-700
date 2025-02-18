## LAB-07-A-SERVICE-ENDPOINT
### https://blog.nillsf.com/index.php/2020/10/14/using-terraform-to-create-vnet-service-endpoints/
resource "azurerm_virtual_network" "lab07a" {
  name                = "${local.lab07a_name}-vnet-${local.random_str}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab07a-internal" {
  name                 = "internal-sub"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab07a.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_storage_account" "lab07a" {
  name                     = "${local.lab07a_name}stor${local.random_str}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.lab07a-internal.id]
  }

  tags = {
    environment = local.group_name
  }
}
