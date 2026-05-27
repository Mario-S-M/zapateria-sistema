pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([file(credentialsId: 'zapateria-env-file', variable: 'ENV_FILE')]) {
                    sh '''
                        docker compose --env-file "$ENV_FILE" down --remove-orphans
                        docker compose --env-file "$ENV_FILE" up -d --build
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                withCredentials([file(credentialsId: 'zapateria-env-file', variable: 'ENV_FILE')]) {
                    sh '''
                        echo "Esperando que el backend levante..."
                        sleep 15
                        docker compose --env-file "$ENV_FILE" ps
                        docker compose --env-file "$ENV_FILE" logs --tail=20 backend
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Deploy exitoso en rama ${env.BRANCH_NAME}"
        }
        failure {
            withCredentials([file(credentialsId: 'zapateria-env-file', variable: 'ENV_FILE')]) {
                sh 'docker compose --env-file "$ENV_FILE" logs --tail=50 || true'
            }
            echo "Deploy fallido. Revisa los logs arriba."
        }
    }
}
