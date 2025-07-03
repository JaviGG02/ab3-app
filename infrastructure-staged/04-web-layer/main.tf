terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = var.tags
  }
}

# This provider is required for CloudFront (must be in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  default_tags {
    tags = var.tags
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks_cluster.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks_cluster.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", data.terraform_remote_state.eks_cluster.outputs.cluster_name]
  }
}

################################################################################
# Data Sources
################################################################################

# Get foundation stage outputs
data "terraform_remote_state" "foundation" {
  backend = "local"

  config = {
    path = "../01-foundation/terraform.tfstate"
  }
}

# Get EKS cluster stage outputs
data "terraform_remote_state" "eks_cluster" {
  backend = "local"

  config = {
    path = "../02-eks-cluster/terraform.tfstate"
  }
}

################################################################################
# Locals
################################################################################
locals {
  name   = data.terraform_remote_state.foundation.outputs.cluster_name
  region = data.terraform_remote_state.foundation.outputs.region
  tags   = data.terraform_remote_state.foundation.outputs.tags
}
