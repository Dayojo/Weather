# Infrastructure as Code with Kubernetes Project

This repository contains Infrastructure as Code (IaC) implementation using Terraform, Kubernetes, and Jenkins for deploying a weather microservice.

## Project Structure

```
project2/
├── terraform/
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
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

## Step-by-Step Implementation

### 1. Infrastructure Setup
- VPC creation with public and private subnets
- EKS cluster deployment
- Security group configurations

### 2. Kubernetes Configuration
- EKS cluster setup
- Jenkins deployment on Kubernetes
- Weather service deployment

### 3. CI/CD Pipeline
- Jenkins installation and configuration
- Pipeline setup for weather microservice
- Automated deployment process

### 4. Microservice
- Weather service API implementation
- Containerization with Docker
- Kubernetes deployment configuration

## Prerequisites

- AWS CLI configured
- Terraform installed
- kubectl installed
- Helm installed
- Docker installed

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/Dayojo/project2.git
cd project2
```

2. Initialize Terraform:
```bash
cd terraform
terraform init
```

3. Deploy infrastructure:
```bash
terraform apply
```

4. Configure kubectl:
```bash
aws eks update-kubeconfig --name k8s-cluster --region us-east-1
```

5. Deploy Jenkins:
```bash
kubectl apply -f kubernetes/jenkins-deployment.yaml
```

6. Deploy the weather service:
```bash
kubectl apply -f kubernetes/weather-service.yaml
```

## Architecture

- AWS VPC with public and private subnets
- EKS cluster for Kubernetes workloads
- Jenkins for CI/CD pipeline
- Weather microservice deployed as containers
- Load balancer for external access

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Your Name - [@Dayojo](https://github.com/Dayojo)

Project Link: [https://github.com/Dayojo/project2](https://github.com/Dayojo/project2)
