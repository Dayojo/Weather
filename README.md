# Weather
Terraform_EKS

# Infrastructure Project

This repository follows a step-by-step implementation of infrastructure and microservices.

## Step 1: Git Repository and Branch Setup

```bash
git init my-iac-k8s-project
cd my-iac-k8s-project
git checkout -b feature/project-init
```

## Step 2: Infrastructure as Code with Terraform

### AWS Provider Configuration
- Region: us-east-1
- Provider version: ~> 4.0
- Backend: local state file

### VPC Configuration
- CIDR: 10.0.0.0/16
- Public and Private Subnets
- NAT Gateway enabled

## Step 3: Kubernetes Cluster (EKS)

- Cluster Version: 1.27
- Node Group Configuration:
  - Instance Type: t3.medium
  - Min Size: 1
  - Max Size: 3
  - Desired Size: 2

## Step 4: Jenkins on Kubernetes

- Namespace: jenkins
- Persistent Volume: 10Gi
- Service Type: LoadBalancer
- Resource Limits:
  - CPU: 2
  - Memory: 2Gi

## Step 5: Weather Microservice

### Components
- Flask REST API
- Docker containerization
- Kubernetes deployment
- Auto-scaling configuration

### API Endpoints
- GET /weather?location={city}
- GET /health

## Step 6: Automation

Deployment script handles:
- Infrastructure provisioning
- Kubernetes cluster setup
- Jenkins deployment
- Microservice deployment

## Repository Structure
```
project2/
├── terraform/
│   ├── providers.tf      # AWS provider configuration
│   ├── main.tf          # VPC and EKS configuration
│   ├── variables.tf     # Variable definitions
│   └── outputs.tf       # Output configurations
├── kubernetes/
│   ├── jenkins-deployment.yaml
│   └── weather-service.yaml
├── microservice/
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── Jenkinsfile
└── scripts/
    └── deploy.sh
```

## GitHub Repository
[https://github.com/Dayojo/project2](https://github.com/Dayojo/project2)

## Deployment Instructions

1. Clone the repository:
```bash
git clone https://github.com/Dayojo/project2.git
cd project2
```

2. Run the deployment script:
```bash
./scripts/deploy.sh
```

The script will execute all steps in sequence and provide necessary outputs and credentials.

