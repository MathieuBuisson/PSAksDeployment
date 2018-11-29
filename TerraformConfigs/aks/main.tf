resource "azurerm_resource_group" "aks" {
  name     = "${var.cluster_name}-rg"
  location = "${var.location}"
}

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.cluster_name}-monitoring"
  location            = "${var.loganalytics_workspace_location}"
  resource_group_name = "${azurerm_resource_group.aks.name}"
  sku                 = "standalone"

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_log_analytics_solution" "container" {
  solution_name         = "ContainerInsights"
  location              = "${azurerm_log_analytics_workspace.aks.location}"
  resource_group_name   = "${azurerm_resource_group.aks.name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.aks.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.aks.name}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_template_deployment" "aks" {
  name                = "${var.cluster_name}-deploy"
  resource_group_name = "${azurerm_resource_group.aks.name}"
  template_body       = "${file("armTemplateAks.json")}"

  parameters {
    "cluster_name"              = "${var.cluster_name}"
    "location"                  = "${azurerm_resource_group.aks.location}"
    "kubernetes_version"        = "${var.kubernetes_version}"
    "agent_count"               = "${var.agent_count}"
    "agent_vm_size"             = "${var.agent_vm_size}"
    "os_disk_size_GB"           = "${var.os_disk_size_GB}"
    "agent_max_pods"            = "${var.agent_max_pods}"
    "client_id"                 = "${var.client_id}"
    "client_secret"             = "${var.client_secret}"
    "loganalytics_workspace_id" = "${azurerm_log_analytics_workspace.aks.id}"
    "environment_tag"           = "${var.environment}"
  }

  depends_on      = ["azurerm_log_analytics_solution.container"]
  deployment_mode = "Incremental"
}

resource "azurerm_public_ip" "ingressctrl_ip" {
  name                         = "${var.cluster_name}-ingressIP"
  location                     = "${azurerm_resource_group.aks.location}"
  resource_group_name          = "${azurerm_template_deployment.aks.outputs["infraResourceGroup"]}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.cluster_name}"

  tags {
    environment = "${var.environment}"
  }
}
