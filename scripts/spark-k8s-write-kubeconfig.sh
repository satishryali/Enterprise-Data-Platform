#!/usr/bin/env bash
# Writes spark-k8s/kubeconfig.spark-submit.yaml (paths only; no secrets inline).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CA_FILE="$REPO_ROOT/server-ca.crt"
CLIENT_CERT="$REPO_ROOT/spark-k8s/submission-client.crt"
CLIENT_KEY="$REPO_ROOT/spark-k8s/submission-client.key"
OUT="$REPO_ROOT/spark-k8s/kubeconfig.spark-submit.yaml"

cat >"$OUT" <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: k3s
    cluster:
      server: https://192.168.1.195:6443
      certificate-authority: ${CA_FILE}
users:
  - name: k3s-admin
    user:
      client-certificate: ${CLIENT_CERT}
      client-key: ${CLIENT_KEY}
contexts:
  - name: k3s
    context:
      cluster: k3s
      user: k3s-admin
      namespace: default
current-context: k3s
EOF
RUN_USER="${SUDO_USER:-${USER}}"
RUN_GROUP="$(id -gn "$RUN_USER" 2>/dev/null || echo "$RUN_USER")"
chown "$RUN_USER:$RUN_GROUP" "$OUT"
chmod 600 "$OUT"
