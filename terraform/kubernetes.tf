# Create the Kubernetes cluster, including the default node pool.
resource "azurerm_kubernetes_cluster" "default" {
  name                 = "aks-${local.name_suffix}"
  location             = local.location
  resource_group_name  = azurerm_resource_group.default.name
  node_resource_group  = "${azurerm_resource_group.default.name}-aks-nodes"
  dns_prefix           = "aks-${local.name_suffix}"
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
