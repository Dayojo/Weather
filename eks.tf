# This file defines the EKS cluster and associated resources.
# It creates:
# 1. EKS cluster with version 1.27
# 2. Node group with t3.medium instances
# 3. Required IAM roles and security groups

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "weather-cluster"
  cluster_version = "1.27"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  # EKS Managed Node Group(s)
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
