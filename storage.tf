# Task 1: Custom StorageClass with Azure Disk CSI driver and Retain policy
resource "kubernetes_storage_class_v1" "managed_premium_retain" {
  metadata {
    name = "managed-premium-retain"
  }

  storage_provisioner    = "disk.csi.azure.com"
  reclaim_policy         = "Retain"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    skuName = "Premium_LRS"
  }
}

# Task 2: PersistentVolumeClaim requesting 5Gi
resource "kubernetes_persistent_volume_claim_v1" "pvc" {
  metadata {
    name      = "azure-managed-disk"
    namespace = "default"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class_v1.managed_premium_retain.metadata[0].name

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  # Prevents Terraform from waiting for the Bound state before creating the pod
  wait_until_bound = false
}

# Task 3: Pod with persistent volume mount
resource "kubernetes_pod_v1" "nginx" {
  metadata {
    name      = "nginx"
    namespace = "default"
  }

  spec {
    container {
      name  = "myfrontend"
      image = "mcr.microsoft.com/azurelinux/base/nginx:1.28"

      volume_mount {
        mount_path = "/mnt/azure"
        name       = "volume"
      }
    }

    volume {
      name = "volume"

      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim_v1.pvc.metadata[0].name
      }
    }
  }

  timeouts {
    create = "10m"
  }

  depends_on = [kubernetes_persistent_volume_claim_v1.pvc]
}