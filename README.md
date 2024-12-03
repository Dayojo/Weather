# Infrastructure Project Documentation

## Project Overview
This project implements a weather service using modern infrastructure practices. It includes:
- Infrastructure as Code using Terraform
- Containerized applications using Docker
- Orchestration using Kubernetes (AWS EKS)
- CI/CD pipeline using Jenkins
- RESTful API using Flask

## Resource Documentation Links

### AWS Resources
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [AWS IAM Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)

### Terraform Resources
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [Terraform EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

### Kubernetes Resources
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

### Jenkins Resources
- [Jenkins on Kubernetes](https://www.jenkins.io/doc/book/installing/kubernetes/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Jenkins Credentials Management](https://www.jenkins.io/doc/book/using/using-credentials/)

## Step-by-Step Configuration Guide

### Step 1: Project Setup and AWS Configuration

Before starting, ensure you have the necessary tools installed and AWS configured.

#### Required Tools Installation
```bash
# Install Terraform
brew install terraform

# Install kubectl
brew install kubectl

# Install AWS CLI
brew install awscli
```

#### AWS Configuration
```bash
aws configure
```
Enter your AWS credentials:
```
AWS Access Key ID: YOUR_ACCESS_KEY
AWS Secret Access Key: YOUR_SECRET_KEY
Default region name: us-east-1
Default output format: json
```

### Step 2: Terraform Configuration

#### main.tf
This file configures the AWS provider and sets up the Terraform backend.

**Resource Links:**
- [AWS Provider Configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)
- [Terraform Backend Configuration](https://www.terraform.io/docs/language/settings/backends/index.html)

```hcl
provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75.0"
    }
  }

  backend "local" {
    path = "./terraform.tfstate"
  }
}
```

#### vpc.tf
This file defines the VPC and its associated networking components.

**Resource Links:**
- [VPC Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [AWS VPC Architecture](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenarios.html)

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "weather-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/weather-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/weather-cluster" = "shared"
  }
}
```

#### eks.tf
This file defines the EKS cluster configuration.

**Resource Links:**
- [EKS Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "weather-cluster"
  cluster_version = "1.27"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    eks_nodes = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = "dev"
      }
    }
  }

  tags = {
    Environment = "dev"
  }
}
```

### Step 3: Weather Service Configuration

#### app/app.py
This file contains the Flask application code for the weather service.

**Resource Links:**
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Open-Meteo API](https://open-meteo.com/en/docs)

```python
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

@app.route('/weather', methods=['GET'])
def get_weather():
    location = request.args.get('location')
    response = requests.get(f"https://api.open-meteo.com/v1/forecast?latitude={location}&current_weather=true")
    return jsonify(response.json())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

#### Dockerfile
This file defines how to build the weather service container image.

**Resource Links:**
- [Docker Documentation](https://docs.docker.com/)
- [Python Docker Official Image](https://hub.docker.com/_/python)

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

#### deployment.yaml
This file defines the Kubernetes deployment and service for the weather application.

**Resource Links:**
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: weather-service
  labels:
    app: weather-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: weather-service
  template:
    metadata:
      labels:
        app: weather-service
    spec:
      containers:
      - name: weather-service
        image: dayojo/weather-service:latest
        ports:
        - containerPort: 5000
        resources:
          requests:
            cpu: "250m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: weather-service
spec:
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  selector:
    app: weather-service
```

### Step 4: CI/CD Pipeline Configuration

#### Jenkinsfile
This file defines the CI/CD pipeline stages and steps.

**Resource Links:**
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Jenkins Pipeline Steps](https://www.jenkins.io/doc/pipeline/steps/)

```groovy
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
```

### Step 5: Deployment Automation

#### deploy.sh
This script automates the entire deployment process.

**Resource Links:**
- [AWS CLI Commands](https://docs.aws.amazon.com/cli/latest/reference/)
- [kubectl Commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)

```bash
#!/bin/bash

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
```

## Project Structure
```
terraform2/
├── app/
│   ├── app.py              # Flask application
│   └── requirements.txt    # Python dependencies
├── main.tf                 # Main Terraform configuration
├── vpc.tf                  # VPC configuration
├── eks.tf                  # EKS cluster configuration
├── outputs.tf             # Terraform outputs
├── variables.tf           # Terraform variables
├── Dockerfile             # Container image definition
├── deployment.yaml        # Kubernetes deployment
├── Jenkinsfile           # CI/CD pipeline
└── deploy.sh             # Deployment script
```

## Testing the Deployment

After deployment, verify the service:

1. Get Weather Service URL:
```bash
kubectl get svc weather-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

2. Test weather service:
```bash
curl "http://[WEATHER_SERVICE_URL]/weather?location=51.5074"
```

Example Response:
```json
{
  "current_weather": {
    "temperature": 18.5,
    "windspeed": 12.3,
    "weathercode": 0,
    "time": "2023-09-20T14:30"
  }
}
```

## Cleanup

To destroy all resources:
```bash
terraform destroy -auto-approve
```

This will remove all created AWS resources to prevent ongoing charges.
