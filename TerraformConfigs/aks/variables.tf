variable "subscription_id" {
  description = "The ID of the Azure subscription where the AKS cluster will be deployed"
}

variable "client_secret" {
  description = "The password of the Service Principal used by Terraform (and the AKS cluster) to access Azure"
}

variable "tenant_id" {
  description = "The ID of the Azure AD tenant where the Terraform Service Principal lives"
}

variable "client_id" {
  description = "The application ID of the Service Principal used by Terraform (and the AKS cluster) to access Azure"
}

variable "cluster_name" {
  description = "The name of the AKS cluster (the containing resource group and the cluster DNS prefix are also using this value)"
}

variable "location" {
  description = "Azure region where the AKS cluster will be deployed"
}

variable "loganalytics_workspace_location" {
  description = "Azure region where the Log Analytics workspace will be deployed"
}

variable "kubernetes_version" {
  description = "The version of Kubernetes used on the AKS Cluster"
}

variable "agent_count" {
  description = "Number of worker nodes in the AKS cluster"
}

variable "agent_vm_size" {
  description = "The VM size for the AKS cluster nodes"
}

variable "os_disk_size_GB" {
  description = "The OS disk size for the cluster nodes. If set to 0, the default osDisk size for the specified vmSize is applied"
}

variable "agent_max_pods" {
  description = "The maximum number of pods that can run on a node"
}

variable "environment" {
  description = "The type of environment this cluster is for. Some policies may apply only to 'Production' environments."
}
