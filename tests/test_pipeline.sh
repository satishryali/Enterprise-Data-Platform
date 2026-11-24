#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_TMP="$(mktemp -d /tmp/edp-pipeline-tests.XXXXXXXX)"
cleanup() {
    [[ "$TASK_TMP" == /tmp/edp-pipeline-tests.* ]] && rm -rf -- "$TASK_TMP"
}
trap cleanup EXIT
mkdir "$TASK_TMP/bin"
ln -s "$ROOT/tests/fixtures/docker" "$TASK_TMP/bin/docker"
export PATH="$TASK_TMP/bin:$PATH" DOCKER_CALL_LOG="$TASK_TMP/docker.log"
sed 's/^DBT_PASSWORD=$/DBT_PASSWORD=not-a-real-password/' "$ROOT/environments/dev/jenkins.env.example" > "$TASK_TMP/dev.env"
sed 's/^DBT_PASSWORD=$/DBT_PASSWORD=not-a-real-password/' "$ROOT/environments/prod/jenkins.env.example" > "$TASK_TMP/prod.env"

bash "$ROOT/scripts/deploy_dbt.sh" check-isolation "$TASK_TMP/dev.env" "$TASK_TMP/prod.env"
if bash "$ROOT/scripts/deploy_dbt.sh" check-isolation "$TASK_TMP/dev.env" "$TASK_TMP/dev.env" 2>/dev/null; then
    echo 'FAIL: promotion to the same database was allowed.' >&2
    exit 1
fi
if bash "$ROOT/scripts/deploy_dbt.sh" stage "$TASK_TMP/dev.env" "$ROOT" 2>/dev/null; then
    echo 'FAIL: unsupported target was allowed.' >&2
    exit 1
fi
if bash "$ROOT/scripts/deploy_dbt.sh" dev "$ROOT/environments/dev/jenkins.env.example" "$ROOT" 2>/dev/null; then
    echo 'FAIL: empty credentials were allowed.' >&2
    exit 1
fi
test ! -e "$DOCKER_CALL_LOG"

bash "$ROOT/scripts/deploy_dbt.sh" prod "$TASK_TMP/prod.env" "$ROOT"
grep -Fq -- "src=$ROOT/dbt,dst=/usr/app,readonly" "$DOCKER_CALL_LOG"
grep -Fq -- '--target prod' "$DOCKER_CALL_LOG"
grep -Fq -- '--env-file' "$DOCKER_CALL_LOG"
if grep -Fq -- 'not-a-real-password' "$DOCKER_CALL_LOG"; then
    echo 'FAIL: password appeared in Docker command arguments.' >&2
    exit 1
fi

: > "$DOCKER_CALL_LOG"
export FAKE_DOCKER_FAIL_ON=debug
if bash "$ROOT/scripts/deploy_dbt.sh" dev "$TASK_TMP/dev.env" "$ROOT"; then
    echo 'FAIL: failed connection check was ignored.' >&2
    exit 1
fi
if grep -Fq -- ' build ' "$DOCKER_CALL_LOG"; then
    echo 'FAIL: build ran after a failed connection check.' >&2
    exit 1
fi

: > "$DOCKER_CALL_LOG"
export FAKE_DOCKER_FAIL_ON=build
if bash "$ROOT/scripts/validate_dbt.sh" "$ROOT"; then
    echo 'FAIL: failed integration build was ignored.' >&2
    exit 1
fi
grep -Fq -- '--project-name edp-ci-' "$DOCKER_CALL_LOG"
grep -Fq -- '--env-file /dev/null' "$DOCKER_CALL_LOG"
grep -Fq -- 'down --volumes --remove-orphans' "$DOCKER_CALL_LOG"
unset FAKE_DOCKER_FAIL_ON
echo 'Pipeline orchestration checks: PASS'
