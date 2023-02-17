terraform {
  required_providers {
    azurerm = {
      version = ">= 3.43"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4"
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

# Generate a random suffix for the storage account.
resource "random_id" "suffix" {
  byte_length = 4
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

# Create the storage account for the kube-audit logs.
resource "azurerm_storage_account" "kube_audit_logs" {
  name                     = "st${local.app}${random_id.suffix.hex}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.default.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create the managed identity for the cluster.
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}
