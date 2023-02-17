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
  # Set the application name
  app = "arceus"

  # Contruct the name suffix.
  name_suffix = "${local.app}-${var.environment}-${var.location}"

  # Set the authorized IP ranges for the Kubernetes cluster.
  authorized_ip_ranges = ["77.169.37.43/32"]
}

# Generate a random suffix for the kube-audit logs storage account.
resource "random_id" "kube_audit_logs" {
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
  name                     = "st${local.app}${random_id.kube_audit_logs.hex}"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.default.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create the managed identity for the Kubernetes cluster.
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}
