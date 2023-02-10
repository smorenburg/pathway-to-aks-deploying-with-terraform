resource "azurerm_kubernetes_cluster" "example" {
  name                 = "cluster-${var.environment}-aks-${local.location_name}"
  location             = local.location
  resource_group_name  = azurerm_resource_group.aks.name
  dns_prefix           = "cluster-${var.environment}-aks-${local.location_name}"
  azure_policy_enabled = true

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2_v5"
  }

  identity {
    type = "SystemAssigned"
  }
}
