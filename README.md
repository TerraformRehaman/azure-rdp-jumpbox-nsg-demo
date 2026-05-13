# azure-nsg-rdp-chain-terraform

Terraform project to deploy a two-subnet Azure architecture with NSG-controlled RDP chained access. Credentials are securely pulled from Azure Key Vault at runtime. No secrets are hardcoded anywhere.

---

## Architecture

```
Your Laptop (Public Internet)
        │
        │  RDP Port 3389
        ▼
┌──────────────────────────────────────────────────┐
│                  Azure Cloud                     │
│  ┌────────────────────────────────────────────┐  │
│  │           VNet: 10.0.0.0/16               │  │
│  │                                            │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │  Subnet 1 — Public  10.0.1.0/24      │  │  │
│  │  │  NSG: Allow RDP :3389 from laptop    │  │  │
│  │  │  VM-1 (Windows) · Public IP ✓        │  │  │
│  │  └───────────────┬──────────────────────┘  │  │
│  │                  │  RDP Port 3389           │  │
│  │  ┌───────────────▼──────────────────────┐  │  │
│  │  │  Subnet 2 — Private  10.0.2.0/24     │  │  │
│  │  │  NSG: Allow RDP only from Subnet 1   │  │  │
│  │  │  VM-2 (Windows) · No Public IP ✗     │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  Key Vault ──► tf-credentials secret             │
│  Storage   ──► tfstate blob (state + lock)       │
└──────────────────────────────────────────────────┘
```

---

## Project Structure

```
azure-nsg-rdp-chain-terraform/
├── providers.tf        # Bootstrap + Main AzureRM providers + remote backend
├── data.tf             # Key Vault data blocks
├── locals.tf           # Parse JSON secret into credential fields
├── variables.tf        # All input variable definitions with validation
├── main.tf             # All Azure resources + RDP auto-enable run commands
├── outputs.tf          # IPs and mstsc commands for each VM
├── main.dev.tfvars     # Dev environment variable values
└── README.md           # This file
```

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Terraform | >= 1.3.0 | https://developer.hashicorp.com/terraform/install |
| Azure CLI | latest | https://learn.microsoft.com/en-us/cli/azure/install-azure-cli |

---

## Manual Setup (One Time)

### 1. Create Resource Group for Key Vault

```bash
az group create --name "rg-keyvault" --location "northcentralus"
```

### 2. Create Key Vault

```bash
az keyvault create --name "kv-nsg-demo-dev" --resource-group "rg-keyvault" --location "northcentralus"
```

### 3. Store credentials as a JSON secret

> **⚠️ Note:** Before running the secret set command, complete these prerequisites:

#### 3a. Assign Key Vault Secrets Officer role to your user

```bash
az role assignment create --role "Key Vault Secrets Officer" --assignee "your-email@example.com" --scope "/subscriptions/<subscription-id>/resourceGroups/rg-keyvault/providers/Microsoft.KeyVault/vaults/kv-nsg-demo-dev"
```

#### 3b. Restrict network access to your laptop IP only

Find your public IP 👉 https://whatismyipaddress.com/

```bash
az keyvault update --name "kv-nsg-demo-dev" --resource-group "rg-keyvault" --default-action Deny --public-network-access Enabled

az keyvault network-rule add --name "kv-nsg-demo-dev" --resource-group "rg-keyvault" --ip-address "<YOUR-LAPTOP-IP>"
```

> Wait ~1 minute for propagation before continuing.

#### 3c. Set the secret (PowerShell — avoids BOM/quote issues)

```powershell
[System.IO.File]::WriteAllText("creds.json", '{"clientId":"xxxx","clientSecret":"xxxx","tenantId":"xxxx","subscriptionId":"xxxx"}')

az keyvault secret set --vault-name "kv-nsg-demo-dev" --name "tf-credentials" --file "creds.json"

Remove-Item "creds.json"
```

#### 3d. Assign roles to Service Principal (clientId)

