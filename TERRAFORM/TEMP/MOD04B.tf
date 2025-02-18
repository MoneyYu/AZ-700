## LAB-04-B-TRAFFIC-MANAGER
resource "azurerm_traffic_manager_profile" "lab04b" {
  name                   = "${local.lab04b_name}-tfm-${local.random_str}"
  resource_group_name    = azurerm_resource_group.rg.name
  traffic_routing_method = "Priority"
  dns_config {
    relative_name = "${local.lab04b_name}-tfm-${local.random_str}"
    ttl           = 10
  }

  monitor_config {
    protocol                    = "HTTPS"
    port                        = 443
    path                        = "/"
    expected_status_code_ranges = ["200-202", "301-302"]
    interval_in_seconds = 10
    timeout_in_seconds  = 5
    tolerated_number_of_failures = 0
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "lab04b01" {
  name                 = "${local.lab04b_name}-tfm-endpoint-01-${local.random_str}"
  profile_id           = azurerm_traffic_manager_profile.lab04b.id
  always_serve_enabled = true
  weight               = 100
  target_resource_id   = azurerm_windows_web_app.lab04b01.id
}

resource "azurerm_traffic_manager_azure_endpoint" "lab04b02" {
  name                 = "${local.lab04b_name}-tfm-endpoint-02-${local.random_str}"
  profile_id           = azurerm_traffic_manager_profile.lab04b.id
  always_serve_enabled = true
  weight               = 100
  target_resource_id   = azurerm_windows_web_app.lab04b02.id
}

resource "azurerm_service_plan" "lab04b01" {
  name                = "${local.lab04b_name}-app-plan-01-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "S1"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_web_app" "lab04b01" {
  name                = "${local.lab04b_name}-app-01-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.lab04b01.id

  site_config {
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
  }

  app_settings = {
    "WEBSITE_TIME_ZONE" = "Taipei Standard Time"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_service_plan" "lab04b02" {
  name                = "${local.lab04b_name}-app-plan-02-${local.random_str}"
  location            = "East Asia"
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "S1"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_web_app" "lab04b02" {
  name                = "${local.lab04b_name}-app-02-${local.random_str}"
  location            = "East Asia"
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.lab04b02.id

  site_config {
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
  }

  app_settings = {
    "WEBSITE_TIME_ZONE" = "Taipei Standard Time"
  }

  tags = {
    environment = local.group_name
  }
}
