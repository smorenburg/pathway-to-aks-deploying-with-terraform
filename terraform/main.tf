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
  location      = "West Europe"
  location_name = lower(replace(local.location, "/\\s+/", ""))
}

resource "azurerm_resource_group" "aks" {
  name     = "rg-${var.environment}-aks-${local.location_name}"
  location = local.location
}
