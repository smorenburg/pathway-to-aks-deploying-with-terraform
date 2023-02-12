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
  name_suffix    = "${local.app}-${var.environment}-${var.location}"
}

# Create the resource group..
resource "azurerm_resource_group" "default" {
  name     = "rg-${local.name_suffix}"
  location = var.location
}
