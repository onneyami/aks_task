output "resource_group_name" {
  description = "The name of the resource group"
  value       = data.azurerm_resource_group.rg.name
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "The login server of the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "aks_cluster_name" {
  description = "The name of the provisioned AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_get_credentials_command" {
  description = "Command to configure kubectl credentials"
  value       = "az aks get-credentials --resource-group ${data.azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

#output "policy_assignment_id" {
#  description = "The Resource ID of the Azure Policy Assignment"
#  value       = azurerm_resource_group_policy_assignment.aks_pod_security_baseline.id
#}

#output "kubernetes_namespace" {
#  description = "The deployed Kubernetes namespace name"
#  value       = kubernetes_namespace.custom_ns.metadata[0].name
#}

output "aks_get_credentials" {
  description = "Command to configure kubectl credentials for the AKS cluster"
  value       = "az aks get-credentials --resource-group ${data.azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}