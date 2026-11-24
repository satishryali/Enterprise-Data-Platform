#!/usr/bin/env bash
# Apply only after committing and publishing the reviewed pipeline to main.
set -euo pipefail
set +x
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JENKINS_URL="${JENKINS_URL:-http://127.0.0.1:8082}"
JENKINS_URL="${JENKINS_URL%/}"
: "${JENKINS_USER:?Set your Jenkins username}"
: "${JENKINS_API_TOKEN:?Set a Jenkins API token (not an SSH passphrase)}"
[[ "$JENKINS_USER" =~ ^[a-zA-Z0-9_.@-]+$ && "$JENKINS_API_TOKEN" =~ ^[a-zA-Z0-9]+$ ]] || {
    echo 'Unexpected Jenkins username or token format.' >&2; exit 1;
}
[[ -z "$(git -C "$ROOT" status --porcelain)" ]] || {
    echo 'Commit and publish the reviewed changes before enabling the job.' >&2; exit 1;
}
PUBLISHED="$(GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/satishryali/Enterprise-Data-Platform.git refs/heads/main | cut -f1)"
[[ "$(git -C "$ROOT" rev-parse HEAD)" == "$PUBLISHED" ]] || {
    echo 'Local HEAD does not match published main. Reconcile/publish without force-pushing.' >&2; exit 1;
}
# Pass credentials through stdin rather than command-line arguments or files.
api() {
    printf 'user = "%s:%s"\n' "$JENKINS_USER" "$JENKINS_API_TOKEN" |
        curl --config - --silent --show-error --connect-timeout 5 --max-time 30 "$@"
}
validation="$(api --fail --form "jenkinsfile=<$ROOT/Jenkinsfile" "$JENKINS_URL/pipeline-model-converter/validate")"
[[ "$validation" == *'Jenkinsfile successfully validated.'* ]] || {
    printf '%s\n' "$validation" >&2; exit 1;
}
mkdir -p "$ROOT/artifacts/jenkins"
umask 077
status="$(api -o "$ROOT/artifacts/jenkins/job-before.xml" -w '%{http_code}' "$JENKINS_URL/job/Enterprise-Data-Platform/config.xml")"
case "$status" in
    200) endpoint="$JENKINS_URL/job/Enterprise-Data-Platform/config.xml" ;;
    404) endpoint="$JENKINS_URL/createItem?name=Enterprise-Data-Platform" ;;
    *) echo "Cannot read Jenkins job (HTTP $status). No changes applied." >&2; exit 1 ;;
esac
# Jenkins API-token authentication is exempt from CSRF crumbs.
api --fail -X POST -H 'Content-Type: application/xml' --data-binary "@$ROOT/jenkins/job.xml" "$endpoint"
printf '\nJob configured: %s/job/Enterprise-Data-Platform/\n' "$JENKINS_URL"
echo 'No build was triggered. Run a CI-only build first.'
