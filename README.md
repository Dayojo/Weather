# Weather
Terraform_EKS

# Infrastructure Project Documentation

## Step 1: Initialize the Git Repository and Branch

1. Initialize a New Git Repository:
```bash
git init my-iac-k8s-project
cd my-iac-k8s-project
```

Output:
```
Initialized empty Git repository in /Users/dayosasanya/Desktop/Terraform /Project1/project2/.git/
```

2. Create the First Branch:
```bash
git checkout -b feature/project-init
```

Output:
```
Switched to a new branch 'feature/project-init'
```

3. Initial Commit:
```bash
echo "# My Infrastructure Project" > README.md
git add README.md
git commit -m "Initial README file"
```

Output:
```
[feature/project-init (root-commit) e52d41e] Initial README file
1 file changed, 1 insertion(+)
create mode 100644 README.md
```

## Step 2: Infrastructure as Code with Terraform

1. Create providers.tf:
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

  backend "local" {
    path = "./terraform.tfstate"
  }
}
```

2. Create main.tf for VPC and EKS:
```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "k8s-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = "weather-service-eks"
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}
```

3. Initialize Terraform:
```bash
terraform init
```

Output:
```
Initializing modules...
Downloading terraform-aws-modules/vpc/aws...
Downloading terraform-aws-modules/eks/aws...

Initializing provider plugins...
- Initializing provider hashicorp/aws...

Terraform has been successfully initialized!
```

4. Apply Configuration:
```bash
terraform apply
```

Output:
```
Apply complete! Resources: 51 added, 0 changed, 0 destroyed.

Outputs:
cluster_endpoint = "https://xxxxx.gr7.us-east-1.eks.amazonaws.com"
cluster_name = "weather-service-eks"
```

## Step 3: Kubernetes Cluster Creation

1. Configure kubectl:
```bash
aws eks update-kubeconfig --name weather-service-eks --region us-east-1
```

Output:
```
Added new context arn:aws:eks:us-east-1:XXXXXXXXXXXX:cluster/weather-service-eks to /Users/dayosasanya/.kube/config
```

2. Verify cluster connection:
```bash
kubectl get nodes
```

Output:
```
NAME                                       STATUS   ROLES    AGE   VERSION
ip-10-0-1-100.us-east-1.compute.internal  Ready    <none>   1m    v1.27.1-eks-2f008fe
ip-10-0-2-200.us-east-1.compute.internal  Ready    <none>   1m    v1.27.1-eks-2f008fe
```

## Step 4: Jenkins Installation on Kubernetes

1. Create Jenkins namespace:
```bash
kubectl create namespace jenkins
```

Output:
```
namespace/jenkins created
```

2. Apply Jenkins deployment:
```bash
kubectl apply -f kubernetes/jenkins-deployment.yaml
```

Output:
```
serviceaccount/jenkins created
clusterrole.rbac.authorization.k8s.io/jenkins-admin created
clusterrolebinding.rbac.authorization.k8s.io/jenkins-admin created
persistentvolumeclaim/jenkins-pv-claim created
deployment.apps/jenkins created
service/jenkins created
```

3. Get Jenkins admin password:
```bash
kubectl exec -n jenkins $(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Output:
```
2a8e2de6a1b5449a8e8e8e8e8e8e8e8e
```

## Step 5: Microservice Development

1. Create and test the weather service:
```bash
cd microservice
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

Output:
```
* Serving Flask app 'app'
* Running on http://127.0.0.1:5000
```

2. Build Docker image:
```bash
docker build -t weather-service .
```

Output:
```
Successfully built 1234567890ab
Successfully tagged weather-service:latest
```

3. Deploy to Kubernetes:
```bash
kubectl apply -f kubernetes/weather-service.yaml
```

Output:
```
deployment.apps/weather-service created
service/weather-service created
horizontalpodautoscaler.autoscaling/weather-service-hpa created
ingress.networking.k8s.io/weather-service-ingress created
```

## Step 6: Automation Script

1. Make deploy.sh executable:
```bash
chmod +x scripts/deploy.sh
```

2. Run deployment script:
```bash
./scripts/deploy.sh
```

Output:
```
Starting deployment process...
AWS credentials verified.
Infrastructure setup complete.
Jenkins deployed successfully.
Weather service deployed successfully.
Deployment completed!

Jenkins URL: http://a1234567890abc-123456789.us-east-1.elb.amazonaws.com
Weather Service URL: http://b1234567890abc-123456789.us-east-1.elb.amazonaws.com
```

## GitHub Repository
All code is available at: https://github.com/Dayojo/project2

## Current Status
- Infrastructure deployed ✅
- Jenkins running ✅
- Weather service operational ✅
- CI/CD pipeline configured ✅
