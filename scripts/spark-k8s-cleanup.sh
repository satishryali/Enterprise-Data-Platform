#!/usr/bin/env bash
# Remove Spark demo pods/services left in default namespace (by label).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KUBECONFIG="${KUBECONFIG:-$REPO_ROOT/spark-k8s/kubeconfig.admin.yaml}"

if [[ ! -f "$KUBECONFIG" ]]; then
  echo "No kubeconfig at $KUBECONFIG — run spark-k8s-setup-auth.sh first"
  exit 1
fi

export KUBECONFIG

echo "Deleting Spark driver/executor pods and services in default..."
kubectl delete pods,svc -n default -l spark-role=driver --ignore-not-found
kubectl delete pods,svc -n default -l spark-role=executor --ignore-not-found
kubectl delete secret spark-k8s-py-app -n default --ignore-not-found
kubectl delete configmap -n default -l spark-app-name=spark-k8s-distributed-demo --ignore-not-found 2>/dev/null || true
# Fallback: name prefix from --name spark-k8s-distributed-demo
kubectl delete pod,svc,configmap -n default --field-selector=metadata.name=spark-k8s-distributed-demo-driver --ignore-not-found 2>/dev/null || true

echo "Remaining Spark-related pods:"
kubectl get pods -n default -o wide 2>/dev/null | rg -i 'spark' || echo "(none)"
