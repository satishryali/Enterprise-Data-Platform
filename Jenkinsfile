pipeline {
    agent any

    environment {
        LAB_DIR = '/home/satish/Enterprise-Data-Platform'
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

        stage('Ingest + dbt') {
            steps {
                sh '''
                    chmod +x scripts/*.sh
                    scripts/load_raw.sh "$WORKSPACE/data/input/employees.csv"
                    if [ -f "$WORKSPACE/data/input/orders.csv" ]; then
                      scripts/load_orders.sh "$WORKSPACE/data/input/orders.csv"
                    fi
                    scripts/ci_dbt.sh "$WORKSPACE"
                '''
            }
        }
    }
}
