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

data "azurerm_client_config" "current" {}

locals {
  # Set the application name
  app = "arceus"

  # Set the name suffix.
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
resource "azurerm_user_assigned_identity" "kubernetes_cluster" {
  name                = "id-aks-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}

# Create the managed identity for the disk encyption set.
resource "azurerm_user_assigned_identity" "disk_encryption_set" {
  name                = "id-des-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}

# Create the key vault.
resource "azurerm_key_vault" "default" {
  name                        = "kv-${local.name_suffix}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.default.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
}

# Create the key vault policy for the current user.
resource "azurerm_key_vault_access_policy" "default" {
  key_vault_id = azurerm_key_vault.default.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
    "WrapKey",
    "UnwrapKey"
  ]
}

# Create the key vault access policy for the disk encryption set managed identity.
resource "azurerm_key_vault_access_policy" "disk_encryption_set" {
  key_vault_id = azurerm_key_vault.default.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.disk_encryption_set.principal_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign",
    "WrapKey",
    "UnwrapKey"
  ]
}

# Create the key for the disk encryption set.
resource "azurerm_key_vault_key" "disk_encryption_set" {
  name         = "disk-encryption-set"
  key_vault_id = azurerm_key_vault.default.id
  key_type     = "RSA-HSM"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [
    azurerm_key_vault_access_policy.disk_encryption_set,
    azurerm_key_vault_access_policy.default
  ]
}

# Create the disk encryption set.
resource "azurerm_disk_encryption_set" "default" {
  name                = "des-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
  key_vault_key_id    = azurerm_key_vault_key.disk_encryption_set.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.disk_encryption_set.id]
  }

  depends_on = [azurerm_key_vault_access_policy.disk_encryption_set]
}
