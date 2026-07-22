# Version épinglée pour la reproductibilité. Si l'apply échoue car la version n'existe
# plus au repo, vérifier avec : helm search repo sealed-secrets/sealed-secrets --versions
resource "helm_release" "sealed_secrets" {
  name             = "sealed-secrets"
  repository       = "https://bitnami.github.io/sealed-secrets"
  chart            = "sealed-secrets"
  version          = var.sealed_secrets_chart_version
  namespace        = "kube-system"
  create_namespace = false

  depends_on = [null_resource.k3d_cluster]
}
