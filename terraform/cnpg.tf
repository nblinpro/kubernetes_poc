# Version épinglée pour la reproductibilité. Si l'apply échoue car la version n'existe
# plus au repo, vérifier avec : helm search repo cnpg/cloudnative-pg --versions
resource "helm_release" "cnpg" {
  name             = "cnpg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  version          = var.cnpg_chart_version
  namespace        = "cnpg-system"
  create_namespace = true

  depends_on = [null_resource.k3d_cluster]
}
