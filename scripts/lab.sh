#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
COMPOSE=(docker compose --env-file "$ROOT/.env" -f "$ROOT/docker-compose.yml")

usage() {
  cat <<'EOF'
Usage: scripts/lab.sh <command>

  up          Start core stack (Postgres + Airflow LocalExecutor)
  down        Stop core stack (keeps warehouse data)
  status      Show compose + resource snapshot
  dbt-dev     dbt build --target dev
  dbt-stg     dbt build --target stg
  dbt-prod    dbt build --target prod
  jupyter     Start Jupyter (on-demand)
  jupyter-off Stop Jupyter
EOF
}

cmd="${1:-}"
case "$cmd" in
  up) "${COMPOSE[@]}" up -d postgres airflow-init
      "${COMPOSE[@]}" up -d airflow-apiserver airflow-scheduler airflow-dag-processor airflow-triggerer
      ;;
  down) "${COMPOSE[@]}" down ;;
  status) "${COMPOSE[@]}" ps
          docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' | head -20
          ;;
  dbt-dev) "${COMPOSE[@]}" --profile tools run --rm dbt build --target dev ;;
  dbt-stg) "${COMPOSE[@]}" --profile tools run --rm dbt build --target stg ;;
  dbt-prod) "${COMPOSE[@]}" --profile tools run --rm dbt build --target prod ;;
  jupyter) "${COMPOSE[@]}" --profile jupyter up -d jupyter ;;
  jupyter-off) "${COMPOSE[@]}" --profile jupyter stop jupyter ;;
  *) usage; exit 1 ;;
esac
