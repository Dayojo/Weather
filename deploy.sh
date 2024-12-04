#!/bin/bash
# Deployment automation script for Weather Service
# This script automates the deployment process by:
# 1. Initializing and applying Terraform configuration
# 2. Building and pushing Docker image
# 3. Deploying the application to Kubernetes

set -e

echo "Starting deployment process..."

# Initialize and apply Terraform
echo "Initializing Terraform..."
terraform init

echo "Applying Terraform configuration..."
terraform apply -auto-approve

# Configure kubectl
echo "Configuring kubectl..."
aws eks update-kubeconfig --name weather-cluster --region us-east-1

# Build and push Docker image
echo "Building Docker image..."
docker build -t dayojo/weather-service:latest .

echo "Pushing Docker image..."
docker push dayojo/weather-service:latest

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f deployment.yaml

# Wait for deployment
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/weather-service

echo "Deployment complete! Use kubectl get svc weather-service to get the LoadBalancer URL"
