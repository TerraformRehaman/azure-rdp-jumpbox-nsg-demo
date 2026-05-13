# =============================================================
#  outputs.tf — Two-Subnet RDP Chain
# =============================================================

output "vnet_id" {
  description = "VNet resource ID"
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_public_id" {
  description = "Subnet 1 (Public) ID"
  value       = azurerm_subnet.subnet_public.id
}

output "subnet_private_id" {
  description = "Subnet 2 (Private) ID"
  value       = azurerm_subnet.subnet_private.id
}

output "nsg_public_id" {
  description = "NSG for Subnet 1"
  value       = azurerm_network_security_group.nsg_public.id
}

output "nsg_private_id" {
  description = "NSG for Subnet 2"
  value       = azurerm_network_security_group.nsg_private.id
}

# -------------------------------------------------------------
# VM-1 — Public Windows RDP
# -------------------------------------------------------------
output "vm1_public_ip" {
  description = "Public IP of VM-1 — RDP target from your laptop"
  value       = azurerm_public_ip.vm1_pip.ip_address
}

output "vm1_private_ip" {
  description = "Private IP of VM-1"
  value       = azurerm_network_interface.nic_vm1.private_ip_address
}

output "rdp_to_vm1" {
  description = "Step 1: RDP from laptop to VM-1"
  value       = "mstsc /v:${azurerm_public_ip.vm1_pip.ip_address}"
}

# -------------------------------------------------------------
# VM-2 — Private Windows RDP
# -------------------------------------------------------------
output "vm2_private_ip" {
  description = "Private IP of VM-2 — RDP from inside VM-1"
  value       = azurerm_network_interface.nic_vm2.private_ip_address
}

output "rdp_to_vm2" {
  description = "Step 2: RDP from inside VM-1 to VM-2"
  value       = "mstsc /v:${azurerm_network_interface.nic_vm2.private_ip_address}"
}

# -------------------------------------------------------------
# KEY VAULT
# -------------------------------------------------------------
output "keyvault_id" {
  description = "Key Vault ID"
  value       = data.azurerm_key_vault.kv.id
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = data.azurerm_key_vault.kv.vault_uri
}
