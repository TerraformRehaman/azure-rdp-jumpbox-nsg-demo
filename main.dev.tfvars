# =============================================================
#  main.dev.tfvars — Two-Subnet RDP Chain (Dev)
#  Usage: terraform plan  -var-file="main.dev.tfvars"
#         terraform apply -var-file="main.dev.tfvars"
# =============================================================

# -------------------------------------------------------------
# ENVIRONMENT
# -------------------------------------------------------------
location            = "North Central US"
resource_group_name = "rg-nsg-demo-dev"

# -------------------------------------------------------------
# KEY VAULT
# -------------------------------------------------------------
key_vault_name           = "kv-nsg-demo-dev"
key_vault_resource_group = "rg-keyvault"
key_vault_secret_name    = "tf-credentials"

# -------------------------------------------------------------
# VM CREDENTIALS
# -------------------------------------------------------------
admin_username = "azureadmin"
admin_password = "AdminPass@1993"

# -------------------------------------------------------------
# NETWORKING
# -------------------------------------------------------------
vnet_address_space    = "10.0.0.0/16"
subnet_public_prefix  = "10.0.1.0/24"     # VM-1 public
subnet_private_prefix = "10.0.2.0/24"     # VM-2 private
vm1_private_ip        = "10.0.1.10"
vm2_private_ip        = "10.0.2.20"
my_laptop_ip          = "98.156.1.186/32"  # ← your laptop IP

# -------------------------------------------------------------
# VM SIZES (free tier)
# -------------------------------------------------------------
vm1_size = "Standard_B1s"
vm2_size = "Standard_B1s"

# -------------------------------------------------------------
# TAGS
# -------------------------------------------------------------
tags = {
  environment = "dev"
  project     = "nsg-rdp-chain"
  owner       = "your-name"
  managed_by  = "terraform"
}
