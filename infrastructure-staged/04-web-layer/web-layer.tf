# Getting ALB from Ingress UI

data "kubernetes_ingress_v1" "ui_ingress" {
  metadata {
    name      = "ui-ingress"
    namespace = "default"
  }
}

# Generate a random string to use as a secret between CloudFront and ALB
resource "random_string" "cloudfront_secret" {
  length  = 16
  special = false
}

# Enhanced WAF ACL with basic ruleset
resource "aws_wafv2_web_acl" "basic_acl" {
  provider    = aws.us_east_1
  name        = "basic-waf-acl"
  description = "Basic WAF ACL with AWS managed rules"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS Managed Core Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  # SQL Injection Protection
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesSQLiRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  # Known Bad Inputs
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled  = true
    }
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimitRuleMetric"
      sampled_requests_enabled  = true
    }
  }

  tags = local.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "BasicWAFMetric"
    sampled_requests_enabled  = true
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  provider = aws.us_east_1

  origin {
    domain_name = data.kubernetes_ingress_v1.ui_ingress.status.0.load_balancer.0.ingress.0.hostname
    origin_id   = "ALB-${local.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Custom-Header"
      value = random_string.cloudfront_secret.result
    }
  }

  enabled             = true
  comment             = "CloudFront distribution for ${local.name}"

  # Cache behavior for static assets
  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${local.name}"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-${local.name}"

    forwarded_values {
      query_string = true
      headers      = ["Host", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-Tablet-Viewer"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 86400
    compress               = true
  }

  # Geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Associate with WAF
  web_acl_id = aws_wafv2_web_acl.basic_acl.arn

  tags = local.tags
}

# WAF ACL for ALB (Regional)
resource "aws_wafv2_web_acl" "alb_acl" {
  name        = "alb-waf-acl"
  description = "WAF ACL for ALB with custom header verification"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  # Allow requests with the custom header from CloudFront
  rule {
    name     = "AllowCloudFrontRequests"
    priority = 1

    action {
      allow {}
    }

    statement {
      byte_match_statement {
        search_string = random_string.cloudfront_secret.result
        field_to_match {
          single_header {
            name = "x-custom-header"
          }
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
        positional_constraint = "EXACTLY"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AllowCloudFrontRequestsMetric"
      sampled_requests_enabled  = true
    }
  }

  # Block all other requests
  rule {
    name     = "BlockDirectAccess"
    priority = 2

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          byte_match_statement {
            search_string = random_string.cloudfront_secret.result
            field_to_match {
              single_header {
                name = "x-custom-header"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
            positional_constraint = "EXACTLY"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "BlockDirectAccessMetric"
      sampled_requests_enabled  = true
    }
  }

  tags = local.tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "ALBWAFMetric"
    sampled_requests_enabled  = true
  }
}

# Parse the ALB hostname to get the ARN
locals {
  alb_hostname = data.kubernetes_ingress_v1.ui_ingress.status[0].load_balancer[0].ingress[0].hostname
  hostname_without_domain = split(".", local.alb_hostname)[0]
  alb_name = join("-", slice(split("-", local.hostname_without_domain), 0, 4))
}
output "alb_name" {
  value = local.alb_name
}
# Find the ALB using data source with name filter
data "aws_lb" "ui_alb" {
  name = local.alb_name
}
# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "alb_assoc" {
  resource_arn = data.aws_lb.ui_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_acl.arn
  
  depends_on = [data.aws_lb.ui_alb]
}
