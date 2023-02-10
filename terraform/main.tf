terraform {
  required_providers {
    azurerm = {
      version = ">= 3.43"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  app            = "app"
  location       = "West Europe"
  location_lower = lower(replace(local.location, "/\\s+/", ""))
}

# Create the resource group for the application.
resource "azurerm_resource_group" "default" {
  name     = "rg-${var.environment}-app-${local.location_lower}"
  location = local.location
}
