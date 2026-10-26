# Virtual Network (vnet-01)
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = [var.vnet_address_space]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = var.aks_cluster_name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.acr_name_prefix]
}

# Discovers your user object ID from 'az login' for ABAC role assignments
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Generates 6 lowercase alphanumeric characters to ensure global name uniqueness
resource "random_string" "acr_suffix" {
  length  = 6
  upper   = false
  special = false
}