# Create the virtual network.
resource "azurerm_virtual_network" "default" {
  name                = "vnet-${local.suffix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.10.0.0/16"]
}

# Create the subnet.
resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Create the network security group.
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}

# Create the route table.
resource "azurerm_route_table" "aks" {
  name                = "rt-aks-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}

# Associate the network security group with the subnet.
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Associate the route table with the subnet.
resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.aks.id
}

# Assign the 'Network Contributor' role for the managed identity to the subnet and route table.
resource "azurerm_role_assignment" "subnet" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.kubernetes_cluster.principal_id
}

resource "azurerm_role_assignment" "route_table" {
  scope                = azurerm_route_table.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.kubernetes_cluster.principal_id
}
