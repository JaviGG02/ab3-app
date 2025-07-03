variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ab3-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.33" # Update this to the latest version when needed
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Project     = "AB3"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Karpenter variables
variable "karpenter_node_group_instance_types" {
  description = "Instance types for the EKS managed node group that runs Karpenter"
  type        = list(string)
  default     = ["m5.large"]
}

# Aurora MySQL variables
variable "aurora_mysql_instance_class" {
  description = "Instance class for Aurora MySQL"
  type        = string
  default     = "db.r5.large"
}

variable "aurora_mysql_engine_version" {
  description = "Engine version for Aurora MySQL"
  type        = string
  default     = "8.0"
}
