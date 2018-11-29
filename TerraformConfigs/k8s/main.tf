resource "kubernetes_namespace" "management" {
  metadata {
    name = "management"
  }
}

resource "kubernetes_cluster_role_binding" "dashboard" {
  # Skipping this for production environments, as they shoudn't be managed with an omnipotent dashboard
  count = "${var.environment == "Prod" ? 0 : 1}"

  metadata {
    name = "kubernetes-dashboard"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = "system:serviceaccount:kube-system:kubernetes-dashboard"
  }
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name = "tiller"

    # Keeping tiller in the kube-system namespace to avoid the following error :
    # User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = "system:serviceaccount:kube-system:${kubernetes_service_account.tiller.metadata.0.name}"
  }
}

resource "null_resource" "helm_init" {
  provisioner "local-exec" {
    command = "helm init --wait --replicas ${var.tiller_replica_count} --tiller-namespace kube-system --service-account=${kubernetes_service_account.tiller.metadata.0.name}"
  }

  depends_on = ["kubernetes_cluster_role_binding.tiller"]
}

resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  chart     = "stable/nginx-ingress"
  namespace = "${kubernetes_namespace.management.metadata.0.name}"

  # Giving Azure 9min to create a load-balancer and assign the Public IP to it
  timeout    = "540"
  depends_on = ["null_resource.helm_init"]

  values = [<<EOF
  controller:
    replicaCount: ${var.ingressctrl_replica_count}
    service:
      loadBalancerIP: "${var.ingressctrl_ip_address}"
EOF
  ]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  chart      = "stable/cert-manager"
  namespace  = "${kubernetes_namespace.management.metadata.0.name}"
  timeout    = "540"
  depends_on = ["helm_release.nginx_ingress"]

  values = [<<EOF
  ingressShim:
    defaultIssuerName: letsencrypt-${var.letsencrypt_environment}
    defaultIssuerKind: ClusterIssuer
EOF
  ]
}

resource "helm_release" "cluster_issuer" {
  name       = "cluster-issuer"
  chart      = "..\\..\\Assets\\cluster-issuer"
  depends_on = ["helm_release.cert_manager"]

  values = [<<EOF
  email: ${var.letsencrypt_email_address}
  environment: ${var.letsencrypt_environment}
EOF
  ]
}

data "template_file" "ingress_cert" {
  template = "${file("..\\..\\Assets\\certificates.yaml.tpl")}"

  vars {
    ingressctrl_fqdn = "${var.ingressctrl_fqdn}"
    environment      = "${var.letsencrypt_environment}"
  }
}

resource "local_file" "ingress_cert" {
  content    = "${data.template_file.ingress_cert.rendered}"
  filename   = "${var.ingress_cert_yaml_path}"
  depends_on = ["helm_release.cluster_issuer"]
}

resource "null_resource" "ingress_cert_apply" {
  triggers {
    file_content = "${data.template_file.ingress_cert.rendered}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${var.ingress_cert_yaml_path}"
  }

  depends_on = ["local_file.ingress_cert"]
}

resource "null_resource" "ingress_cert_label" {
  provisioner "local-exec" {
    command = "./Add-SecretLabel.ps1 -SecretName tls-secret -Namespace ${kubernetes_namespace.management.metadata.0.name}"
    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "ByPass", "-Command"]
  }

  depends_on = ["null_resource.ingress_cert_apply"]
}

# To enable the use of a single TLS certificate by ingress resources in different namespaces
resource "helm_release" "secret_propagator" {
  name       = "secret-propagator"
  chart      = "..\\..\\Assets\\secret-propagator"
  depends_on = ["null_resource.ingress_cert_label"]

  values = [<<EOF
kubectlVersion: '1.12.1'
selector:
  key: propagate-to-ns
  value: 'true'
namespace:
  source: ${kubernetes_namespace.management.metadata.0.name}
replicaCount: 1
EOF
  ]
}
