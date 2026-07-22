locals {
  k3d_config_path = "${path.module}/.k3d-config.rendered.yaml"
  kubeconfig_path = "${path.module}/kubeconfig"
}

resource "local_file" "k3d_config" {
  content = templatefile("${path.module}/k3d-config.yaml.tpl", {
    cluster_name = var.cluster_name
    agents_count = var.agents_count
  })
  filename = local.k3d_config_path
}

# Il n'existe pas de provider Terraform k3d officiel/mature : on pilote le CLI k3d via
# local-exec. Le garde `k3d cluster list` rend le create idempotent (un ré-apply avec
# triggers inchangés ne relance de toute façon pas ce local-exec, mais la garde protège
# aussi contre une reprise après un apply interrompu).
resource "null_resource" "k3d_cluster" {
  triggers = {
    config_hash  = local_file.k3d_config.content_md5
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      if k3d cluster list | awk 'NR>1 {print $1}' | grep -qx "${var.cluster_name}"; then
        echo "Cluster ${var.cluster_name} existe déjà, création ignorée."
      else
        k3d cluster create --config "${local.k3d_config_path}"
      fi
      k3d kubeconfig write "${var.cluster_name}" --output "${local.kubeconfig_path}"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "k3d cluster delete ${self.triggers.cluster_name}"
  }

  depends_on = [local_file.k3d_config]
}
