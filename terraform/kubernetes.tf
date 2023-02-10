# Create the Kubernetes cluster, including the default node pool.
resource "azurerm_kubernetes_cluster" "default" {
  name                 = "aks-${var.environment}-${local.app}-${local.location_lower}"
  location             = local.location
  resource_group_name  = azurerm_resource_group.default.name
  node_resource_group  = "rg-${var.environment}-app-${local.location_lower}-aks-nodes"
  dns_prefix           = "aks-${var.environment}-${local.app}-${local.location_lower}"
  azure_policy_enabled = true

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_D2_v5"
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 6
  }

  identity {
    type = "SystemAssigned"
  }
}
