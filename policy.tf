# Query the built-in Kubernetes policy definition
data "azurerm_policy_definition" "k8s_no_privileged" {
  display_name = "Kubernetes cluster shouldn't allow privileged containers"
}

# Assign the policy at Resource Group scope
resource "azurerm_resource_group_policy_assignment" "k8s_policy" {
  name                 = "audit-k8s-privileged"
  display_name         = "Audit privileged containers on AKS"
  description          = "Audits pods and containers requesting privileged mode in AKS"
  resource_group_id    = data.azurerm_resource_group.rg.id
  policy_definition_id = data.azurerm_policy_definition.k8s_no_privileged.id

  # Policy enforcement = Enabled
  enforce = true

  # Parameters configuration
  parameters = jsonencode({
    effect = {
      value = "Audit"
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