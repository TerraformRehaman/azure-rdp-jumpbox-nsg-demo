# =============================================================
#  data.tf — Pull credentials from Azure Key Vault
# =============================================================

# -------------------------------------------------------------
# DATA — Reference the Key Vault (bootstrap provider)
# -------------------------------------------------------------
data "azurerm_key_vault" "kv" {
  provider            = azurerm.bootstrap
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

# -------------------------------------------------------------
# DATA — Pull the secret from Key Vault
#
# Secret must be stored as JSON:
# {
#   "clientId":       "xxxx-xxxx-xxxx-xxxx",
#   "clientSecret":   "xxxx-xxxx-xxxx-xxxx",
#   "tenantId":       "xxxx-xxxx-xxxx-xxxx",
#   "subscriptionId": "xxxx-xxxx-xxxx-xxxx"
# }
# -------------------------------------------------------------
data "azurerm_key_vault_secret" "tf_creds" {
  provider     = azurerm.bootstrap
  name         = var.key_vault_secret_name
  key_vault_id = data.azurerm_key_vault.kv.id
}
