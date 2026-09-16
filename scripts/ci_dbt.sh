#!/usr/bin/env bash
set -euo pipefail

# Run dbt against an isolated stack.
# Usage: ci_dbt.sh <dev|prod> [code_root]

TARGET="${1:?usage: ci_dbt.sh <dev|prod> [code_root]}"
LAB_DIR="${LAB_DIR:-/home/satish/Enterprise-Data-Platform}"
CODE_ROOT="${2:-$LAB_DIR}"
ENV_FILE="${ENV_FILE:-$LAB_DIR/environments/${TARGET}/.env}"
COMPOSE_FILE="$LAB_DIR/compose/docker-compose.yml"

case "$TARGET" in
  dev|prod) ;;
  *) echo "target must be dev or prod" >&2; exit 1 ;;
esac

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  exit 1
fi

if [[ ! -d "$CODE_ROOT/dbt" ]]; then
  echo "No dbt project at $CODE_ROOT/dbt" >&2
  exit 1
fi

export CODE_ROOT

extra=()
if [[ "$TARGET" == "dev" ]]; then
  extra+=(-f "$LAB_DIR/compose/docker-compose.oracle.yml")
fi

compose=(
  docker compose
  -p "edp-${TARGET}"
  --env-file "$ENV_FILE"
  -f "$COMPOSE_FILE"
  "${extra[@]}"
  --profile tools
)

"${compose[@]}" run --rm --no-deps dbt debug --target "$TARGET"
"${compose[@]}" run --rm --no-deps dbt build --target "$TARGET"
