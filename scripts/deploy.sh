#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Print colored message
print_message() {
    echo -e "${2}${1}${NC}"
}

# Check if AWS credentials are configured
check_aws_credentials() {
    print_message "Checking AWS credentials..." "${YELLOW}"
    if ! aws sts get-caller-identity &>/dev/null; then
        print_message "AWS credentials not configured. Please run 'aws configure' first." "${RED}"
        exit 1
    fi
    print_message "AWS credentials verified." "${GREEN}"
}

# Initialize and apply Terraform
setup_infrastructure() {
    print_message "Setting up infrastructure with Terraform..." "${YELLOW}"
    cd ../terraform

    print_message "Initializing Terraform..." "${YELLOW}"
    terraform init

    print_message "Validating Terraform configuration..." "${YELLOW}"
    terraform validate

    print_message "Applying Terraform configuration..." "${YELLOW}"
    terraform apply -auto-approve

    print_message "Infrastructure setup complete." "${GREEN}"
    
    # Get EKS cluster name
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    
    # Update kubeconfig
    print_message "Updating kubeconfig..." "${YELLOW}"
    aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-1
    
    cd ..
}

# Deploy Jenkins
deploy_jenkins() {
    print_message "Deploying Jenkins..." "${YELLOW}"
    
    # Create Jenkins namespace and deploy Jenkins
    kubectl apply -f kubernetes/jenkins-deployment.yaml
    
    # Wait for Jenkins pod to be ready
    print_message "Waiting for Jenkins pod to be ready..." "${YELLOW}"
    kubectl wait --namespace jenkins \
        --for=condition=ready pod \
        --selector=app=jenkins \
        --timeout=300s
    
    # Get Jenkins admin password
    print_message "Getting Jenkins admin password..." "${YELLOW}"
    POD_NAME=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath="{.items[0].metadata.name}")
    JENKINS_PASSWORD=$(kubectl exec -n jenkins $POD_NAME -- cat /var/jenkins_home/secrets/initialAdminPassword)
    
    print_message "Jenkins initial admin password: $JENKINS_PASSWORD" "${GREEN}"
    
    # Get Jenkins URL
    JENKINS_URL=$(kubectl get svc -n jenkins jenkins -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
    print_message "Jenkins URL: http://$JENKINS_URL" "${GREEN}"
}

# Deploy Weather Service
deploy_weather_service() {
    print_message "Deploying Weather Service..." "${YELLOW}"
    
    # Build and push Docker image
    cd ../microservice
    
    # Get ECR repository URL from Terraform output
    ECR_REPO=$(terraform output -raw ecr_repository_url)
    
    # Build and push Docker image
    docker build -t weather-service .
    docker tag weather-service:latest $ECR_REPO:latest
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO
    docker push $ECR_REPO:latest
    
    # Deploy to Kubernetes
    kubectl apply -f ../kubernetes/weather-service.yaml
    
    # Wait for deployment
    kubectl wait --namespace weather-service \
        --for=condition=available deployment/weather-service \
        --timeout=300s
    
    # Get service URL
    SERVICE_URL=$(kubectl get svc -n weather-service weather-service -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
    print_message "Weather Service URL: http://$SERVICE_URL" "${GREEN}"
    
    cd ..
}

# Main deployment process
main() {
    print_message "Starting deployment process..." "${YELLOW}"
    
    # Check prerequisites
    check_aws_credentials
    
    # Setup infrastructure
    setup_infrastructure
    
    # Deploy applications
    deploy_jenkins
    deploy_weather_service
    
    print_message "Deployment completed successfully!" "${GREEN}"
    print_message "Please save the Jenkins admin password and URLs shown above." "${YELLOW}"
}

# Run main function
main
