################################################################################
# EKS Add-ons
################################################################################

# Add CoreDNS and metrics-server to the existing cluster with node selectors
resource "aws_eks_addon" "coredns" {
  cluster_name             = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  addon_name               = "coredns"
  addon_version            = data.aws_eks_addon_version.coredns.version
  
  configuration_values = jsonencode({
    tolerations = [
      {
        key    = "CriticalAddonsOnly"
        operator = "Exists"
        effect = "NoSchedule"
      }
    ],
    nodeSelector = {
      role = "system"
    }
  })
  
  tags = local.tags
}

# Commented out - replaced with Helm chart in metrics-server-fix.tf for better control
resource "aws_eks_addon" "metrics_server" {
  cluster_name             = data.terraform_remote_state.eks_cluster.outputs.cluster_name
  addon_name               = "metrics-server"
  addon_version            = data.aws_eks_addon_version.metrics_server.version
  
  configuration_values = jsonencode({
    tolerations = [
      {
        key    = "CriticalAddonsOnly"
        operator = "Exists"
        effect = "NoSchedule"
      }
    ],
    nodeSelector = {
      role = "system"
    }
  })
  
  tags = local.tags
}

# Get latest addon versions
data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = data.terraform_remote_state.eks_cluster.outputs.cluster_version
  most_recent        = true
}

data "aws_eks_addon_version" "metrics_server" {
  addon_name         = "metrics-server"
  kubernetes_version = data.terraform_remote_state.eks_cluster.outputs.cluster_version
  most_recent        = true
}

################################################################################
# Load Balancer Controller Add-On
################################################################################

module "lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.46"  # Use latest 5.x version

  role_name             = "${local.name}-lb-controller-irsa"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn = data.terraform_remote_state.eks_cluster.outputs.oidc_provider_arn
      namespace_service_accounts = [
        "kube-system:aws-load-balancer-controller",
      ]
    }
  }

  tags = local.tags
}

resource "kubernetes_service_account" "lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_controller_irsa.iam_role_arn
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.1" # Updated to latest version

  values = [
    yamlencode({
      clusterName = data.terraform_remote_state.eks_cluster.outputs.cluster_name
      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
      region = var.region
      vpcId  = data.terraform_remote_state.foundation.outputs.vpc_id
      nodeSelector = {
        role = "system"
      }
      tolerations = [
        {
          key = "CriticalAddonsOnly"
          operator = "Exists"
          effect = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [
    kubernetes_service_account.lb_controller,
    module.lb_controller_irsa
  ]
}
