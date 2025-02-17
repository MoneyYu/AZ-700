terraform {
  required_version = ">=1.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.9.1"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "group_postfix" {
  type = string
}

variable "user_name" {
  type    = string
  default = "demouser"
}

variable "user_passowrd" {
  type    = string
  default = "Azuredemo2020"
}

locals {
  group_name    = "AZ700-${var.group_postfix}"
  location      = "japaneast"
  random_str    = "gsd"
  vm_size       = "Standard_B4ms"
  lab01_name    = "lab01"
  lab01a_name   = "lab01a"
  lab01b_name   = "lab01b"
  lab01c_name   = "lab01c"
  lab01d_name   = "lab01d"
  lab02_name    = "lab02"
  lab02a_name   = "lab02a"
  lab02b_name   = "lab02b"
  lab03_name    = "lab03"
  lab04_name    = "lab04"
  lab04a_name    = "lab04a"
  lab04b_name    = "lab04b"
  lab05a_name   = "lab05a"
  lab05b_name   = "lab05b"
  lab06a_name   = "lab06a"
  lab06b_name   = "lab06b"
  lab06c_name   = "lab06c"
  lab06d_name   = "lab06d"
  lab06e_name   = "lab06e"
  lab07_name    = "lab07"
  lab08_name    = "lab08"
  lab09a_name   = "lab09a"
  lab09b_name   = "lab09b"
  lab09c_name   = "lab09c"
  lab09d_name   = "lab09d"
  lab10_name    = "lab10"
  lab11_name    = "lab11"
  user_name     = "demouser"
  user_passowrd = "Azuredemo2020"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_client_config" "current" {}

resource "random_string" "rid" {
  length  = 3
  special = false
  numeric = false
  upper   = false
}

resource "random_integer" "rint" {
  min = 100
  max = 999
}

resource "random_pet" "petname" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    ami_id = var.group_postfix
  }
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "rg" {
  name     = local.group_name
  location = local.location

  tags = {
    environment = local.group_name
  }
}
