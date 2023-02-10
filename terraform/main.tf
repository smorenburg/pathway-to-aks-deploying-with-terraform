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
  name_suffix    = "${var.environment}-${local.app}-${local.location_lower}"
}

# Create the resource group for the application.
resource "azurerm_resource_group" "default" {
  name     = "rg-${local.name_suffix}"
  location = local.location
}
