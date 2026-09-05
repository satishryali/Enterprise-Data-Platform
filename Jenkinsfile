pipeline {
    agent any

    stages {
        stage('Checkout Verification') {
            steps {
                echo 'Enterprise Data Platform CI/CD pipeline started'
                sh 'git status'
            }
        }

        stage('Application Test') {
            steps {
                sh 'python3 src/main.py'
            }
        }
    }
}
