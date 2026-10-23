# Retrieve the built-in Pod Security Baseline Initiative
data "azurerm_policy_set_definition" "aks_pod_security_baseline" {
  display_name = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
}

# Assign the initiative to the Resource Group scope with Deny enforcement
resource "azurerm_resource_group_policy_assignment" "aks_pod_security_baseline" {
  name                 = "aks-pod-security-baseline"
  display_name         = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
  description          = "Enforces Linux pod security baseline standards on all AKS clusters within the resource group"
  resource_group_id    = data.azurerm_resource_group.rg.id
  policy_definition_id = data.azurerm_policy_set_definition.aks_pod_security_baseline.id

  # Enables admission enforcement
  enforce = true

  # Sets the initiative parameter "effect" to Deny
  parameters = jsonencode({
    effect = {
      value = "Deny"
    }
    excludedNamespaces = {
      value = [
        "kube-system",
        "gatekeeper-system",
        "azure-arc"
      ]
    }
  })
}