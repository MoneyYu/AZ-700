## LAB-07-B-PRIVATE-LINK
### https://learn.microsoft.com/en-us/azure/app-service/scripts/terraform-secure-backend-frontend
### https://rollendxavier.medium.com/azure-private-links-secured-networking-between-azure-services-with-terraform-6d86b7d15f0e
resource "azurerm_virtual_network" "lab07b" {
  name                = "${local.lab07b_name}-vnet-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab07b-integration" {
  name                 = "integration-sub"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.lab07b.name
  address_prefixes     = ["10.0.1.0/24"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet" "lab07b-endpoint" {
  name                              = "endpoint-sub"
  resource_group_name               = azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.lab07b.name
  address_prefixes                  = ["10.0.2.0/24"]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_network_security_group" "lab07b" {
  name                = "${local.lab07b_name}-nsg-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_network_security_group_association" "lab07b-integration" {
  subnet_id                 = azurerm_subnet.lab07b-integration.id
  network_security_group_id = azurerm_network_security_group.lab07b.id
}

resource "azurerm_subnet_network_security_group_association" "lab07b-endpoint" {
  subnet_id                 = azurerm_subnet.lab07b-endpoint.id
  network_security_group_id = azurerm_network_security_group.lab07b.id
}

resource "azurerm_service_plan" "lab07b" {
  name                = "${local.lab07b_name}-app-plan-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "S1"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_web_app" "lab07b-frontend" {
  name                = "${local.lab07b_name}-app-frontend-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.lab07b.id

  site_config {
    vnet_route_all_enabled = true
  }

  app_settings = {
    "WEBSITE_DNS_SERVER" : "168.63.129.16",
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "lab07b-frontend" {
  app_service_id = azurerm_windows_web_app.lab07b-frontend.id
  subnet_id      = azurerm_subnet.lab07b-integration.id
}

resource "azurerm_windows_web_app" "lab07b-backend" {
  name                = "${local.lab07b_name}-app-backend-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.lab07b.id

  site_config {}

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_private_dns_zone" "lab07b" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "lab07b" {
  name                  = "dnszonelink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.lab07b.name
  virtual_network_id    = azurerm_virtual_network.lab07b.id
}

resource "azurerm_private_endpoint" "lab07b" {
  name                = "${local.lab07b_name}-private-endpoint-backend-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.lab07b-endpoint.id

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.lab07b.id]
  }

  private_service_connection {
    name                           = "privateendpointconnection"
    private_connection_resource_id = azurerm_windows_web_app.lab07b-backend.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  tags = {
    environment = local.group_name
  }
}
