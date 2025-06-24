# # Applying UI Microservice Resources
# # resource "kubectl_manifest" "ui_sa" {
# #   yaml_body = file("${path.module}/../manifests-ab3/retail-sample-app/ui/service-acc.yaml")
# # }

# # resource "kubectl_manifest" "ui_configmap" {
# #   yaml_body = file("${path.module}/../manifests-ab3/retail-sample-app/ui/config-map.yaml")
# #   depends_on = [kubectl_manifest.ui_sa]
# # }

# # resource "kubectl_manifest" "ui_service" {
# #   yaml_body = file("${path.module}/../manifests-ab3/retail-sample-app/ui/service.yaml")
# #   depends_on = [kubectl_manifest.ui_configmap]
# # }

# # resource "kubectl_manifest" "ui_deployment" {
# #   yaml_body = file("${path.module}/../manifests-ab3/retail-sample-app/ui/deployment.yaml")
# #   depends_on = [kubectl_manifest.ui_service]
# # }

# # resource "kubectl_manifest" "ui_ingress" {
# #   yaml_body = templatefile("${path.module}/../manifests-ab3/retail-sample-app/ui/ingress.yaml", {
# #     CLOUDFRONT_SECRET = random_string.cloudfront_secret.result
# #   })
# #   depends_on = [kubectl_manifest.ui_deployment]
# # }

# data "kubernetes_ingress_v1" "ui_ingress" {
#   metadata {
#     name      = "ui-ingress"
#     namespace = "default"
#   }
# }

# # Generate a random string to use as a secret between CloudFront and ALB
# resource "random_string" "cloudfront_secret" {
#   length  = 16
#   special = false
# }

# # Enhanced WAF ACL with basic ruleset
# resource "aws_wafv2_web_acl" "basic_acl" {
#   provider    = aws.ecr-cloudfront
#   name        = "basic-waf-acl"
#   description = "Basic WAF ACL with AWS managed rules"
#   scope       = "CLOUDFRONT"

#   default_action {
#     allow {}
#   }

#   # AWS Managed Core Rule Set
#   rule {
#     name     = "AWS-AWSManagedRulesCommonRuleSet"
#     priority = 1

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name               = "AWSManagedRulesCommonRuleSetMetric"
#       sampled_requests_enabled  = true
#     }
#   }

#   # SQL Injection Protection
#   rule {
#     name     = "AWS-AWSManagedRulesSQLiRuleSet"
#     priority = 2

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesSQLiRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name               = "AWSManagedRulesSQLiRuleSetMetric"
#       sampled_requests_enabled  = true
#     }
#   }

#   # Rate Limiting
#   # rule {
#   #   name     = "RateLimit"
#   #   priority = 3

#   #   action {
#   #     block {}
#   #   }

#   #   statement {
#   #     rate_based_statement {
#   #       limit              = 1000
#   #       aggregate_key_type = "IP"
#   #     }
#   #   }

#   #   visibility_config {
#   #     cloudwatch_metrics_enabled = true
#   #     metric_name               = "RateLimitMetric"
#   #     sampled_requests_enabled  = true
#   #   }
#   # }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name               = "BasicWAFACLMetric"
#     sampled_requests_enabled  = true
#   }

#   tags = local.tags
# }

# # Blocking ALB request from outside cloudfront
# resource "aws_wafv2_web_acl" "alb_acl" {
#   name        = "alb-waf-acl"
#   description = "Allow only CloudFront with secret header"
#   scope       = "REGIONAL" # <-- Critical for ALB
#   default_action {
#     block {}
#   }
#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "alb-waf"
#     sampled_requests_enabled   = true
#   }
#   rule {
#     name     = "AllowCloudFrontHeader"
#     priority = 1
#     action {
#       allow {}
#     }
#     statement {
#       byte_match_statement {
#         field_to_match {
#           single_header {
#             name = "x-cloudfront-secret"
#           }
#         }
#         positional_constraint = "EXACTLY"
#         search_string         = random_string.cloudfront_secret.result
        
#         text_transformation {
#           priority = 0
#           type     = "NONE"
#         }
#       }
#     }
#     visibility_config {
#       sampled_requests_enabled   = true
#       cloudwatch_metrics_enabled = true
#       metric_name                = "allow-cloudfront-header"
#     }
#   }
# }

