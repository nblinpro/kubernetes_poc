# Bootstrap App-of-Apps : seule cette Application racine est appliquée par Terraform.
# Tout le reste (postgres, redis, todo-api) est ensuite géré en pur GitOps par ArgoCD
# depuis k8s/apps (voir k8s/root-app.yaml) — Terraform ne les touche jamais directement.
resource "kubernetes_manifest" "root_app" {
  manifest = yamldecode(file("${path.module}/../k8s/root-app.yaml"))

  depends_on = [helm_release.argocd]
}
