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
  yaml_body = templatefile("${path.module}/../manifests-ab3/ui/ingress.yaml", {
    security_group_ids = aws_security_group.alb_cloudfront_only.id
  })
  depends_on = [kubectl_manifest.ui_deployment, aws_security_group.alb_cloudfront_only]
}
 # origin_verify = random_password.origin_verify.result

data "kubernetes_ingress_v1" "ui_ingress" {
  metadata {
    name      = "ui-ingress"
    namespace = "default"
  }

  depends_on = [kubectl_manifest.ui_ingress]
}

output "alb_hostname" {
  value       = try(data.kubernetes_ingress_v1.ui_ingress.status[0].load_balancer[0].ingress[0].hostname, "ALB not ready")
  description = "ALB DNS name provisioned by the Ingress Controller"
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
  }

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
      headers = ["Host", "Origin", "Authorization"]
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
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

# Get current AWS account ID
data "aws_caller_identity" "current" {
  provider = aws.ecr-cloudfront
}

# Get CloudFront managed prefix list
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Security groups for the application
# 1. ALB security group - only allows traffic from CloudFront
resource "aws_security_group" "alb_cloudfront_only" {
  name        = "alb-cloudfront-only"
  description = "Allow traffic from CloudFront to ALB only"
  vpc_id      = module.vpc.vpc_id

  # Allow CloudFront traffic to ALB
  ingress {
    description     = "HTTP from CloudFront"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "alb-cloudfront-only"
    }
  )
}

# 2. Microservices security group - allows internal communication between services
resource "aws_security_group" "microservices_internal" {
  name        = "microservices-internal"
  description = "Allow internal traffic between microservices"
  vpc_id      = module.vpc.vpc_id
  
  # Allow internal VPC traffic for microservice communication
  ingress {
    description = "Internal VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "microservices-internal"
    }
  )
}

# 3. Database security group - only allows traffic from microservices
resource "aws_security_group" "database_internal" {
  name        = "database-internal"
  description = "Allow traffic from microservices to databases"
  vpc_id      = module.vpc.vpc_id
  
  # Allow PostgreSQL access from microservices
  ingress {
    description     = "PostgreSQL from microservices"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal.id]
  }
  
  # Allow RabbitMQ access from microservices
  ingress {
    description     = "RabbitMQ from microservices"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal.id]
  }
  
  # Allow RabbitMQ management interface from microservices
  ingress {
    description     = "RabbitMQ Management from microservices"
    from_port       = 15672
    to_port         = 15672
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal.id]
  }
  
  # Allow Redis access from microservices
  ingress {
    description     = "Redis from microservices"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal.id]
  }
  
  # Allow DynamoDB local access from microservices
  ingress {
    description     = "DynamoDB local from microservices"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.microservices_internal.id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "database-internal"
    }
  )
}

# Instructions for the user
output "next_steps" {
  value = <<-EOT
IMPORTANT: Follow these steps to complete the setup:

1. Apply the Terraform configuration:
   terraform apply

2. Wait for the Kubernetes resources to be created and the ALB to be provisioned.
   This will automatically apply the UI manifests from the /ui/ folder using kustomize.

3. The CloudFront distribution will automatically use the ALB hostname from the ingress.
   Access your application via the CloudFront domain:
   ${aws_cloudfront_distribution.ui_distribution.domain_name}

NOTE: Shield Advanced protection requires a subscription. To enable it:
1. Subscribe to Shield Advanced in the AWS console
2. Uncomment the aws_shield_protection resource in web-layer.tf
3. Run terraform apply again
EOT
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.ui_distribution.domain_name
}

output "waf_acl_arn" {
  value = aws_wafv2_web_acl.basic_acl.arn
}