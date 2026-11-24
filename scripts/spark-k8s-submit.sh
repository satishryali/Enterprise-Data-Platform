#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

CA_FILE="$REPO_ROOT/server-ca.crt"
TOKEN_FILE="$REPO_ROOT/spark-k8s/spark-submission-token"
APP_FILE="$REPO_ROOT/spark_k8s_test.py"
EXEC_TEMPLATE="$REPO_ROOT/spark-k8s/executor-pod-template.yaml"
DRIVER_TEMPLATE="$REPO_ROOT/spark-k8s/driver-pod-template.yaml"
K8S_API="https://192.168.1.195:6443"
APP_NAME="spark-k8s-distributed-demo"
PY_SECRET="spark-k8s-py-app"
KUBECTL_KUBECONFIG="$REPO_ROOT/spark-k8s/kubeconfig.admin.yaml"

for f in "$CA_FILE" "$TOKEN_FILE" "$APP_FILE" "$EXEC_TEMPLATE" "$DRIVER_TEMPLATE"; do
  if [[ ! -f "$f" ]]; then
    echo "Missing required file: $f"
    echo "Run first: $REPO_ROOT/scripts/spark-k8s-setup-auth.sh"
    exit 1
  fi
done

if [[ -d "$REPO_ROOT/.venv" ]]; then
  export SPARK_HOME="$REPO_ROOT/.venv/lib/python3.10/site-packages/pyspark"
  export PATH="$SPARK_HOME/bin:$PATH"
fi

export SPARK_LOCAL_IP="${SPARK_LOCAL_IP:-192.168.1.195}"

# Do not load kubeconfig client certs into Fabric8 (EC keys break Java). Use token + CA only.
unset KUBECONFIG

echo "Publishing Python app as Secret ${PY_SECRET} (mounted into driver)..."
kubectl --kubeconfig="$KUBECTL_KUBECONFIG" create secret generic "$PY_SECRET" \
  --from-file=spark_k8s_test.py="$APP_FILE" \
  --dry-run=client -o yaml | kubectl --kubeconfig="$KUBECTL_KUBECONFIG" apply -f -

echo "Submitting PySpark job to K3s (cluster mode)..."
echo "  Driver node selector: homeserver"
echo "  Executors: 2 on nodes with label spark-worker=true (anti-affinity: one per host)"
echo ""

spark-submit \
  --master "k8s://${K8S_API}" \
  --deploy-mode cluster \
  --name "$APP_NAME" \
  --conf "spark.kubernetes.container.image=apache/spark:4.2.0" \
  --conf "spark.kubernetes.container.image.pullPolicy=IfNotPresent" \
  --conf "spark.kubernetes.namespace=default" \
  --conf "spark.kubernetes.authenticate.submission.caCertFile=${CA_FILE}" \
  --conf "spark.kubernetes.authenticate.submission.oauthTokenFile=${TOKEN_FILE}" \
  --conf "spark.kubernetes.authenticate.driver.serviceAccountName=spark" \
  --conf "spark.kubernetes.authenticate.executor.serviceAccountName=spark" \
  --conf "spark.kubernetes.driver.secrets.${PY_SECRET}=/opt/spark/work-dir" \
  --conf "spark.kubernetes.executor.instances=2" \
  --conf "spark.kubernetes.executor.node.selector.spark-worker=true" \
  --conf "spark.kubernetes.driver.node.selector.kubernetes.io/hostname=homeserver" \
  --conf "spark.kubernetes.driver.podTemplateFile=${DRIVER_TEMPLATE}" \
  --conf "spark.kubernetes.executor.podTemplateFile=${EXEC_TEMPLATE}" \
  --conf "spark.executor.cores=1" \
  --conf "spark.executor.memory=1g" \
  --conf "spark.driver.cores=1" \
  --conf "spark.driver.memory=1g" \
  --conf "spark.driver.port=37078" \
  --conf "spark.kubernetes.executor.useDriverPodIP=true" \
  --conf "spark.driver.blockManager.port=37079" \
  --conf "spark.blockManager.port=0" \
  --conf "spark.pyspark.python=python3" \
  --conf "spark.kubernetes.driverEnv.PYSPARK_PYTHON=python3" \
  --conf "spark.kubernetes.executorEnv.PYSPARK_PYTHON=python3" \
  --conf "spark.kubernetes.submission.waitAppCompletion=true" \
  --conf "spark.dynamicAllocation.enabled=false" \
  --conf "spark.kubernetes.executor.request.cores=1" \
  --conf "spark.network.timeout=300s" \
  --conf "spark.executor.heartbeatInterval=30s" \
  --conf "spark.kubernetes.executor.maxFailures=15" \
  --conf "spark.executor.maxNumFailures=15" \
  "local:///opt/spark/work-dir/spark_k8s_test.py"
