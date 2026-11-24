#!/usr/bin/env bash
# One-time (or daily) refresh of Spark submission credentials. Requires sudo.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# When invoked via sudo, write credentials for the invoking user (not root).
RUN_USER="${SUDO_USER:-${USER}}"
RUN_GROUP="$(id -gn "$RUN_USER" 2>/dev/null || echo "$RUN_USER")"

SPARK_K8S_DIR="$REPO_ROOT/spark-k8s"
CLIENT_CERT="$SPARK_K8S_DIR/submission-client.crt"
CLIENT_KEY="$SPARK_K8S_DIR/submission-client.key"
TOKEN_FILE="$SPARK_K8S_DIR/spark-submission-token"
KUBECONFIG_FILE="$SPARK_K8S_DIR/kubeconfig.admin.yaml"
CA_FILE="$REPO_ROOT/server-ca.crt"
K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

mkdir -p "$SPARK_K8S_DIR"

if [[ $EUID -eq 0 ]]; then
  KUBECTL=(kubectl)
  SUDO=""
else
  SUDO="sudo"
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found; using k3s kubectl via sudo"
    KUBECTL=(sudo k3s kubectl)
  else
    KUBECTL=(sudo kubectl)
  fi
fi

if [[ ! -f "$CA_FILE" ]]; then
  echo "Copying K3s cluster CA to $CA_FILE"
  $SUDO cp /var/lib/rancher/k3s/server/tls/server-ca.crt "$CA_FILE"
  if [[ -n $SUDO ]]; then
    $SUDO chown "$(id -u):$(id -g)" "$CA_FILE"
  fi
  chmod 644 "$CA_FILE"
fi

echo "Applying Spark RBAC (idempotent)..."
"${KUBECTL[@]}" apply -f "$SPARK_K8S_DIR/spark-rbac.yaml"
"${KUBECTL[@]}" apply -f "$SPARK_K8S_DIR/spark-submitter-rbac.yaml"

echo "Writing kubeconfig for manual kubectl (server https://192.168.1.195:6443)..."
$SUDO cp "$K3S_KUBECONFIG" "$KUBECONFIG_FILE"
sed -i 's|https://127.0.0.1:6443|https://192.168.1.195:6443|g' "$KUBECONFIG_FILE"

echo "Extracting client cert/key for spark-submit (K3s uses cert auth, not bearer tokens)..."
TMP_CERT="$(mktemp)"
TMP_KEY="$(mktemp)"
$SUDO kubectl --kubeconfig="$K3S_KUBECONFIG" config view --raw --minify \
  -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d >"$TMP_CERT"
$SUDO kubectl --kubeconfig="$K3S_KUBECONFIG" config view --raw --minify \
  -o jsonpath='{.users[0].user.client-key-data}' | base64 -d >"$TMP_KEY"
mv "$TMP_CERT" "$CLIENT_CERT"
mv "$TMP_KEY" "$CLIENT_KEY"
# Java/Fabric8 expects PKCS#8, not "BEGIN EC PRIVATE KEY" from K3s kubeconfig.
openssl pkcs8 -topk8 -nocrypt -inform PEM -outform PEM \
  -in "$CLIENT_KEY" -out "${CLIENT_KEY}.pkcs8"
mv "${CLIENT_KEY}.pkcs8" "$CLIENT_KEY"
chown "$RUN_USER:$RUN_GROUP" "$CLIENT_CERT" "$CLIENT_KEY" "$KUBECONFIG_FILE"
chmod 644 "$CLIENT_CERT"
chmod 600 "$CLIENT_KEY"
chmod 600 "$KUBECONFIG_FILE"

if [[ ! -s "$CLIENT_CERT" ]] || [[ ! -s "$CLIENT_KEY" ]]; then
  echo "ERROR: failed to extract client certificate or key from $K3S_KUBECONFIG"
  exit 1
fi

echo "Verifying API access..."
export KUBECONFIG="$KUBECONFIG_FILE"
kubectl get nodes -o wide
kubectl auth can-i create pods --as=system:serviceaccount:default:spark

"$REPO_ROOT/scripts/spark-k8s-write-kubeconfig.sh"

echo "Creating bearer token for spark-submit (avoids Java EC key parsing issues)..."
"${KUBECTL[@]}" create token spark-submitter -n default --duration=24h >"$TOKEN_FILE"
chown "$RUN_USER:$RUN_GROUP" "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

echo "OK. Run: $REPO_ROOT/scripts/spark-k8s-submit.sh"
