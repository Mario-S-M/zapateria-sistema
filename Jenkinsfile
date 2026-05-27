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
                        cp $ENV_FILE .env
                        docker compose down --remove-orphans
                        docker compose up -d --build
                        rm -f .env
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Esperando que el backend levante..."
                    sleep 15
                    docker compose ps
                    docker compose logs --tail=20 backend
                '''
            }
        }
    }

    post {
        success {
            echo "Deploy exitoso en rama ${env.BRANCH_NAME}"
        }
        failure {
            sh 'docker compose logs --tail=50 || true'
            echo "Deploy fallido. Revisa los logs arriba."
        }
    }
}
