# Built-in policy: Kubernetes cluster should not allow privileged containers
data "azurerm_policy_definition" "k8s_no_privileged" {
  name = "95edb821-ddaf-4404-9732-666045e056b4"
}

# Assign to rg-andrei so it evaluates the AKS cluster
resource "azurerm_resource_group_policy_assignment" "k8s_policy" {
  name                 = "audit-k8s-privileged"
  display_name         = "Audit privileged containers on AKS"
  description          = "Audits pods and containers requesting privileged mode in AKS"
  resource_group_id    = data.azurerm_resource_group.rg.id
  policy_definition_id = data.azurerm_policy_definition.k8s_no_privileged.id

  enforce = true

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