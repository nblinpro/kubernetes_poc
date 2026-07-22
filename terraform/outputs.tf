output "next_steps" {
  description = "Rappel des commandes utiles après un apply réussi"
  value       = <<-EOT
    Cluster        : ${var.cluster_name} (1 server + ${var.agents_count} agents)
    Kubeconfig     : ${local.kubeconfig_path}
    Nodes          : kubectl --kubeconfig ${local.kubeconfig_path} get nodes
    ArgoCD UI      : https://${local.argocd_hostname} (utilisateur: admin, certificat auto-signé à accepter)
                     Si l'IP ne correspond pas à ta machine, relance apply avec
                     -var="argocd_host_ip=<ton IP LAN>".
  EOT
}
