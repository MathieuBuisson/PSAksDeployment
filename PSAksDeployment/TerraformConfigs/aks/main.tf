resource "azurerm_resource_group" "aks" {
  name     = "${var.cluster_name}-rg"
  location = "${var.location}"
}

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.cluster_name}-monitoring"
  location            = "${var.loganalytics_workspace_location}"
  resource_group_name = "${azurerm_resource_group.aks.name}"
  sku                 = "standalone"

  tags = {
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

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.cluster_name}"
  location            = "${azurerm_resource_group.aks.location}"
  resource_group_name = "${azurerm_resource_group.aks.name}"
  dns_prefix          = "${var.cluster_name}"
  kubernetes_version  = "${var.kubernetes_version}"

  agent_pool_profile {
    name            = "agentpool"
    count           = "${var.agent_count}"
    vm_size         = "${var.agent_vm_size}"
    os_type         = "Linux"
    os_disk_size_gb = "${var.os_disk_size_GB}"
    max_pods        = "${var.agent_max_pods}"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

  role_based_access_control {
    enabled = true
  }

  network_profile {
    network_plugin = "kubenet"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = "${azurerm_log_analytics_workspace.aks.id}"
    }
  }

  tags = {
    Environment = "${var.environment}"
  }

  depends_on = ["azurerm_log_analytics_solution.container"]
}

resource "azurerm_public_ip" "ingressctrl_ip" {
  name                = "${var.cluster_name}-ingressIP"
  location            = "${azurerm_kubernetes_cluster.aks.location}"
  resource_group_name = "${azurerm_kubernetes_cluster.aks.node_resource_group}"
  allocation_method   = "Static"
  domain_name_label   = "${var.cluster_name}"

  tags = {
    environment = "${var.environment}"
  }
}
