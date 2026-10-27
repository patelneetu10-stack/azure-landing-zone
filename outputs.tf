output "hub_virtual_network_id" {
  description = "The ID of the central Hub Virtual Network"
  value       = azurerm_virtual_network.hub.id
}

output "hub_virtual_network_name" {
  description = "The name of the central Hub Virtual Network"
  value       = azurerm_virtual_network.hub.name
}

output "azure_firewall_private_ip" {
  description = "Private IP address of Azure Firewall for UDR routing"
  value       = var.enable_azure_firewall ? azurerm_firewall.hub[0].ip_configuration[0].private_ip_address : null
}

output "azure_firewall_public_ip" {
  description = "Public IP address of Azure Firewall"
  value       = var.enable_azure_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "bastion_host_name" {
  description = "The name of the deployed Azure Bastion Host"
  value       = var.enable_bastion ? azurerm_bastion_host.main[0].name : null
}

output "log_analytics_workspace_id" {
  description = "Central Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.core.id
}

output "spoke_workload_vnet_id" {
  description = "Workload Spoke Virtual Network ID"
  value       = azurerm_virtual_network.spoke_workload.id
}
