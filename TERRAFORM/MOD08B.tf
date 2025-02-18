## LAB-08-B-NETWORK-WATCHER
### https://learn.microsoft.com/en-us/azure/developer/terraform/create-network-watcher-nsg-flow-logs
### https://learn.microsoft.com/en-us/azure/network-watcher/nsg-flow-logs-overview

locals {
  lab08b-location = "southeastasia"
}

# Networking components to be monitored
resource "azurerm_network_security_group" "lab08b" {
  name                = "${local.lab08b_name}-nsg-${local.random_str}"
  location            = local.lab08b-location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Demo"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Log collection components
resource "azurerm_storage_account" "lab08b" {
  name                = "${local.lab08b_name}stor${local.random_str}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.lab08b-location

  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_log_analytics_workspace" "lab08b" {
  name                = "${local.lab08b_name}-log-${local.random_str}"
  location            = local.lab08b-location
  resource_group_name = azurerm_resource_group.rg.name
  retention_in_days   = 90
  daily_quota_gb      = 5
}

# The Network Watcher Instance & network log flow
# There can only be one Network Watcher per subscription and region
resource "azurerm_network_watcher" "lab08b" {
  name                = "${local.lab08b_name}-net-watcher-${local.random_str}"
  location            = local.lab08b-location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_watcher_flow_log" "lab08b" {
  name                 = "${local.lab08b_name}-example-log-${local.random_str}"
  network_watcher_name = azurerm_network_watcher.lab08b.name
  resource_group_name  = azurerm_resource_group.rg.name

  network_security_group_id = azurerm_network_security_group.lab08b.id
  storage_account_id = azurerm_storage_account.lab08b.id
  enabled            = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.lab08b.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.lab08b.location
    workspace_resource_id = azurerm_log_analytics_workspace.lab08b.id
    interval_in_minutes   = 10
  }
}
