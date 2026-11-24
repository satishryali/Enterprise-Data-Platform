#!/usr/bin/env bash
set -euo pipefail

# Run any dbt command in Docker against lab Postgres.
# Examples:
#   scripts/dbt.sh debug
#   scripts/dbt.sh build
#   scripts/dbt.sh run --select stg_employees
#   scripts/dbt.sh test

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
COMPOSE_FILE="$ROOT/compose/docker-compose.yml"
TARGET="${DBT_TARGET:-lab}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — copy .env.example to .env" >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx edp-postgres; then
  echo "edp-postgres is not running. Start the lab: scripts/lab.sh up" >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: scripts/dbt.sh <dbt-args...>" >&2
  echo "Example: scripts/dbt.sh build --target $TARGET" >&2
  exit 1
fi

docker compose -p edp --project-directory "$ROOT" --env-file "$ENV_FILE" \
  -f "$COMPOSE_FILE" --profile tools \
  run --rm --no-deps dbt "$@" --target "$TARGET"
