# This is the main Terraform configuration file.
# It includes the AWS provider and Terraform backend configuration.

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
