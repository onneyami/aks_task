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
