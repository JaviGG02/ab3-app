variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.33" # Update this to the latest version when needed
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
