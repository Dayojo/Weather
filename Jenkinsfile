# Jenkins Pipeline Configuration
# This file defines the CI/CD pipeline stages for the weather service:
# 1. Build: Install dependencies
# 2. Test: Run tests (placeholder for now)
# 3. Docker: Build and push Docker image
# 4. Deploy: Deploy to Kubernetes

pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'dayojo/weather-service'
        DOCKER_TAG = 'latest'
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'pip install -r app/requirements.txt'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                // Placeholder for future test implementation
                // sh 'python -m pytest tests/'
            }
        }
        
        stage('Docker Build and Push') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    docker.withRegistry('', 'docker-hub-credentials') {
                        docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh 'kubectl apply -f deployment.yaml'
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
