variable "subscription_id" {
  description = "Target Azure subscription ID. Authentication uses Azure CLI or workload identity."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant containing the subscription."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group to import, or a new resource group name."
  type        = string
}

variable "location" {
  description = "Azure region for the resource group and App Service resources."
  type        = string
  default     = "japanwest"
}

variable "plan_name" {
  description = "App Service Plan name."
  type        = string
}

variable "web_app_name" {
  description = "Globally unique Web App name. Change it when creating a separate environment."
  type        = string
}

variable "sku_name" {
  description = "Free or Basic Linux App Service SKU. Basic plans incur charges."
  type        = string
  default     = "B1"

  validation {
    condition     = contains(["F1", "B1", "B2", "B3"], var.sku_name)
    error_message = "Use F1, B1, B2, or B3. Check regional quota before provisioning."
  }
}

variable "public_network_access_enabled" {
  description = "Enable public HTTPS access only with the required organizational approval."
  type        = bool
  default     = false
}

variable "resource_tags" {
  description = "Tags on the plan and web app only. SecurityControl=Ignore is an approved policy exception."
  type        = map(string)
  default     = {}
}