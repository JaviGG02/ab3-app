output "kubectl_access_command" {
  description = "Command to configure kubectl to access the EKS cluster"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "karpenter_iam_role_arn" {
  description = "ARN of the IAM role used by Karpenter"
  value       = module.karpenter.node_iam_role_arn
}

output "karpenter_queue_name" {
  description = "Name of the SQS queue used by Karpenter"
  value       = module.karpenter.queue_name
}

# Aurora MySQL outputs (placeholders)
output "aurora_mysql_cluster_endpoint" {
  description = "The cluster endpoint for Aurora MySQL"
  value       = "placeholder-for-aurora-endpoint"
}

output "aurora_mysql_reader_endpoint" {
  description = "The reader endpoint for Aurora MySQL"
  value       = "placeholder-for-aurora-reader-endpoint"
}

# ArgoCD outputs (placeholders)
output "argocd_url" {
  description = "URL for ArgoCD UI"
  value       = "placeholder-for-argocd-url"
}