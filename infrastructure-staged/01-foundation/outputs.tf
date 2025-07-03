################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

################################################################################
# Aurora Outputs
################################################################################

output "aurora_cluster_endpoint" {
  description = "The cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "The cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "aurora_cluster_database_name" {
  description = "The database name"
  value       = aws_rds_cluster.aurora.database_name
  sensitive   = true
}

output "aurora_security_group_id" {
  description = "Security group ID for Aurora cluster"
  value       = aws_security_group.aurora.id
}

################################################################################
# IAM Outputs
################################################################################

output "custom_nodeclass_role_arn" {
  description = "ARN of the custom nodeclass IAM role"
  value       = aws_iam_role.custom_nodeclass_role.arn
}

output "custom_nodeclass_role_name" {
  description = "Name of the custom nodeclass IAM role"
  value       = aws_iam_role.custom_nodeclass_role.name
}

output "lb_controller_policy_arn" {
  description = "ARN of the Load Balancer Controller IAM policy"
  value       = aws_iam_policy.lb_controller_policy.arn
}

################################################################################
# Common Outputs
################################################################################

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = local.name
}

output "region" {
  description = "AWS region"
  value       = local.region
}

output "tags" {
  description = "Common tags"
  value       = local.tags
}
