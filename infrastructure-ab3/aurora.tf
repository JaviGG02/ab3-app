################################################################################
# Secrets Manager Aurora Cluster
################################################################################
data "aws_secretsmanager_secret" "db_credentials" {
  name = "ab3/aurora/credentials"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)
}

################################################################################
# Aurora RDS Cluster
################################################################################

resource "aws_db_subnet_group" "aurora" {
  name       = "${local.name}-aurora"
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}

resource "aws_security_group" "aurora" {
  name        = "${local.name}-aurora"
  description = "Allow inbound traffic from EKS nodes to Aurora cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow EKS nodes to communicate with Aurora"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${local.name}-aurora"
  engine                  = "aurora-mysql"
  engine_version          = var.aurora_mysql_engine_version
  availability_zones      = local.azs
  database_name           = local.db_creds.dbname
  master_username         = local.db_creds.username
  master_password         = local.db_creds.password
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  vpc_security_group_ids  = [aws_security_group.aurora.id]
  
  # Enable storage encryption
  storage_encrypted = true
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-aurora"
    }
  )
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count               = 2
  identifier          = "${local.name}-aurora-${count.index}"
  cluster_identifier  = aws_rds_cluster.aurora.id
  instance_class      = var.aurora_mysql_instance_class
  engine              = aws_rds_cluster.aurora.engine
  engine_version      = aws_rds_cluster.aurora.engine_version
  db_subnet_group_name = aws_db_subnet_group.aurora.name
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name}-aurora-${count.index}"
    }
  )
}

# Create Kubernetes secrets for catalog and orders services to access the database
resource "kubectl_manifest" "catalog_db_secret" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: catalog-db-secret
  namespace: default
type: Opaque
stringData:
  DB_HOST: "${aws_rds_cluster.aurora.endpoint}"
  DB_PORT: "3306"
  DB_NAME: "catalog"
  DB_USER: "${local.db_creds.username}"
  DB_PASSWORD: "${local.db_creds.password}"
YAML

  depends_on = [module.eks]
}

resource "kubectl_manifest" "orders_db_secret" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: orders-db-secret
  namespace: default
type: Opaque
stringData:
  DB_HOST: "${aws_rds_cluster.aurora.endpoint}"
  DB_PORT: "3306"
  DB_NAME: "orders"
  DB_USER: "${aws_rds_cluster.aurora.master_username}"
  DB_PASSWORD: "${aws_rds_cluster.aurora.master_password}"
YAML

  depends_on = [module.eks]
}

################################################################################
# Outputs
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
  sensitive = true
}