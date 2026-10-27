variable "environment" {
  description = "Target deployment environment (e.g., prod, nonprod, core)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod", "core"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, core."
  }
}

variable "primary_location" {
  description = "Primary Azure region for Landing Zone infrastructure"
  type        = string
  default     = "eastus"
}

variable "secondary_location" {
  description = "Secondary Azure region for disaster recovery and geo-replication"
  type        = string
  default     = "centralus"
}

variable "workload_name" {
  description = "Core workload or organizational name identifier"
  type        = string
  default     = "enterprise-platform"
}

variable "hub_vnet_address_space" {
  description = "Address space for the central Hub Virtual Network"
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "spoke_workload_address_space" {
  description = "Address space for the Core Workload Spoke Virtual Network"
  type        = list(string)
  default     = ["10.101.0.0/16"]
}

variable "spoke_shared_address_space" {
  description = "Address space for the Shared Services Spoke Virtual Network"
  type        = list(string)
  default     = ["10.102.0.0/16"]
}

variable "enable_azure_firewall" {
  description = "Flag to deploy Azure Firewall Premium in the Hub network"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Flag to deploy Azure Bastion Host for secure zero-public-IP VM management"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Enterprise governance tags applied to all landing zone resources"
  type        = map(string)
  default = {
    Architecture        = "Azure-Cloud-Adoption-Framework"
    CostCenter          = "Cloud-Platform-Core"
    ManagedBy           = "Terraform"
    SecurityCompliance  = "CIS-Azure-v2.0"
    DataClassification  = "Confidential"
  }
}
