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

# Security group for Aurora - will be updated in stage 2 to allow EKS access
resource "aws_security_group" "aurora" {
  name        = "${local.name}-aurora"
  description = "Security group for Aurora cluster"
  vpc_id      = module.vpc.vpc_id

  # Placeholder rule - will be updated in stage 2
  ingress {
    description = "MySQL/Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
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
