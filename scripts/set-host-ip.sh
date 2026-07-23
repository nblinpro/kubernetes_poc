#!/usr/bin/env bash
# Remplace l'IP LAN codée en dur (hostnames nip.io, URL frontend) par une nouvelle,
# dans tous les fichiers du dépôt qui la référencent. Un seul point d'entrée au lieu
# de modifier chaque fichier à la main.
#
# Usage: ./scripts/set-host-ip.sh <ancienne_ip> <nouvelle_ip>
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <ancienne_ip> <nouvelle_ip>" >&2
  echo "Exemple: $0 192.168.80.169 10.0.0.42" >&2
  exit 1
fi

OLD_IP="$1"
NEW_IP="$2"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FILES=$(grep -rl "$OLD_IP" "$REPO_ROOT/apps" "$REPO_ROOT/k8s" "$REPO_ROOT/README.md" 2>/dev/null || true)

if [[ -z "$FILES" ]]; then
  echo "Aucun fichier ne référence ${OLD_IP}." >&2
  exit 1
fi

echo "Fichiers à mettre à jour :"
echo "$FILES"
echo

for f in $FILES; do
  sed -i "s/${OLD_IP//./\\.}/${NEW_IP}/g" "$f"
done

echo "Fait. IP remplacée : ${OLD_IP} -> ${NEW_IP}"
echo
echo "⚠️  Les certificats TLS auto-signés et les mots de passe scellés (Sealed Secrets)"
echo "   sont générés pour l'ancien hostname / l'ancien cluster : lance ensuite"
echo "   ./scripts/reseal-secrets.sh ${NEW_IP}"
echo "   puis commit + push."
