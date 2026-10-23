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