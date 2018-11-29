variable "tiller_replica_count" {
  description = "Number of pods to run Tiller"
}

variable "ingressctrl_replica_count" {
  description = "Number of pods to run the ingress controller"
}

variable "ingressctrl_ip_address" {
  description = "Public IP address to assign to the ingress controller"
}

variable "letsencrypt_email_address" {
  description = "Email address used to register with Let's Encrypt"
}

variable "letsencrypt_environment" {
  description = "Let's Encrypt server URL to which certificate requests will be sent"
}

variable "ingressctrl_fqdn" {
  description = "Full DNS name of the primary ingress controller"
}

variable "ingress_cert_yaml_path" {
  description = "Path of the generated definition file for the ingress controller certificate"
}

variable "environment" {
  description = "The type of environment this cluster is for. Some policies may apply only to 'Production' environments."
}
