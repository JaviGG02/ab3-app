################################################################################
# CloudFront Outputs
################################################################################

output "cloudfront_distribution_id" {
  description = "The identifier for the distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "The ARN (Amazon Resource Name) for the distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_distribution_caller_reference" {
  description = "Internal value used by CloudFront to allow future updates to the distribution configuration"
  value       = aws_cloudfront_distribution.main.caller_reference
}

output "cloudfront_distribution_status" {
  description = "The current status of the distribution. Deployed if the distribution's information is fully propagated throughout the Amazon CloudFront system"
  value       = aws_cloudfront_distribution.main.status
}

output "cloudfront_distribution_trusted_signers" {
  description = "List of nested attributes for active trusted signers, if the distribution is set up to serve private content with signed URLs"
  value       = aws_cloudfront_distribution.main.trusted_signers
}

output "cloudfront_domain_name" {
  description = "The domain name corresponding to the distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_etag" {
  description = "The current version of the distribution's information"
  value       = aws_cloudfront_distribution.main.etag
}

output "cloudfront_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

################################################################################
# WAF Outputs
################################################################################

output "waf_cloudfront_acl_id" {
  description = "The ID of the WAF WebACL for CloudFront"
  value       = aws_wafv2_web_acl.basic_acl.id
}

output "waf_cloudfront_acl_arn" {
  description = "The ARN of the WAF WebACL for CloudFront"
  value       = aws_wafv2_web_acl.basic_acl.arn
}

output "waf_alb_acl_id" {
  description = "The ID of the WAF WebACL for ALB"
  value       = aws_wafv2_web_acl.alb_acl.id
}

output "waf_alb_acl_arn" {
  description = "The ARN of the WAF WebACL for ALB"
  value       = aws_wafv2_web_acl.alb_acl.arn
}

################################################################################
# Application Access
################################################################################

output "application_url" {
  description = "URL to access the application through CloudFront"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "alb_hostname" {
  description = "ALB hostname (direct access - should be blocked by WAF)"
  value       = data.kubernetes_ingress_v1.ui_ingress.status[0].load_balancer[0].ingress[0].hostname
}
