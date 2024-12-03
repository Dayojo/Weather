terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"

  # Tags to apply to all AWS resources
  default_tags {
    tags = {
      Environment = "Production"
      Project     = "Weather-Service"
      ManagedBy   = "Terraform"
    }
  }
}

# Kubernetes provider configuration will be added after EKS cluster creation
provider "kubernetes" {
  # Configuration will be loaded from EKS cluster
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    command     = "aws"
  }
}
