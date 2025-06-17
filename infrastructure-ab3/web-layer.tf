# Applying UI Microservice Resources
resource "kubectl_manifest" "ui_sa" {
  yaml_body = file("${path.module}/../manifests-ab3/ui/service-acc.yaml")
}

resource "kubectl_manifest" "ui_configmap" {
  yaml_body = file("${path.module}/../manifests-ab3/ui/config-map.yaml")
  depends_on = [kubectl_manifest.ui_sa]
}

resource "kubectl_manifest" "ui_service" {
  yaml_body = file("${path.module}/../manifests-ab3/ui/service.yaml")
  depends_on = [kubectl_manifest.ui_configmap]
}

resource "kubectl_manifest" "ui_deployment" {
  yaml_body = file("${path.module}/../manifests-ab3/ui/deployment.yaml")
  depends_on = [kubectl_manifest.ui_service]
}

resource "kubectl_manifest" "ui_ingress" {
  yaml_body = templatefile("${path.module}/../manifests-ab3/ui/ingress.yaml", {})
  depends_on = [kubectl_manifest.ui_deployment]
}


data "kubernetes_ingress_v1" "ui_ingress" {
  metadata {
    name      = "ui-ingress"
    namespace = "default"
  }

  depends_on = [kubectl_manifest.ui_ingress]
}

# Enhanced WAF ACL with basic ruleset
resource "aws_wafv2_web_acl" "basic_acl" {
  provider    = aws.ecr-cloudfront
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

  # Rate Limiting
  rule {
    name     = "RateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "RateLimitMetric"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "BasicWAFACLMetric"
    sampled_requests_enabled  = true
  }

  tags = local.tags
}

# CloudFront distribution with ALB origin
resource "aws_cloudfront_distribution" "ui_distribution" {
  provider = aws.ecr-cloudfront
  enabled  = true
  comment  = "UI Distribution"

  # Use the ALB hostname from the ingress
  origin {
    domain_name = data.kubernetes_ingress_v1.ui_ingress.status.0.load_balancer.0.ingress.0.hostname
    origin_id   = "K8sUIOrigin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    
    # Ensure all headers are forwarded to the origin
    custom_header {
      name  = "X-Forwarded-Host"
      value = data.kubernetes_ingress_v1.ui_ingress.status.0.load_balancer.0.ingress.0.hostname
    }
  }
  
  # Default cache behavior for all other paths
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "K8sUIOrigin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["*"] # Forward all headers to ensure proper routing
    }

    min_ttl     = 0
    default_ttl = 0  # Disable caching for dynamic content
    max_ttl     = 0  # Disable caching for dynamic content
  }


  price_class = "PriceClass_100" # Use only North America and Europe

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Associate with WAF
  web_acl_id = aws_wafv2_web_acl.basic_acl.arn

  tags = local.tags
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.ui_distribution.domain_name
}

output "waf_acl_arn" {
  value = aws_wafv2_web_acl.basic_acl.arn
}