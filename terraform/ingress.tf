locals {
  # nip.io résout automatiquement "<n'importe-quoi>.<IP>.nip.io" vers <IP>, sans
  # dépendre d'une vraie zone DNS ni de /etc/hosts sur les postes clients.
  argocd_hostname = "argocd.${var.argocd_host_ip}.nip.io"
}

# Certificat auto-signé pour l'Ingress ArgoCD : pas de cert-manager dans ce PoC,
# donc on génère et on injecte nous-mêmes le secret "argocd-server-tls" attendu
# par le chart quand server.ingress.tls = true.
resource "tls_private_key" "argocd" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "argocd" {
  private_key_pem = tls_private_key.argocd.private_key_pem

  subject {
    common_name = local.argocd_hostname
  }

  dns_names             = [local.argocd_hostname]
  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret_v1" "argocd_server_tls" {
  metadata {
    name      = "argocd-server-tls"
    namespace = "argocd"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.argocd.cert_pem
    "tls.key" = tls_private_key.argocd.private_key_pem
  }

  depends_on = [helm_release.argocd]
}
