# Spark on K3s (distributed demo)

## What was wrong

1. **SSL (`PKIX path building failed`)** — `spark-submit` must use `spark.kubernetes.authenticate.submission.caCertFile` pointing at the K3s CA (`server-ca.crt`).
2. **K3s admin auth uses client certificates**, not a `token:` field in `k3s.yaml`. Submission needs `submission.clientCertFile` + `submission.clientKeyFile` (created by `spark-k8s-setup-auth.sh`).
3. **`local:///opt/spark/work-dir/spark_k8s_test.py`** — use `file:///…/spark_k8s_test.py` so Spark uploads the app.

## Quick start (on homeserver)

```bash
cd ~/Enterprise-Data-Platform
chmod +x scripts/spark-k8s-*.sh

# Once (or daily — token expires in 24h):
./scripts/spark-k8s-setup-auth.sh

# Optional: pre-pull image on worker nodes
export KUBECONFIG=$PWD/spark-k8s/kubeconfig.admin.yaml
kubectl apply -f spark-k8s/image-prepull-daemonset.yaml
# after images are pulled:
kubectl delete -f spark-k8s/image-prepull-daemonset.yaml

# Terminal 1 — watch pods
export KUBECONFIG=$PWD/spark-k8s/kubeconfig.admin.yaml
kubectl get pods -o wide -w

# Terminal 2 — submit (~60s observation window in the app)
./scripts/spark-k8s-submit.sh

# Cleanup demo pods
./scripts/spark-k8s-cleanup.sh
```

Expected layout while the job runs:

- **homeserver** — Spark driver pod
- **ganesh** — executor (one pod)
- **desktop-jmp9r71** — executor (one pod)

Executor anti-affinity is defined in `executor-pod-template.yaml`.
