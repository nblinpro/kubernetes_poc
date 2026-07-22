# Version épinglée pour la reproductibilité. Si l'apply échoue car la version n'existe
# plus au repo, vérifier avec : helm search repo argo/argo-cd --versions
#
# Le mot de passe admin n'est jamais en clair ici : configs.secret.argocdServerAdminPassword
# attend un hash bcrypt, fourni par var.argocd_admin_password_hash (elle-même injectée
# uniquement via TF_VAR_argocd_admin_password_hash, voir README).
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  set_sensitive = [
    {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.argocd_admin_password_hash
    }
  ]

  set = [
    {
      name  = "configs.secret.argocdServerAdminPasswordMtime"
      value = var.argocd_admin_password_mtime
    },
    {
      # Clé littérale "server.insecure" dans la map configs.params (le point fait
      # partie du nom de clé, d'où l'échappement) : argocd-server sert en HTTP en
      # interne, TLS est terminé par l'Ingress Traefik à la place.
      name  = "configs.params.server\\.insecure"
      value = "true"
    },
    {
      name  = "server.ingress.enabled"
      value = "true"
    },
    {
      name  = "server.ingress.ingressClassName"
      value = "traefik"
    },
    {
      name  = "server.ingress.hostname"
      value = local.argocd_hostname
    },
    {
      # Utilise le secret TLS auto-signé créé dans ingress.tf (argocd-server-tls).
      name  = "server.ingress.tls"
      value = "true"
    }
  ]

  depends_on = [null_resource.k3d_cluster]
}
