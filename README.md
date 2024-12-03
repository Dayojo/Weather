# Infrastructure Project Documentation

## Project Overview
This project implements a weather service using modern infrastructure practices. It includes:
- Infrastructure as Code using Terraform
- Containerized applications using Docker
- Orchestration using Kubernetes
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

The Terraform configuration is split into multiple files for better organization and maintainability.

#### providers.tf
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
      version = "~> 4.0"
    }
  }
}
```

#### variables.tf
This file defines variables used throughout the Terraform configuration, making it easier to modify common values.

**Resource Links:**
- [Terraform Variables](https://www.terraform.io/docs/language/values/variables.html)
- [Variable Validation](https://www.terraform.io/docs/language/values/variables.html#custom-validation-rules)

```hcl
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "weather-app-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
```

#### main.tf
This file contains the main infrastructure configuration, including VPC and EKS cluster setup.

**Resource Links:**
- [VPC Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
- [EKS Module Documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [AWS VPC Architecture](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Scenarios.html)

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "eks-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true
  
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

### Step 3: Kubernetes Configuration

#### jenkins-deployment.yaml
This file defines the Kubernetes resources needed for Jenkins deployment, including namespace, persistent volume, deployment, and service.

**Resource Links:**
- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pv-claim
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp2

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pv-claim

---
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: jenkins
```

### Step 4: Weather Service Configuration

#### app.py
This file contains the Flask application code for the weather service. It provides a RESTful API endpoint for weather information.

**Resource Links:**
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Open-Meteo API](https://open-meteo.com/en/docs)
- [Python Requests Library](https://docs.python-requests.org/en/latest/)

```python
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

@app.route('/weather', methods=['GET'])
def get_weather():
    location = request.args.get('location')
    if not location:
        return jsonify({'error': 'Location parameter is required'}), 400

    api_url = f"https://api.open-meteo.com/v1/forecast"
    params = {
        'latitude': 0,
        'longitude': 0,
        'current_weather': True
    }

    try:
        # Get coordinates
        geo_url = f"https://nominatim.openstreetmap.org/search?q={location}&format=json"
        geo_response = requests.get(geo_url)
        geo_data = geo_response.json()

        if not geo_data:
            return jsonify({'error': 'Location not found'}), 404

        params['latitude'] = float(geo_data[0]['lat'])
        params['longitude'] = float(geo_data[0]['lon'])

        # Get weather
        weather_response = requests.get(api_url, params=params)
        return jsonify(weather_response.json())

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

#### Dockerfile
This file defines how to build the weather service container image.

**Resource Links:**
- [Docker Documentation](https://docs.docker.com/)
- [Python Docker Official Image](https://hub.docker.com/_/python)
- [Docker Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

#### weather-service.yaml
This file defines the Kubernetes deployment and service for the weather application.

**Resource Links:**
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: weather-service
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
        image: weather-service:latest
        ports:
        - containerPort: 5000
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "200m"
            memory: "256Mi"

---
apiVersion: v1
kind: Service
metadata:
  name: weather-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 5000
  selector:
    app: weather-service
```

### Step 5: CI/CD Pipeline Configuration

#### Jenkinsfile
This file defines the CI/CD pipeline stages and steps.

**Resource Links:**
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Jenkins Pipeline Steps](https://www.jenkins.io/doc/pipeline/steps/)
- [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)

```groovy
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'weather-service'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Build') {
            steps {
                dir('microservice') {
                    sh 'docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .'
                }
            }
        }

        stage('Test') {
            steps {
                dir('microservice') {
                    sh '''
                        python -m venv venv
                        . venv/bin/activate
                        pip install -r requirements.txt
                        python -m pytest
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    kubectl apply -f kubernetes/weather-service.yaml
                    kubectl set image deployment/weather-service weather-service=${DOCKER_IMAGE}:${DOCKER_TAG}
                '''
            }
        }
    }
}
```

### Step 6: Deployment Automation

#### deploy.sh
This script automates the entire deployment process.

**Resource Links:**
- [Bash Scripting Guide](https://tldp.org/LDP/abs/html/)
- [AWS CLI Commands](https://docs.aws.amazon.com/cli/latest/reference/)
- [kubectl Commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)

```bash
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}AWS credentials not configured${NC}"
    exit 1
fi

# Deploy infrastructure
echo "Deploying infrastructure..."
cd terraform
terraform init
terraform apply -auto-approve

# Configure kubectl
echo "Configuring kubectl..."
aws eks update-kubeconfig --name weather-app-cluster --region us-east-1

# Deploy Jenkins
echo "Deploying Jenkins..."
kubectl apply -f ../kubernetes/jenkins-deployment.yaml

# Build and deploy weather service
echo "Building weather service..."
cd ../microservice
docker build -t weather-service:latest .

echo "Deploying weather service..."
kubectl apply -f ../kubernetes/weather-service.yaml

echo -e "${GREEN}Deployment complete!${NC}"
```

## Project Structure
```
project2/
├── terraform/          # Infrastructure as Code files
│   ├── providers.tf    # AWS provider configuration
│   ├── variables.tf    # Variable definitions
│   └── main.tf        # Main infrastructure configuration
├── kubernetes/         # Kubernetes manifests
│   ├── jenkins-deployment.yaml    # Jenkins deployment configuration
│   └── weather-service.yaml       # Weather service deployment
├── microservice/       # Weather service application
│   ├── app.py         # Flask application
│   ├── requirements.txt    # Python dependencies
│   ├── Dockerfile     # Container image definition
│   └── Jenkinsfile    # CI/CD pipeline definition
└── scripts/           # Automation scripts
    └── deploy.sh      # Deployment automation script
```

## GitHub Repository
[https://github.com/Dayojo/Weather](https://github.com/Dayojo/Weather)

## Testing the Deployment

After deployment, verify the services:

1. Get Jenkins URL:
```bash
kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

2. Get Weather Service URL:
```bash
kubectl get svc weather-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

3. Test weather service:
```bash
curl "http://[WEATHER_SERVICE_URL]/weather?location=London"
```

Example Response:
```json
{
  "location": "London",
  "current_weather": {
    "temperature": 18.5,
    "precipitation": 0,
    "wind_speed": 12.3
  },
  "timestamp": "2023-09-20T14:30:00Z"
}
```

## Cleanup

To destroy all resources:
```bash
terraform destroy -auto-approve
```

This will remove all created AWS resources to prevent ongoing charges.
