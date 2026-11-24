pipeline {
    agent { label 'platform-agent' }

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timeout(time: 45, unit: 'MINUTES')
    }

    parameters {
        booleanParam(name: 'DEPLOY_DEV', defaultValue: false,
                     description: 'Build the checked-out models in DEV after CI succeeds.')
        booleanParam(name: 'DEPLOY_PROD', defaultValue: false,
                     description: 'Build in DEV, then promote the same commit and dbt image directly to PROD.')
    }

    triggers { pollSCM('H/5 * * * *') }

    environment {
        DBT_IMAGE_TAG = 'ghcr.io/dbt-labs/dbt-postgres:1.9.latest'
        DEV_CREDENTIALS_ID = 'edp-dev-env'
        PROD_CREDENTIALS_ID = 'edp-prod-env'
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Preflight') {
            steps {
                sh '''#!/usr/bin/env bash
set -euo pipefail
command -v python3
command -v docker
docker compose version
timeout 20s docker info >/dev/null
mkdir -p artifacts
if [[ "$DEPLOY_DEV" == true || "$DEPLOY_PROD" == true ]]; then
    test "$(git rev-parse HEAD)" = "$(git rev-parse refs/remotes/origin/main)" || {
        echo 'Deployments must use the main branch checkout.' >&2
        exit 1
    }
fi
'''
                script {
                    // Resolve the mutable tag once; CI, DEV and PROD use this exact image.
                    env.DBT_IMAGE = sh(returnStdout: true, script: '''
                        set -eu
                        docker pull "$DBT_IMAGE_TAG" >&2
                        docker image inspect --format '{{index .RepoDigests 0}}' "$DBT_IMAGE_TAG"
                    ''').trim()
                }
                sh '''
                    git rev-parse HEAD > artifacts/commit.txt
                    printf '%s\n' "$DBT_IMAGE" > artifacts/dbt-image.txt
                '''
            }
        }

        stage('Checks and unit tests') {
            steps {
                sh '''#!/usr/bin/env bash
set -euo pipefail
for script in scripts/*.sh tests/test_pipeline.sh tests/fixtures/docker; do
    bash -n "$script"
done
python3 -m py_compile src/main.py src/csv_reader.py
python3 -m venv .venv-ci
.venv-ci/bin/python -m pip install -r requirements.txt
.venv-ci/bin/python -m pytest -q tests --junitxml=artifacts/pytest.xml
bash tests/test_pipeline.sh
'''
            }
        }

        stage('Isolated dbt integration tests') {
            steps { sh 'bash scripts/validate_dbt.sh "$WORKSPACE"' }
        }

        stage('Check environment isolation') {
            when { expression { params.DEPLOY_PROD } }
            steps {
                withCredentials([
                    file(credentialsId: env.DEV_CREDENTIALS_ID, variable: 'DEV_ENV_FILE'),
                    file(credentialsId: env.PROD_CREDENTIALS_ID, variable: 'PROD_ENV_FILE')
                ]) {
                    sh 'bash scripts/deploy_dbt.sh check-isolation "$DEV_ENV_FILE" "$PROD_ENV_FILE"'
                }
            }
        }

        stage('Deploy DEV') {
            when { expression { params.DEPLOY_DEV || params.DEPLOY_PROD } }
            steps {
                withCredentials([file(credentialsId: env.DEV_CREDENTIALS_ID, variable: 'DBT_ENV_FILE')]) {
                    sh 'bash scripts/deploy_dbt.sh dev "$DBT_ENV_FILE" "$WORKSPACE"'
                }
            }
        }

        stage('Promote DEV to PROD') {
            when { expression { params.DEPLOY_PROD } }
            steps {
                withCredentials([file(credentialsId: env.PROD_CREDENTIALS_ID, variable: 'DBT_ENV_FILE')]) {
                    sh 'bash scripts/deploy_dbt.sh prod "$DBT_ENV_FILE" "$WORKSPACE"'
                }
            }
        }
    }

    post {
        always {
            junit testResults: 'artifacts/pytest.xml', allowEmptyResults: true
            archiveArtifacts artifacts: 'artifacts/commit.txt,artifacts/dbt-image.txt,artifacts/dbt/**/target/manifest.json,artifacts/dbt/**/target/run_results.json',
                             allowEmptyArchive: true
        }
    }
}
