output "log_analytics_workspace_name" {
  value = "${azurerm_log_analytics_workspace.aks.name}"
}

output "kubernetes_master_FQDN" {
  value = "${azurerm_template_deployment.aks.outputs["masterFQDN"]}"
}

output "AKS_resource_ID" {
  value = "${azurerm_template_deployment.aks.outputs["clusterID"]}"
}

output "AKS_infra_resource_group" {
  value = "${azurerm_template_deployment.aks.outputs["infraResourceGroup"]}"
}

output "ingressctrl_ip_address" {
  value = "${azurerm_public_ip.ingressctrl_ip.ip_address}"
}
