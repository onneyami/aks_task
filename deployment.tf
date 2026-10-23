# Task 1: Create demo-deployment Namespace
resource "kubernetes_namespace_v1" "demo_deployment" {
  metadata {
    name = "demo-deployment"
  }
}

# Task 2: Create Nginx Deployment (v1.25)
resource "kubernetes_deployment_v1" "nginx_deployment" {
  metadata {
    name      = "nginx-deployment"
    namespace = kubernetes_namespace_v1.demo_deployment.metadata[0].name
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "mcr.microsoft.com/azurelinux/base/nginx:1.25"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}