#!/usr/bin/env bash
set -euo pipefail

# Run dbt from a Git checkout against the already-running lab stack.
# Usage: scripts/ci_dbt.sh <dev|stg|prod> [project_dir]

TARGET="${1:?usage: ci_dbt.sh <dev|stg|prod> [project_dir]}"
PROJECT_DIR="${2:-$(pwd)}"
LAB_DIR="${LAB_DIR:-/home/satish/Enterprise-Data-Platform}"
ENV_FILE="${ENV_FILE:-$LAB_DIR/.env}"

case "$TARGET" in
  dev|stg|prod) ;;
  *) echo "target must be dev, stg, or prod" >&2; exit 1 ;;
esac

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  exit 1
fi

docker compose \
  -p enterprise-data-platform \
  --project-directory "$PROJECT_DIR" \
  --env-file "$ENV_FILE" \
  -f "$PROJECT_DIR/docker-compose.yml" \
  --profile tools \
  run --rm --no-deps \
  dbt build --target "$TARGET"
