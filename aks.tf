# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.aks_cluster_name}-${random_string.acr_suffix.result}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# AKS Cluster configured for Azure CNI and Windows workloads
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-01"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "aks-01-dns"

  sku_tier                = "Free"
  local_account_disabled  = false

  identity {
    type = "SystemAssigned"
  }

  # Required credentials for Windows node administration
  windows_profile {
    admin_username = "azureuser"
    admin_password = "P@ssw0rdAKS2026!" # Meets Azure complexity requirements
  }

  # Linux System Pool
  default_node_pool {
    name           = "agentpool"
    node_count     = 2 # Reduce to 1 if vCPU quota is restricted
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
    os_sku         = "Ubuntu"
    zones          = []
  }

  # Standard Azure CNI configuration
  network_profile {
    network_plugin     = "azure"
    network_policy     = "none"
    service_cidr       = "172.16.0.0/22"
    dns_service_ip     = "172.16.3.254"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }
}

# Windows 2022 User Node Pool (w1pool)
resource "azurerm_kubernetes_cluster_node_pool" "windows" {
  name                  = "w1pool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2s_v3"
  node_count            = 2 # Reduce to 1 if vCPU quota is restricted
  os_type               = "Windows"
  os_sku                = "Windows2022"
  mode                  = "User"
  max_pods              = 30
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  zones                 = []
}

# Grant AKS Kubelet Identity AcrPull rights on the Container Registry
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}