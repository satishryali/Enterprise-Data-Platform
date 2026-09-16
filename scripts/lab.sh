#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE_FILE="$ROOT/compose/docker-compose.yml"
dev_env="$ROOT/environments/dev/.env"
prod_env="$ROOT/environments/prod/.env"
oracle_override="$ROOT/compose/docker-compose.oracle.yml"

usage() {
  cat <<'EOF'
Usage: scripts/lab.sh <command>

  up            Start DEV only (Postgres + Airflow + Oracle)
  down          Stop DEV (keeps data)
  status        Show DEV/PROD containers and RAM
  dbt-dev       dbt build against DEV
  prod-up       Start PROD Postgres only
  prod-down     Stop PROD (uses no RAM after this)
  dbt-prod      dbt build against PROD
EOF
}

dev_compose() {
  docker compose -p edp-dev --env-file "$dev_env" -f "$COMPOSE_FILE" -f "$oracle_override" "$@"
}

prod_compose() {
  docker compose -p edp-prod --env-file "$prod_env" -f "$COMPOSE_FILE" "$@"
}

cmd="${1:-}"
case "$cmd" in
  up) dev_compose --profile airflow --profile oracle up -d ;;
  down) dev_compose --profile airflow --profile oracle --profile tools down ;;
  status)
    echo '=== DEV ==='
    dev_compose --profile airflow --profile oracle ps
    echo '=== PROD ==='
    prod_compose ps
    echo '=== RAM ==='
    docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'
    ;;
  dbt-dev)
    CODE_ROOT="$ROOT" "$ROOT/scripts/ci_dbt.sh" dev "$ROOT"
    ;;
  prod-up) prod_compose up -d postgres ;;
  prod-down) prod_compose --profile airflow --profile tools down ;;
  dbt-prod)
    prod_compose up -d postgres
    CODE_ROOT="$ROOT" "$ROOT/scripts/ci_dbt.sh" prod "$ROOT"
    ;;
  *) usage; exit 1 ;;
esac
