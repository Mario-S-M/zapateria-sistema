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
                        docker compose --env-file "$ENV_FILE" down --remove-orphans || true
                        docker rm -f zapateria_postgres zapateria_backend zapateria_web 2>/dev/null || true
                        docker ps -q --filter "publish=8090" | xargs -r docker rm -f || true
                        docker ps -q --filter "publish=3000" | xargs -r docker rm -f || true
                        docker ps -q --filter "publish=5432" | xargs -r docker rm -f || true
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
