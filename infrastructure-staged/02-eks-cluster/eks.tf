################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  # Give the Terraform identity admin access to the cluster
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  # Only basic add-ons for initial cluster setup
  cluster_addons = {
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = data.terraform_remote_state.foundation.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.foundation.outputs.private_subnets

  # Enable EKS AutoMode
  cluster_compute_config = {
    enabled = true
  }

  # Add managed node group for system workloads
  eks_managed_node_groups = {
    system = {
      name            = "system-node-group"
      use_name_prefix = true

      subnet_ids = data.terraform_remote_state.foundation.outputs.private_subnets

      min_size     = 1
      max_size     = 2
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      # Add labels to identify system nodes
      labels = {
        role = "system"
      }

      # Ensure system pods can be scheduled on these nodes
      taints = {
        dedicated = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE"  # Using PREFER_NO_SCHEDULE instead of NO_SCHEDULE to allow other pods if needed
        }
      }
    }
  }

  # Access entry for AutoMode nodes
  access_entries = {
    custom_nodeclass_access = {
      principal_arn = data.terraform_remote_state.foundation.outputs.custom_nodeclass_role_arn
      type          = "EC2"

      policy_associations = {
        auto = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAutoNodePolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = local.tags
}

################################################################################
# Update Aurora Security Group to allow EKS access
################################################################################

resource "aws_security_group_rule" "aurora_eks_access" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.eks.node_security_group_id
  security_group_id        = data.terraform_remote_state.foundation.outputs.aurora_security_group_id
  description              = "Allow EKS nodes to communicate with Aurora"
}

################################################################################
# EKS AutoMode Configuration
################################################################################

# Define custom NodeClass and NodePool configurations
locals {
  custom_nodeclass_yamls = [
    "nodeclass-basic.yaml",
    # "nodeclass-ebs-optimized.yaml"
  ]
  custom_nodepool_yamls = [
    "nodepool-amd64.yaml",
    "nodepool-graviton.yaml"
  ]
}

# Apply custom nodeclass objects
resource "kubectl_manifest" "custom_nodeclass" {
  for_each = toset(local.custom_nodeclass_yamls)

  yaml_body = templatefile("${path.module}/../../manifests-ab3/eks-automode-config/${each.value}", {
    node_iam_role_name = data.terraform_remote_state.foundation.outputs.custom_nodeclass_role_name
    cluster_name       = module.eks.cluster_name
  })

  depends_on = [module.eks]
}

# Apply custom nodepool objects
resource "kubectl_manifest" "custom_nodepool" {
  for_each = toset(local.custom_nodepool_yamls)

  yaml_body = file("${path.module}/../../manifests-ab3/eks-automode-config/${each.value}")

  depends_on = [kubectl_manifest.custom_nodeclass]
}

################################################################################
# Create Kubernetes secrets for catalog and orders services to access the database
################################################################################

# Get database credentials from Secrets Manager
data "aws_secretsmanager_secret" "db_credentials" {
  name = "ab3/aurora/credentials"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)
}

resource "kubectl_manifest" "catalog_db_secret" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: catalog-db
  namespace: default
type: Opaque
stringData:
  RETAIL_CATALOG_PERSISTENCE_USER: "${local.db_creds.username}"
  RETAIL_CATALOG_PERSISTENCE_PASSWORD: "${local.db_creds.password}"
YAML

  depends_on = [module.eks]
}

resource "kubectl_manifest" "catalog_config_map" {
  yaml_body = <<-YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: catalog
  namespace: default
data:
  RETAIL_CATALOG_PERSISTENCE_ENDPOINT: "${data.terraform_remote_state.foundation.outputs.aurora_cluster_endpoint}:3306"
  RETAIL_CATALOG_PERSISTENCE_PROVIDER: mysql
  RETAIL_CATALOG_PERSISTENCE_DB_NAME: "${data.terraform_remote_state.foundation.outputs.aurora_cluster_database_name}"
YAML

  depends_on = [module.eks]
}
