terraform {
  required_providers {
    azurerm = {
      version = ">= 3.43"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  app                  = "arceus"
  name_suffix          = "${local.app}-${var.environment}-${var.location}"
  authorized_ip_ranges = ["77.169.37.43/32"]
}

# Create the resource group.
resource "azurerm_resource_group" "default" {
  name     = "rg-${local.name_suffix}"
  location = var.location
}

# Create the Log Analytics workspace.
resource "azurerm_log_analytics_workspace" "default" {
  name                = "log-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
  retention_in_days   = 30
}