```bash
# Key Vault Secrets User — read secrets
az role assignment create --role "Key Vault Secrets User" --assignee "<clientId>" --scope "/subscriptions/<subscription-id>/resourceGroups/rg-keyvault/providers/Microsoft.KeyVault/vaults/kv-nsg-demo-dev"

# Owner — manage all resources in target RG
az role assignment create --role "Owner" --assignee "<clientId>" --scope "/subscriptions/<subscription-id>/resourceGroups/rg-nsg-demo-dev"
```

---

## Remote Backend Setup (One Time)

### 1. Create Storage Account

```bash
az group create --name "rg-tfstate" --location "northcentralus"

az storage account create --name "sttfstatensgdemodev" --resource-group "rg-tfstate" --location "northcentralus" --sku "Standard_LRS" --kind "StorageV2" --min-tls-version "TLS1_2" --allow-blob-public-access false

az storage container create --name "tfstate" --account-name "sttfstatensgdemodev" --auth-mode login
```

### 2. Assign Storage Blob Data Contributor to Service Principal

```bash
az role assignment create --role "Storage Blob Data Contributor" --assignee "<clientId>" --scope "/subscriptions/<subscription-id>/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/sttfstatensgdemodev"
```

---

## Deployment

### Step 1 — Login

```bash
az login --tenant "your-tenant-id"
```

### Step 2 — Clone the repo

```bash
git clone https://github.com/<your-org>/azure-nsg-rdp-chain-terraform.git
cd azure-nsg-rdp-chain-terraform
```

### Step 3 — Update main.dev.tfvars

```hcl
key_vault_name           = "kv-nsg-demo-dev"
key_vault_resource_group = "rg-keyvault"
admin_password           = "YourStr0ng@Pass!"
my_laptop_ip             = "x.x.x.x/32"          # your public IP
```

### Step 4 — Run Terraform

```bash
terraform init
terraform plan  -var-file="main.dev.tfvars"
terraform apply -var-file="main.dev.tfvars"
```

---

## Outputs

| Output | Description |
|---|---|
| `vm1_public_ip` | Public IP of VM-1 (RDP from laptop) |
| `vm1_private_ip` | Private IP of VM-1 |
| `vm2_private_ip` | Private IP of VM-2 (RDP from VM-1) |
| `rdp_to_vm1` | Step 1 mstsc command |
| `rdp_to_vm2` | Step 2 mstsc command |
| `keyvault_uri` | Key Vault URI |

---

## Connect to VMs

### Step 1 — RDP to VM-1 (from your laptop)

```
Win + R → mstsc
Computer : <vm1_public_ip>
Username : azureadmin
Password : <admin_password>
```

### Step 2 — RDP to VM-2 (from inside VM-1)

Open **Run** inside VM-1:
```
Win + R → mstsc
Computer : 10.0.2.20
Username : azureadmin
Password : <admin_password>
```

---

## NSG Rules Summary

### Subnet 1 — Public (VM-1)

| Priority | Direction | Port | Source | Action |
|---|---|---|---|---|
| 100 | Inbound | 3389 (RDP) | Your Laptop IP | Allow |
| 100 | Outbound | Any | VirtualNetwork | Allow |
| 4000 | Inbound | Any | Any | Deny |

### Subnet 2 — Private (VM-2)

| Priority | Direction | Port | Source | Action |
|---|---|---|---|---|
| 100 | Inbound | 3389 (RDP) | 10.0.1.0/24 | Allow |
| 4000 | Inbound | Any | Any | Deny |

---

## Security Notes

- VM-2 has **no public IP** — unreachable from the internet
- The private subnet only accepts RDP from the public subnet (VM-1)
- Azure credentials are **never hardcoded** — pulled from Key Vault at runtime
- RDP is **auto-enabled** on all VMs via Terraform `run_command` resource
- Set `my_laptop_ip` to `x.x.x.x/32` for tightest security

---

## Cleanup

```bash
terraform destroy -var-file="main.dev.tfvars"
```

> Deallocate VMs to save cost when not in use:
> ```bash
> az vm deallocate -g rg-nsg-demo-dev -n vm1-rdp-public
> az vm deallocate -g rg-nsg-demo-dev -n vm2-rdp-private
> ```

---

## License

MIT
