resource "azurerm_container_registry" "acr" {
  name                = "${var.acr_name_prefix}${random_string.acr_suffix.result}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = true
  role_assignment_mode = "AbacRepositoryPermissions"

  #tags = {
  #  environment = "dev"
  #  project     = "myproject"
  #}
}

resource "azurerm_role_assignment" "acr_repository_writer" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Container Registry Repository Writer"
  scope                = azurerm_container_registry.acr.id
}

resource "azurerm_role_assignment" "acr_catalog_lister" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Container Registry Catalog Lister"
  scope                = azurerm_container_registry.acr.id
}