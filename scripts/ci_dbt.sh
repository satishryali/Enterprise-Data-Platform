#!/usr/bin/env bash
set -euo pipefail

CODE_ROOT="${1:-$(pwd)}"
ROOT="${LAB_DIR:-/home/satish/Enterprise-Data-Platform}"
ENV_FILE="${ENV_FILE:-$ROOT/.env}"
COMPOSE_FILE="$ROOT/compose/docker-compose.yml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

if [[ ! -d "$CODE_ROOT/dbt" ]]; then
  echo "No dbt project at $CODE_ROOT/dbt" >&2
  exit 1
fi

compose=(
  docker compose -p edp --project-directory "$ROOT" --env-file "$ENV_FILE" -f "$COMPOSE_FILE" --profile tools
)

"${compose[@]}" run --rm --no-deps dbt debug --target lab
"${compose[@]}" run --rm --no-deps dbt build --target lab
