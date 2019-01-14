output "log_analytics_workspace_name" {
  value = "${azurerm_log_analytics_workspace.aks.name}"
}

output "kubernetes_master_FQDN" {
  value = "${azurerm_kubernetes_cluster.aks.fqdn}"
}

output "AKS_resource_ID" {
  value = "${azurerm_kubernetes_cluster.aks.id}"
}

output "AKS_infra_resource_group" {
  value = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
}

output "ingressctrl_ip_address" {
  value = "${azurerm_public_ip.ingressctrl_ip.ip_address}"
}
