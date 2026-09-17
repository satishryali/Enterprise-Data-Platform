#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
COMPOSE_FILE="$ROOT/compose/docker-compose.yml"

usage() {
  cat <<'EOF'
Usage: scripts/lab.sh <command>

  up       Start lab (Postgres + Airflow + Oracle)
  down     Stop lab (keeps data)
  status   Containers and RAM
  dbt      dbt debug + build
EOF
}

compose() {
  docker compose -p edp --project-directory "$ROOT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

cmd="${1:-}"
case "$cmd" in
  up) compose --profile airflow --profile oracle up -d ;;
  down) compose --profile airflow --profile oracle --profile tools down ;;
  status)
    compose --profile airflow --profile oracle ps
    docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' | head -20
    ;;
  dbt) "$ROOT/scripts/ci_dbt.sh" "$ROOT" ;;
  *) usage; exit 1 ;;
esac
