#!/usr/bin/env bash
# Régénère tous les Sealed Secrets du dépôt contre le contrôleur sealed-secrets du
# cluster CIBLE (KUBECONFIG courant). Nécessaire après un redéploiement sur une
# nouvelle machine : chaque contrôleur sealed-secrets génère sa propre paire de clés,
# les SealedSecret existants (chiffrés pour l'ancien cluster) ne se déchiffrent pas
# ailleurs.
#
# Usage: ./scripts/reseal-secrets.sh <ip_lan>
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <ip_lan>" >&2
  echo "Exemple: $0 192.168.80.169" >&2
  exit 1
fi

HOST_IP="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for bin in kubectl kubeseal openssl; do
  command -v "$bin" >/dev/null || { echo "$bin introuvable dans le PATH" >&2; exit 1; }
done

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "Récupération du certificat public du contrôleur sealed-secrets..."
kubeseal --fetch-cert --controller-namespace kube-system --controller-name sealed-secrets \
  > "$WORKDIR/pub-cert.pem"

seal_generic_secret() {
  local name="$1" namespace="$2" outfile="$3"
  shift 3
  kubectl create secret generic "$name" --namespace "$namespace" "$@" \
    --dry-run=client -o yaml \
    | kubeseal --cert "$WORKDIR/pub-cert.pem" --format yaml > "$outfile"
}

seal_tls_secret() {
  local name="$1" namespace="$2" hostname="$3" outfile="$4"
  openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
    -keyout "$WORKDIR/tls.key" -out "$WORKDIR/tls.crt" \
    -subj "/CN=${hostname}" \
    -addext "subjectAltName=DNS:${hostname}" >/dev/null 2>&1
  kubectl create secret tls "$name" --namespace "$namespace" \
    --cert="$WORKDIR/tls.crt" --key="$WORKDIR/tls.key" \
    --dry-run=client -o yaml \
    | kubeseal --cert "$WORKDIR/pub-cert.pem" --format yaml > "$outfile"
  rm -f "$WORKDIR/tls.key" "$WORKDIR/tls.crt"
}

echo "Scellement redis-secret (mot de passe Redis)..."
REDIS_PASSWORD=$(openssl rand -base64 24)
seal_generic_secret redis-secret todo "$REPO_ROOT/k8s/redis/sealedsecret.yaml" \
  --from-literal=password="$REDIS_PASSWORD"

echo "Scellement grafana-admin-credentials..."
GRAFANA_PASSWORD=$(openssl rand -base64 24)
seal_generic_secret grafana-admin-credentials monitoring "$REPO_ROOT/k8s/monitoring/sealedsecret-grafana-admin.yaml" \
  --from-literal=admin-user="admin" \
  --from-literal=admin-password="$GRAFANA_PASSWORD"

echo "Scellement todo-api-tls (todo-api.${HOST_IP}.nip.io)..."
seal_tls_secret todo-api-tls todo "todo-api.${HOST_IP}.nip.io" "$REPO_ROOT/k8s/todo-api/sealedsecret-tls.yaml"

echo "Scellement todo-frontend-tls (todo.${HOST_IP}.nip.io)..."
seal_tls_secret todo-frontend-tls todo "todo.${HOST_IP}.nip.io" "$REPO_ROOT/k8s/frontend/sealedsecret-tls.yaml"

echo "Scellement grafana-tls (grafana.${HOST_IP}.nip.io)..."
seal_tls_secret grafana-tls monitoring "grafana.${HOST_IP}.nip.io" "$REPO_ROOT/k8s/monitoring/sealedsecret-grafana-tls.yaml"

echo
echo "Terminé. Mots de passe générés (à noter maintenant, plus jamais affichés) :"
echo "  Redis   : ${REDIS_PASSWORD}"
echo "  Grafana : ${GRAFANA_PASSWORD}"
echo
echo "Prochaine étape : commit + push, puis laisser ArgoCD resynchroniser."
