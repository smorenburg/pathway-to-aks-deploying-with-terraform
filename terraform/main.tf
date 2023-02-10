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
  name_suffix    = "${var.environment}-${local.app}-${var.location}"
}

# Create the resource group for the application.
resource "azurerm_resource_group" "default" {
  name     = "rg-${local.name_suffix}"
  location = var.location
}
