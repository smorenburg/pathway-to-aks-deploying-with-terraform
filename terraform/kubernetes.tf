# Create the managed identity for the cluster.
resource "azurerm_user_assigned_identity" "aks" {
  name                = "mi-aks-cluster-${local.name_suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}

# Create the cluster, including the default node pool.
resource "azurerm_kubernetes_cluster" "default" {
  name                 = "aks-cluster-${local.name_suffix}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.default.name
  node_resource_group  = "${azurerm_resource_group.default.name}-aks-nodes"
  dns_prefix           = "aks-cluster-${local.name_suffix}"
  azure_policy_enabled = true

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_D2_v5"
    vnet_subnet_id      = azurerm_subnet.aks.id
    zones               = ["1", "2", "3"]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 6
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  depends_on = [
    azurerm_role_assignment.subnet,
    azurerm_role_assignment.route_table
  ]
}
