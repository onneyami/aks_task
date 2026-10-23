variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-andrei"
}

variable "acr_name_prefix" {
  description = "The prefix for the Azure Container Registry name"
  type        = string
  default     = "newregistryapl"
}

variable "acr_sku" {
  description = "The SKU for the Azure Container Registry"
  type        = string
  default     = "Standard"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "myAKSCluster"
}

variable "aks_node_size" {
  description = "VM size for the default system node pool"
  type        = string
  default     = "Standard_D4ds_v5" # Fallback to Standard_D2s_v5 if vCPU quota in rg-andrei is restricted
}