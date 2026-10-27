# ==============================================================================
# Azure Landing Zone (CAF) - Hub-and-Spoke Enterprise Network Foundation
# ==============================================================================

# 1. Central Resource Groups
resource "azurerm_resource_group" "hub" {
  name     = "rg-${var.workload_name}-hub-${var.environment}"
  location = var.primary_location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke_workload" {
  name     = "rg-${var.workload_name}-spoke-app-${var.environment}"
  location = var.primary_location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke_shared" {
  name     = "rg-${var.workload_name}-spoke-shared-${var.environment}"
  location = var.primary_location
  tags     = var.tags
}

# 2. Centralized Observability & Logging (Log Analytics Workspace)
resource "azurerm_log_analytics_workspace" "core" {
  name                = "law-${var.workload_name}-${var.environment}-01"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
  tags                = var.tags
}

# 3. Hub Virtual Network & Core Subnets
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = var.hub_vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.100.0.0/24"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.100.1.0/24"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.100.2.0/24"]
}

resource "azurerm_subnet" "hub_management" {
  name                 = "snet-hub-management"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.100.3.0/24"]
}

# 4. Azure Firewall (Standard/Premium with Central Policy)
resource "azurerm_public_ip" "firewall" {
  count               = var.enable_azure_firewall ? 1 : 0
  name                = "pip-afw-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall_policy" "main" {
  count               = var.enable_azure_firewall ? 1 : 0
  name                = "afwp-${var.workload_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku                 = "Standard"
  tags                = var.tags

  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall" "hub" {
  count               = var.enable_azure_firewall ? 1 : 0
  name                = "afw-${var.workload_name}-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  zones               = ["1", "2", "3"]
  tags                = var.tags

  ip_configuration {
    name                 = "firewall-ip-config"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

# 5. Azure Bastion Host (Zero-Public-IP Administrative Access)
resource "azurerm_public_ip" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "pip-bas-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "main" {
  count               = var.enable_bastion ? 1 : 0
  name                = "bas-${var.workload_name}-${var.environment}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tunneling_enabled   = true
  ip_connect_enabled  = true
  tags                = var.tags

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

# 6. Spoke Virtual Networks (Workload & Shared Services)
resource "azurerm_virtual_network" "spoke_workload" {
  name                = "vnet-spoke-workload-${var.environment}"
  location            = azurerm_resource_group.spoke_workload.location
  resource_group_name = azurerm_resource_group.spoke_workload.name
  address_space       = var.spoke_workload_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "workload_app" {
  name                 = "snet-workload-app"
  resource_group_name  = azurerm_resource_group.spoke_workload.name
  virtual_network_name = azurerm_virtual_network.spoke_workload.name
  address_prefixes     = ["10.101.1.0/24"]
}

resource "azurerm_subnet" "workload_data" {
  name                 = "snet-workload-data"
  resource_group_name  = azurerm_resource_group.spoke_workload.name
  virtual_network_name = azurerm_virtual_network.spoke_workload.name
  address_prefixes     = ["10.101.2.0/24"]
}

resource "azurerm_subnet" "workload_private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.spoke_workload.name
  virtual_network_name = azurerm_virtual_network.spoke_workload.name
  address_prefixes     = ["10.101.3.0/24"]
}

# 7. VNet Peering (Hub <-> Spoke Workload)
resource "azurerm_virtual_network_peering" "hub_to_workload" {
  name                         = "peer-hub-to-workload"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_workload.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_virtual_network_peering" "workload_to_hub" {
  name                         = "peer-workload-to-hub"
  resource_group_name          = azurerm_resource_group.spoke_workload.name
  virtual_network_name         = azurerm_virtual_network.spoke_workload.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  depends_on                   = [azurerm_virtual_network_peering.hub_to_workload]
}

# 8. User-Defined Routing (UDR) - Forced Tunneling via Azure Firewall
resource "azurerm_route_table" "spoke_to_firewall" {
  count                         = var.enable_azure_firewall ? 1 : 0
  name                          = "rt-spoke-egress-to-fw"
  location                      = azurerm_resource_group.spoke_workload.location
  resource_group_name           = azurerm_resource_group.spoke_workload.name
  disable_bgp_route_propagation = false
  tags                          = var.tags

  route {
    name                   = "route-default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.hub[0].ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "workload_app" {
  count          = var.enable_azure_firewall ? 1 : 0
  subnet_id      = azurerm_subnet.workload_app.id
  route_table_id = azurerm_route_table.spoke_to_firewall[0].id
}
