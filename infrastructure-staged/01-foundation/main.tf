terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
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

################################################################################
# Common data sources
################################################################################

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr-cloudfront
}

data "aws_availability_zones" "available" {
  # Do not include local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

################################################################################
# Locals
################################################################################
locals {
  name   = var.cluster_name
  region = var.region

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  # Merge default tags with user provided tags
  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${local.name}" = "owned"
      "terraform-managed"                   = "true"
    }
  )
}
