## LAB-05-B-FRONT-DOOR
resource "azurerm_cdn_frontdoor_profile" "lab05b" {
  name                = "${local.lab05b_name}-fd-profile-${local.random_str}"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Premium_AzureFrontDoor"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "lab05b" {
  name                     = "${local.lab05b_name}-fd-endpoint-${local.random_str}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.lab05b.id

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "lab05b" {
  name                     = "${local.lab05b_name}-fd-origin-group-${local.random_str}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.lab05b.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "lab05b" {
  name                          = "${local.lab05b_name}-fd-origin-${local.random_str}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.lab05b.id

  enabled                        = true
  host_name                      = azurerm_windows_web_app.lab05b.default_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_windows_web_app.lab05b.default_hostname
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "lab05b" {
  name                          = "${local.lab05b_name}-fd-route-${local.random_str}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.lab05b.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.lab05b.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.lab05b.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
}

resource "azurerm_service_plan" "lab05b" {
  name                = "${local.lab05b_name}-app-plan-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "S1"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_web_app" "lab05b" {
  name                = "${local.lab05b_name}-app-${local.random_str}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.lab05b.id

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
