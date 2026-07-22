variable "cluster_name" {
  description = "Nom du cluster k3d"
  type        = string
  default     = "poc"
}

variable "agents_count" {
  description = "Nombre de nœuds worker (agents) k3d, en plus du server unique"
  type        = number
  default     = 2
}

variable "sealed_secrets_chart_version" {
  description = "Version du chart Helm sealed-secrets/sealed-secrets à épingler"
  type        = string
  default     = "2.19.1"
}

variable "argocd_chart_version" {
  description = <<-EOT
    Version du chart Helm argo/argo-cd à épingler (chart majeur 10.x au moment de la
    rédaction, appVersion ArgoCD v3.0.0). Vérifier avant l'apply avec
    `helm search repo argo/argo-cd --versions` et ajuster si la version n'existe plus.
  EOT
  type        = string
  default     = "10.1.4"
}

variable "argocd_admin_password_hash" {
  description = <<-EOT
    Hash bcrypt du mot de passe admin ArgoCD. Ne JAMAIS mettre de valeur en dur ici ni
    dans terraform.tfvars. Fournir via la variable d'environnement
    TF_VAR_argocd_admin_password_hash (voir README pour la commande htpasswd).
  EOT
  type        = string
  sensitive   = true
}

variable "argocd_admin_password_mtime" {
  description = "Horodatage RFC3339 associé au mot de passe admin ArgoCD (fixe pour éviter un diff Terraform à chaque apply)"
  type        = string
  default     = "2024-01-01T00:00:00Z"
}

variable "cnpg_chart_version" {
  description = <<-EOT
    Version du chart Helm cnpg/cloudnative-pg à épingler. Vérifier avant l'apply avec
    `helm search repo cnpg/cloudnative-pg --versions` et ajuster si la version n'existe
    plus.
  EOT
  type        = string
  default     = "0.29.0"
}

variable "argocd_host_ip" {
  description = <<-EOT
    IP utilisée pour construire le nom d'hôte nip.io de l'Ingress ArgoCD
    (argocd.<argocd_host_ip>.nip.io). Défaut 127.0.0.1 pour un accès local uniquement ;
    mettre l'IP LAN de la machine (ex: 192.168.80.169) pour y accéder depuis un autre
    poste du réseau.
  EOT
  type        = string
  default     = "127.0.0.1"
}
