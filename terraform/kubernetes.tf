# Collect the diagnostic categories.
data "azurerm_monitor_diagnostic_categories" "kubernetes_cluster" {
  resource_id = azurerm_kubernetes_cluster.default.id
}

locals {
  # Set the log categories, excluding the kube-audit logs.
  kubernetes_cluster_log_categories = toset([
    for type in data.azurerm_monitor_diagnostic_categories.kubernetes_cluster.log_category_types : type
    if type != "kube-audit"
  ])

  # Set the metric categories.
  kubernetes_cluster_metric_categories = data.azurerm_monitor_diagnostic_categories.kubernetes_cluster.metrics
}

# Create the Kubernetes cluster, including the default node pool.
resource "azurerm_kubernetes_cluster" "default" {
  name                   = "aks-${local.suffix}"
  location               = var.location
  resource_group_name    = azurerm_resource_group.default.name
  node_resource_group    = "${azurerm_resource_group.default.name}-aks"
  dns_prefix             = "aks-${local.suffix}"
  sku_tier               = var.kubernetes_cluster_sku_tier
  azure_policy_enabled   = true
  disk_encryption_set_id = azurerm_disk_encryption_set.default.id

  default_node_pool {
    name                = "default"
    vm_size             = var.kubernetes_cluster_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 9

    upgrade_settings {
      max_surge = "25%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.kubernetes_cluster.id]
  }

  api_server_access_profile {
    authorized_ip_ranges = local.authorized_ip_ranges
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id
  }

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id
  }

  depends_on = [
    azurerm_role_assignment.subnet,
    azurerm_role_assignment.route_table
  ]
}

# Create the default diagnostic setting, excluding the kube-audit logs.
resource "azurerm_monitor_diagnostic_setting" "kubernetes_cluster_default" {
  name                           = "default"
  target_resource_id             = azurerm_kubernetes_cluster.default.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.default.id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = local.kubernetes_cluster_log_categories

    content {
      category = enabled_log.key
    }
  }

  dynamic "metric" {
    for_each = local.kubernetes_cluster_metric_categories

    content {
      category = metric.key
      enabled  = false
    }
  }
}

# Create the kube-audit diagnostic setting.
resource "azurerm_monitor_diagnostic_setting" "kubernetes_cluster_kube_audit" {
  name               = "kube-audit"
  target_resource_id = azurerm_kubernetes_cluster.default.id
  storage_account_id = azurerm_storage_account.logs.id

  enabled_log {
    category = "kube-audit"

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  dynamic "metric" {
    for_each = local.kubernetes_cluster_metric_categories

    content {
      category = metric.key
      enabled  = false
    }
  }
}
