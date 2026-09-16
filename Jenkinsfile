pipeline {
    agent any

    parameters {
        booleanParam(
            name: 'DEPLOY_PROD',
            defaultValue: false,
            description: 'Deploy this Git commit into the isolated PROD stack (starts PROD Postgres, then dbt)'
        )
    }

    environment {
        LAB_DIR = '/home/satish/Enterprise-Data-Platform'
        PROD_ROOT = '/mnt/storage/import/edp-prod/release'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Python checks') {
            steps {
                sh '''
                    python3 -m py_compile src/main.py src/csv_reader.py
                    test -f data/input/employees.csv
                '''
            }
        }

        stage('DEV ingest + dbt') {
            steps {
                sh '''
                    chmod +x scripts/*.sh
                    scripts/load_raw.sh dev "$WORKSPACE/data/input/employees.csv"
                    scripts/ci_dbt.sh dev "$WORKSPACE"
                '''
            }
        }

        stage('Deploy PROD from Git') {
            when {
                expression { params.DEPLOY_PROD == true || params.DEPLOY_PROD == 'true' }
            }
            steps {
                input message: 'Deploy this commit to isolated PROD? This does not copy data from DEV.'
                sh '''
                    mkdir -p "$PROD_ROOT"
                    rsync -a --delete \
                      --exclude '.git/' \
                      --exclude '.venv/' \
                      --exclude 'dbt/target/' \
                      --exclude 'dbt/logs/' \
                      --exclude 'airflow/logs/' \
                      "$WORKSPACE/" "$PROD_ROOT/"
                    docker compose -p edp-prod \
                      --env-file "$LAB_DIR/environments/prod/.env" \
                      -f "$LAB_DIR/compose/docker-compose.yml" \
                      up -d postgres
                    for i in $(seq 1 30); do
                      docker exec edp-prod-postgres pg_isready -U postgres && break
                      sleep 2
                    done
                    scripts/load_raw.sh prod "$PROD_ROOT/data/input/employees.csv"
                    scripts/ci_dbt.sh prod "$PROD_ROOT"
                '''
            }
        }
    }
}
