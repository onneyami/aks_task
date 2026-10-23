resource "kubernetes_namespace" "custom_ns" {
  metadata {
    name = var.namespace_name

    # Equivalent to editing YAML in Steps 13-15
    labels = {
      environment = "dev"
      managed-by  = "terraform"
    }

    annotations = {
      description = "Application workloads namespace created via Terraform"
    }
  }
}