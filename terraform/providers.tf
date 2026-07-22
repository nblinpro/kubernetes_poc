# NOTE : le kubeconfig n'existe qu'après la création du cluster par
# null_resource.k3d_cluster. Terraform ne supporte pas de depends_on sur un bloc
# provider, donc le tout premier apply doit se faire en deux temps :
#   terraform apply -target=null_resource.k3d_cluster
#   terraform apply
# (voir README, section Démarrage). Les applies suivants fonctionnent normalement.

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = local.kubeconfig_path
  }
}
