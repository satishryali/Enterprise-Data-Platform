#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "${1:-$(dirname "$0")/..}" && pwd)"
PROJECT="edp-ci-$(id -u)-$$"
export CI_UID="$(id -u)" CI_GID="$(id -g)"
mkdir -p "$ROOT/artifacts/dbt/ci"
compose=(docker compose --project-name "$PROJECT" --project-directory "$ROOT"
    --env-file /dev/null -f "$ROOT/jenkins/compose.ci.yml")

cleanup() {
    status=$?
    trap - EXIT
    # This uniquely named disposable project never includes the lab stack.
    if ! "${compose[@]}" down --volumes --remove-orphans --timeout 10; then
        echo "Failed to clean up disposable project $PROJECT" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
"${compose[@]}" up --detach --wait --wait-timeout 90 postgres
"${compose[@]}" run --rm --no-deps dbt debug --profiles-dir /profiles --target ci
"${compose[@]}" run --rm --no-deps dbt build --profiles-dir /profiles --target ci
