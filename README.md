# Infrastructure Project Documentation

## Step-by-Step Configuration Guide

### Step 1: Project Setup and AWS Configuration

1. First, ensure AWS CLI is installed and configured:
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

2. Install required tools:
```bash
# Install Terraform
brew install terraform

# Install kubectl
brew install kubectl

# Install AWS CLI
brew install awscli
```

### Step 2: Terraform Configuration

1. Create `providers.tf`:
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

2. Create `variables.tf`:
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

3. Create `main.tf`:
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

4. Initialize and apply Terraform:
```bash
terraform init
terraform plan
terraform apply
```

### Step 3: Kubernetes Configuration

1. Update kubeconfig:
```bash
aws eks update-kubeconfig --name weather-app-cluster --region us-east-1
```

2. Create `kubernetes/jenkins-deployment.yaml`:
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

3. Deploy Jenkins:
```bash
kubectl apply -f kubernetes/jenkins-deployment.yaml
```

### Step 4: Weather Service Configuration

1. Create `microservice/app.py`:
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

2. Create `microservice/requirements.txt`:
```
Flask==2.3.3
requests==2.31.0
gunicorn==21.2.0
```

3. Create `microservice/Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

4. Create `kubernetes/weather-service.yaml`:
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

1. Create `microservice/Jenkinsfile`:
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

### Step 6: Deployment Script

1. Create `scripts/deploy.sh`:
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

2. Make the script executable:
```bash
chmod +x scripts/deploy.sh
```

### Step 7: Running the Project

1. Deploy everything:
```bash
./scripts/deploy.sh
```

2. Get service URLs:
```bash
# Get Jenkins URL
kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get Weather Service URL
kubectl get svc weather-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

3. Test the weather service:
```bash
curl "http://[WEATHER_SERVICE_URL]/weather?location=London"
```

### Step 8: Cleanup

To destroy all resources:
```bash
terraform destroy -auto-approve
```

## Project Structure
```
project2/
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   └── main.tf
├── kubernetes/
│   ├── jenkins-deployment.yaml
│   └── weather-service.yaml
├── microservice/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── Jenkinsfile
└── scripts/
    └── deploy.sh
```

## Reference Documentation
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Flask Documentation](https://flask.palletsprojects.com/)

## GitHub Repository
[https://github.com/Dayojo/Weather](https://github.com/Dayojo/Weather)
