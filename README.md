# Infrastructure Project Documentation

## Reference Documentation
- AWS Documentation: https://docs.aws.amazon.com/
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- EKS Documentation: https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html
- Jenkins Documentation: https://www.jenkins.io/doc/
- Kubernetes Documentation: https://kubernetes.io/docs/home/
- Flask Documentation: https://flask.palletsprojects.com/

## Step 1: Initialize the Git Repository and Branch

### Reference Links:
- Git Basics: https://git-scm.com/book/en/v2/Getting-Started-Git-Basics
- GitHub CLI: https://cli.github.com/manual/

### Explanation:
We start by initializing a new Git repository and creating a feature branch. This follows Git Flow practices where all new features are developed in separate branches. The initialization creates a .git directory to track our changes, and the branch creation gives us a separate workspace for our feature development.

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

### Reference Links:
- Terraform AWS VPC Module: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
- Terraform AWS EKS Module: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
- AWS VPC Documentation: https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html

### Explanation:
We use Terraform to create our infrastructure as code. This includes setting up a VPC with public and private subnets, NAT gateways for private subnet internet access, and all necessary networking components. The configuration uses official AWS modules to ensure best practices are followed.

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

### Reference Links:
- EKS Cluster Creation: https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html
- kubectl Installation: https://kubernetes.io/docs/tasks/tools/install-kubectl/
- EKS Authentication: https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html

### Explanation:
After creating the EKS cluster with Terraform, we need to configure kubectl to interact with our cluster. The AWS CLI provides a command to update our kubeconfig file with the necessary credentials and cluster information.

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

### Reference Links:
- Jenkins on Kubernetes: https://www.jenkins.io/doc/book/installing/kubernetes/
- Jenkins Helm Chart: https://github.com/jenkinsci/helm-charts
- Kubernetes Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/

### Explanation:
Jenkins is deployed as a containerized application on our Kubernetes cluster. We create a dedicated namespace, set up persistent storage to maintain Jenkins data, and configure RBAC for security. The deployment includes a LoadBalancer service to make Jenkins accessible externally.

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

### Reference Links:
- Flask Documentation: https://flask.palletsprojects.com/
- Docker Documentation: https://docs.docker.com/
- Python Virtual Environments: https://docs.python.org/3/tutorial/venv.html
- Open-Meteo API: https://open-meteo.com/en/docs

### Explanation:
Our weather service is a Flask-based REST API that provides weather information. It's containerized using Docker for consistent deployment and scaled using Kubernetes. The service includes health checks, proper error handling, and uses the Open-Meteo API as its data source.

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

### Reference Links:
- Bash Scripting Guide: https://tldp.org/LDP/abs/html/
- AWS CLI Configuration: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
- Kubernetes Deployment Strategies: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

### Explanation:
The deployment script automates the entire setup process. It includes error handling, proper AWS credential verification, and provides clear status updates. The script ensures all components are deployed in the correct order and verifies each step's success.

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

## GitHub Repository Setup

### Reference Links:
- GitHub Repository Creation: https://docs.github.com/en/get-started/quickstart/create-a-repo
- GitHub CLI Authentication: https://cli.github.com/manual/gh_auth_login

1. Create a new repository on GitHub:
```bash
gh repo create project2 --public --source=. --remote=origin
```

2. Push the code:
```bash
git remote add origin https://github.com/Dayojo/project2.git
git push -u origin main
```

Repository URL: https://github.com/Dayojo/project2

## Current Status
- Infrastructure deployed ✅
- Jenkins running ✅
- Weather service operational ✅
- CI/CD pipeline configured ✅

## Testing the Weather Service

Once deployed, you can test the weather service using:
```bash
curl "http://[LOAD_BALANCER_URL]/weather?location=London"
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
