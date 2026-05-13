# =============================================================
#  providers.tf — Three-Subnet RDP Chain Architecture
#  Auth: Azure Key Vault via bootstrap provider
#  State: Azure Storage Account (blob locking)
# =============================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"

  # -----------------------------------------------------------
  # REMOTE BACKEND — Terraform State in Azure Storage
  # -----------------------------------------------------------
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatensgdemodev"
    container_name       = "tfstate"
    key                  = "dev/nsg-rdp-chain.tfstate"
  }
}

# -------------------------------------------------------------
# BOOTSTRAP PROVIDER
# Uses "az login" session only to read Key Vault secret
# -------------------------------------------------------------
provider "azurerm" {
  alias    = "bootstrap"
  features {}
}

# -------------------------------------------------------------
# MAIN PROVIDER
# Uses credentials parsed from Key Vault secret via locals.tf
# All resources in main.tf use this provider
# -------------------------------------------------------------
provider "azurerm" {
  features        {}
  client_id       = local.client_id
  client_secret   = local.client_secret
  tenant_id       = local.tenant_id
  subscription_id = local.subscription_id
}