#   # Parse the ALB hostname to get the ARN
# locals {
#   alb_hostname = data.kubernetes_ingress_v1.ui_ingress.status[0].load_balancer[0].ingress[0].hostname
#   hostname_without_domain = split(".", local.alb_hostname)[0]
#   alb_name = join("-", slice(split("-", local.hostname_without_domain), 0, 4))
# }
# output "alb_name" {
#   value = local.alb_name
# }

# # Find the ALB using data source with name filter
# data "aws_lb" "ui_alb" {
#   name = local.alb_name
# }

# # WAF association with ALB
# # resource "aws_wafv2_web_acl_association" "alb_assoc" {
# #   resource_arn = data.aws_lb.ui_alb.arn
# #   web_acl_arn  = aws_wafv2_web_acl.alb_acl.arn
  
# #   depends_on = [data.aws_lb.ui_alb]
# # }

# # CloudFront distribution with ALB origin
# resource "aws_cloudfront_distribution" "ui_distribution" {
#   provider = aws.ecr-cloudfront
#   enabled  = true
#   comment  = "UI Distribution"

#   # Use the ALB hostname from the ingress
#   origin {
#     domain_name = data.kubernetes_ingress_v1.ui_ingress.status.0.load_balancer.0.ingress.0.hostname
#     origin_id   = "K8sUIOrigin"

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "http-only"
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
    
#     # Add a secret header to identify CloudFront requests
#     custom_header {
#       name  = "X-CloudFront-Secret"
#       value = random_string.cloudfront_secret.result
#     }
    
#     # Ensure all headers are forwarded to the origin
#     custom_header {
#       name  = "X-Forwarded-Host"
#       value = data.kubernetes_ingress_v1.ui_ingress.status.0.load_balancer.0.ingress.0.hostname
#     }
#   }
  
#   lifecycle {
#     # Ignore any references to the ALB that might be in the CloudFront distribution
#     ignore_changes = [origin]
#   }
  
#   # Default cache behavior for all other paths
#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods         = ["GET", "HEAD"]
#     target_origin_id       = "K8sUIOrigin"
#     viewer_protocol_policy = "redirect-to-https"
#     compress               = true

#     forwarded_values {
#       query_string = true
#       cookies {
#         forward = "all"
#       }
#       headers = ["*"] # Forward all headers to ensure proper routing
#     }

#     min_ttl     = 0
#     default_ttl = 0  # Disable caching for dynamic content
#     max_ttl     = 0  # Disable caching for dynamic content
#   }

#   # Cache behavior for home page
#   ordered_cache_behavior {
#     path_pattern           = "/"
#     allowed_methods        = ["GET", "HEAD"]
#     cached_methods         = ["GET", "HEAD"]
#     target_origin_id       = "K8sUIOrigin"
#     viewer_protocol_policy = "redirect-to-https"
#     compress               = true

#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#       headers = []
#     }

#     min_ttl     = 300
#     default_ttl = 1800
#     max_ttl     = 3600
#   }

#   # Cache behavior for catalog pages
#   ordered_cache_behavior {
#     path_pattern           = "/catalog/*"
#     allowed_methods        = ["GET", "HEAD"]
#     cached_methods         = ["GET", "HEAD"]
#     target_origin_id       = "K8sUIOrigin"
#     viewer_protocol_policy = "redirect-to-https"
#     compress               = true

#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#       headers = []
#     }

#     min_ttl     = 300
#     default_ttl = 3600
#     max_ttl     = 86400
#   }

#   price_class = "PriceClass_100" # Use only North America and Europe

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   # Associate with WAF
#   web_acl_id = aws_wafv2_web_acl.basic_acl.arn

#   tags = local.tags
# }


# # OUTPUTS 
# output "ui_ingress_hostname" {
#   value = data.kubernetes_ingress_v1.ui_ingress.status[0].load_balancer[0].ingress[0].hostname
# }

# # output "cloudfront_domain_name" {
# #   value = aws_cloudfront_distribution.ui_distribution.domain_name
# # }

# output "waf_acl_arn" {
#   value = aws_wafv2_web_acl.basic_acl.arn
# }