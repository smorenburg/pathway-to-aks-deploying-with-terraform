# Create the cluster, including the default node pool.
resource "azurerm_kubernetes_cluster" "default" {
  name                 = "aks-${local.name_suffix}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.default.name
  node_resource_group  = "${azurerm_resource_group.default.name}-aks"
  dns_prefix           = "aks-${local.name_suffix}"
  azure_policy_enabled = true

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_D2_v5"
    vnet_subnet_id      = azurerm_subnet.aks.id
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 6

    upgrade_settings {
      max_surge = "25%"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  api_server_access_profile {
    authorized_ip_ranges = local.authorized_ip_ranges
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id
  }

  depends_on = [
    azurerm_role_assignment.subnet,
    azurerm_role_assignment.route_table
  ]
}

# Collect the diagnostic categories for the cluster.
data "azurerm_monitor_diagnostic_categories" "kubernetes_cluster" {
  resource_id = azurerm_kubernetes_cluster.default.id
}

#
locals {
  log_categories    = data.azurerm_monitor_diagnostic_categories.kubernetes_cluster.log_category_types
  metric_categories = data.azurerm_monitor_diagnostic_categories.kubernetes_cluster.metrics
}

# Create the default diagnostic settings, excluding the kube-audit logs.
resource "azurerm_monitor_diagnostic_setting" "default" {
  name                       = "default"
  target_resource_id         = azurerm_kubernetes_cluster.default.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.default.id

  dynamic "enabled_log" {
    for_each = { for category in local.log_categories : category => category if category != "kube-audit" }

    content {
      category = enabled_log.key
    }
  }

  dynamic "metric" {
    for_each = local.metric_categories

    content {
      category = metric.key
      enabled  = true
    }
  }
}

# Create the kube-audit diagnostic setting.
resource "azurerm_monitor_diagnostic_setting" "kube_audit" {
  name               = "kube-audit"
  target_resource_id = azurerm_kubernetes_cluster.default.id
  storage_account_id = azurerm_storage_account.kube_audit_logs.id

  enabled_log {
    category = "kube-audit"
  }

  dynamic "metric" {
    for_each = local.metric_categories

    content {
      category = metric.key
      enabled  = false
    }
  }
}
