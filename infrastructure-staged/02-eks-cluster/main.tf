terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = var.tags
  }
}

# This provider is required for ECR and CloudFront to authenticate with public repos
provider "aws" {
  alias  = "ecr-cloudfront"
  region = "us-east-1"
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  config_path = "~/.kube/config"

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name,
    "--region", var.region]
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

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr-cloudfront
}

################################################################################
# Locals
################################################################################
locals {
  name   = data.terraform_remote_state.foundation.outputs.cluster_name
  region = data.terraform_remote_state.foundation.outputs.region
  tags   = data.terraform_remote_state.foundation.outputs.tags
}
