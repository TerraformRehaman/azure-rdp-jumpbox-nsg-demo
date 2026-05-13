# =============================================================
#  variables.tf — Two-Subnet RDP Chain Architecture
# =============================================================

variable "location" {
  description = "Azure region"
  type        = string
  default     = "North Central US"
  validation {
    condition     = contains(["East US", "East US 2", "West US", "West US 2", "West Europe", "North Europe", "North Central US"], var.location)
    error_message = "Must be a valid Azure region."
  }
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
  default     = "rg-nsg-demo"
  validation {
    condition     = length(var.resource_group_name) >= 3 && length(var.resource_group_name) <= 90
    error_message = "Must be 3–90 characters."
  }
}

# -------------------------------------------------------------
# KEY VAULT
# -------------------------------------------------------------
variable "key_vault_name" {
  description = "Existing Key Vault name"
  type        = string
  validation {
    condition     = length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24
    error_message = "Must be 3–24 characters."
  }
}

variable "key_vault_resource_group" {
  description = "Resource group of the Key Vault"
  type        = string
}

variable "key_vault_secret_name" {
  description = "Secret name inside Key Vault"
  type        = string
  default     = "tf-credentials"
}

# -------------------------------------------------------------
# VM CREDENTIALS
# -------------------------------------------------------------
variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
  default     = "azureadmin"
  validation {
    condition     = length(var.admin_username) >= 3 && !contains(["admin", "administrator", "root", "guest"], var.admin_username)
    error_message = "Must be at least 3 chars and not a reserved name."
  }
}

variable "admin_password" {
  description = "Admin password (min 12 chars)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Must be at least 12 characters."
  }
}

# -------------------------------------------------------------
# NETWORKING
# -------------------------------------------------------------
variable "vnet_address_space" {
  description = "VNet CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_public_prefix" {
  description = "Subnet 1 — Public (VM-1)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_private_prefix" {
  description = "Subnet 2 — Private (VM-2)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "vm1_private_ip" {
  description = "Static private IP for VM-1"
  type        = string
  default     = "10.0.1.10"
}

variable "vm2_private_ip" {
  description = "Static private IP for VM-2"
  type        = string
  default     = "10.0.2.20"
}

variable "my_laptop_ip" {
  description = "Your public IP to allow RDP inbound (e.g. 98.156.1.186/32)"
  type        = string
  default     = "0.0.0.0/0"
  validation {
    condition     = can(cidrhost(var.my_laptop_ip, 0))
    error_message = "Must be a valid CIDR block."
  }
}

# -------------------------------------------------------------
# VM SIZES
# -------------------------------------------------------------
variable "vm1_size" {
  description = "VM-1 SKU (Public RDP Jump Box)"
  type        = string
  default     = "Standard_B1s"
}

variable "vm2_size" {
  description = "VM-2 SKU (Private)"
  type        = string
  default     = "Standard_B1s"
}

# -------------------------------------------------------------
# TAGS
# -------------------------------------------------------------
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    environment = "dev"
    project     = "nsg-rdp-chain"
    owner       = "your-name"
    managed_by  = "terraform"
  }
}
