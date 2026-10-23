# Container Insights (Azure Monitor) Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.aks_cluster_name}-${random_string.acr_suffix.result}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Azure Kubernetes Service (AKS) Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "${var.aks_cluster_name}-${random_string.acr_suffix.result}"

  # Step 7: Pricing Tier explicitly set to Free
  sku_tier = "Free"

  # Step 7: Local accounts with Kubernetes RBAC (no Azure AD / Azure RBAC enforcement)
  local_account_disabled = false

  # Step 7: Managed Identity for cluster control plane
  identity {
    type = "SystemAssigned"
  }

  # Step 8: System node pool (Dev/Test preset: 1 node, no Availability Zones)
  default_node_pool {
    name       = "systempool"
    node_count = 1
    vm_size    = var.aks_node_size
    os_sku     = "Ubuntu"
    zones      = [] # Availability zones: None
  }

  # Step 11: Networking - Azure CNI Overlay powered by Cilium
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
  }

  # Step 12: Observability - Container Insights
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }
}

# Step 12: ACR Attachment (AcrPull permission for AKS Kubelet Managed Identity)
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}