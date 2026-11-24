#!/usr/bin/env bash
set -euo pipefail
# Never source a credentials file as executable shell code or enable tracing.
set +x

die() { echo "$*" >&2; exit 1; }

env_value() {
    local file="$1" key="$2"
    awk -v key="$key" '
        { sub(/\r$/, "") }
        index($0, key "=") == 1 { value = substr($0, length(key) + 2); count++ }
        END { if (count != 1 || value == "") exit 1; print value }
    ' "$file"
}

validate_env() {
    local file="$1" key value port
    [[ -f "$file" && -r "$file" ]] || die 'Database credentials file is missing or unreadable.'
    for key in DBT_HOST DBT_PORT DBT_DBNAME DBT_USER DBT_PASSWORD; do
        value="$(env_value "$file" "$key")" || die "Set exactly one nonempty $key in the credentials file."
        [[ "$value" != \"* && "$value" != \'* ]] || die "Use unquoted KEY=value entries for $key."
    done
    port="$(env_value "$file" DBT_PORT)"
    [[ "$port" =~ ^[0-9]{1,5}$ ]] || die 'DBT_PORT must be a TCP port.'
    (( 10#$port > 0 && 10#$port <= 65535 )) || die 'DBT_PORT is out of range.'
}

TARGET="${1:-}"
if [[ "$TARGET" == check-isolation ]]; then
    [[ $# -eq 3 ]] || die 'Usage: deploy_dbt.sh check-isolation <dev-env-file> <prod-env-file>'
    validate_env "$2"
    validate_env "$3"
    [[ "$(env_value "$2" DBT_DBNAME)" != "$(env_value "$3" DBT_DBNAME)" ]] ||
        die 'DEV and PROD must use different database names; promotion refused.'
    echo 'DEV and PROD database isolation: OK'
    exit 0
fi

[[ "$TARGET" == dev || "$TARGET" == prod ]] || die 'Usage: deploy_dbt.sh <dev|prod> <env-file> [workspace]'
[[ $# -ge 2 && $# -le 3 ]] || die 'A database credentials file is required.'
ENV_FILE="$2"
validate_env "$ENV_FILE"
ROOT="$(cd "${3:-$(dirname "$0")/..}" && pwd)"
ARTIFACTS="$ROOT/artifacts/dbt/$TARGET"
mkdir -p "$ARTIFACTS"
docker_args=(run --rm --network "${DBT_DOCKER_NETWORK:-host}" --user "$(id -u):$(id -g)"
    --env-file "$ENV_FILE" --env HOME=/tmp
    --env DBT_TARGET_PATH=/artifacts/target --env DBT_LOG_PATH=/artifacts/logs
    --env DBT_SEND_ANONYMOUS_USAGE_STATS=false
    --mount "type=bind,src=$ROOT/dbt,dst=/usr/app,readonly"
    --mount "type=bind,src=$ROOT/jenkins/profiles.yml,dst=/profiles/profiles.yml,readonly"
    --mount "type=bind,src=$ARTIFACTS,dst=/artifacts"
    --workdir /usr/app "${DBT_IMAGE:-ghcr.io/dbt-labs/dbt-postgres:1.9.latest}")
docker "${docker_args[@]}" debug --profiles-dir /profiles --target "$TARGET"
docker "${docker_args[@]}" build --profiles-dir /profiles --target "$TARGET"
