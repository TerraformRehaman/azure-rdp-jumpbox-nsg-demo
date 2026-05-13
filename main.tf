# =============================================================
#  main.tf — Azure NSG Demo: Two-Subnet RDP Chain Scenario
#  Laptop → RDP → VM-1 (Public) → RDP → VM-2 (Private)
#  Credentials → pulled from Key Vault via data.tf
#  Provider    → configured in providers.tf
# =============================================================

# -------------------------------------------------------------
# RESOURCE GROUP
# -------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# -------------------------------------------------------------
# VIRTUAL NETWORK
# -------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-nsg-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

# -------------------------------------------------------------
# SUBNET 1 — Public (VM-1 Windows, Public IP, RDP from laptop)
# -------------------------------------------------------------
resource "azurerm_subnet" "subnet_public" {
  name                 = "subnet-public"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_public_prefix]
}

# -------------------------------------------------------------
# SUBNET 2 — Private (VM-2 Windows, RDP from Subnet 1 only)
# -------------------------------------------------------------
resource "azurerm_subnet" "subnet_private" {
  name                 = "subnet-private"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_private_prefix]
}

# =============================================================
# NSG 1 — Public Subnet
#   Allow: RDP (3389) from laptop IP
#   Allow: Outbound to VNet (to reach VM-2)
#   Deny:  Everything else
# =============================================================
resource "azurerm_network_security_group" "nsg_public" {
  name                = "nsg-subnet-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP-From-Laptop"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.my_laptop_ip
    destination_address_prefix = "*"
    description                = "Allow RDP from laptop to VM-1"
  }

  security_rule {
    name                       = "Allow-VNet-Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    description                = "Allow VM-1 to reach VM-2 inside VNet"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny all other inbound"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_public_assoc" {
  subnet_id                 = azurerm_subnet.subnet_public.id
  network_security_group_id = azurerm_network_security_group.nsg_public.id
}

# =============================================================
# NSG 2 — Private Subnet
#   Allow: RDP (3389) from Subnet 1 only (VM-1)
#   Deny:  Everything else
# =============================================================
resource "azurerm_network_security_group" "nsg_private" {
  name                = "nsg-subnet-private"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP-From-Subnet1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.subnet_public_prefix
    destination_address_prefix = "*"
    description                = "Allow RDP from VM-1 (Subnet 1) only"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Block all — including internet"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_private_assoc" {
  subnet_id                 = azurerm_subnet.subnet_private.id
  network_security_group_id = azurerm_network_security_group.nsg_private.id
}

# -------------------------------------------------------------
# PUBLIC IP — VM-1 only
# -------------------------------------------------------------
resource "azurerm_public_ip" "vm1_pip" {
  name                = "pip-vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# -------------------------------------------------------------
# NIC — VM-1 (Public Subnet, Public IP)
# -------------------------------------------------------------
resource "azurerm_network_interface" "nic_vm1" {
  name                = "nic-vm1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-vm1"
    subnet_id                     = azurerm_subnet.subnet_public.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm1_private_ip
    public_ip_address_id          = azurerm_public_ip.vm1_pip.id
  }

  tags = var.tags
}

# -------------------------------------------------------------
# NIC — VM-2 (Private Subnet, NO Public IP)
# -------------------------------------------------------------
resource "azurerm_network_interface" "nic_vm2" {
  name                = "nic-vm2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-vm2"
    subnet_id                     = azurerm_subnet.subnet_private.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm2_private_ip
  }

  tags = var.tags
}

# -------------------------------------------------------------
# VM-1 — Windows (Public Subnet, RDP from laptop)
# -------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "vm1-rdp-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm1_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic_vm1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = merge(var.tags, { role = "rdp-public-jumpbox" })
}

# -------------------------------------------------------------
# VM-2 — Windows (Private Subnet, RDP from VM-1 only)
# -------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "vm2-rdp-private"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm2_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.nic_vm2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = merge(var.tags, { role = "rdp-private" })
}

# =============================================================
# ENABLE RDP ON ALL VMs (Windows has RDP disabled by default)
# =============================================================
resource "azurerm_virtual_machine_run_command" "enable_rdp_vm1" {
  name               = "enable-rdp-vm1"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm1.id

  source {
    script = "Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0; Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'"
  }
}

resource "azurerm_virtual_machine_run_command" "enable_rdp_vm2" {
  name               = "enable-rdp-vm2"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.vm2.id

  source {
    script = "Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0; Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'"
  }
}
