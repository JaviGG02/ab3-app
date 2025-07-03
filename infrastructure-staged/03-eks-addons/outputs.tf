################################################################################
# Add-ons Outputs
################################################################################

output "coredns_addon_version" {
  description = "Version of CoreDNS addon"
  value       = aws_eks_addon.coredns.addon_version
}



output "lb_controller_role_arn" {
  description = "ARN of the Load Balancer Controller IAM role"
  value       = module.lb_controller_irsa.iam_role_arn
}

output "lb_controller_helm_release_status" {
  description = "Status of the Load Balancer Controller Helm release"
  value       = helm_release.aws_load_balancer_controller.status
}
