pipeline {
    agent any

    parameters {
        booleanParam(
            name: 'DEPLOY_PROD',
            defaultValue: false,
            description: 'Also promote STG -> PROD after DEV and STG succeed'
        )
    }

    environment {
        LAB_DIR = '/home/satish/Enterprise-Data-Platform'
        ENV_FILE = '/home/satish/Enterprise-Data-Platform/.env'
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

        stage('Promote DEV -> STG') {
            steps {
                sh '''
                    scripts/promote_raw.sh etl_dev etl_stg
                    scripts/ci_dbt.sh stg "$WORKSPACE"
                '''
            }
        }

        stage('Promote STG -> PROD') {
            when {
                expression { params.DEPLOY_PROD == true || params.DEPLOY_PROD == 'true' }
            }
            steps {
                input message: 'Promote STG to PROD?'
                sh '''
                    scripts/promote_raw.sh etl_stg etl_prod
                    scripts/ci_dbt.sh prod "$WORKSPACE"
                '''
            }
        }
    }
}
