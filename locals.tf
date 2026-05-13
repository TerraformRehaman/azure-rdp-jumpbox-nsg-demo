# =============================================================
#  locals.tf — Parse Key Vault secret JSON into named values
# =============================================================

locals {
  # Parse the JSON secret pulled from Key Vault in data.tf
  creds = jsondecode(data.azurerm_key_vault_secret.tf_creds.value)

  # Individual credential fields used by providers.tf
  client_id       = local.creds["clientId"]
  client_secret   = local.creds["clientSecret"]
  tenant_id       = local.creds["tenantId"]
  subscription_id = local.creds["subscriptionId"]
}
