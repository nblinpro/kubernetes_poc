#!/usr/bin/env bash
# Vérification en lecture seule de l'état du cluster après un `terraform apply`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG_PATH="${SCRIPT_DIR}/../terraform/kubeconfig"

if [[ ! -f "${KUBECONFIG_PATH}" ]]; then
  echo "Kubeconfig introuvable (${KUBECONFIG_PATH}). As-tu lancé terraform apply ?" >&2
  exit 1
fi

export KUBECONFIG="${KUBECONFIG_PATH}"

echo "== Nœuds =="
kubectl get nodes -o wide

echo
echo "== Pods (tous namespaces) =="
kubectl get pods -A

echo
echo "== Helm releases =="
helm list -A

echo
echo "== ArgoCD =="
kubectl -n argocd get pods
echo "Pour accéder à l'UI : kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "puis https://localhost:8080 (admin / mot de passe défini via TF_VAR_argocd_admin_password_hash)"
