apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: tls-secret
  namespace: management
spec:
  secretName: tls-secret
  dnsNames:
  - ${ingressctrl_fqdn}
  acme:
    config:
    - http01:
        ingressClass: nginx
      domains:
      - ${ingressctrl_fqdn}
  issuerRef:
    name: letsencrypt-${environment}
    kind: ClusterIssuer