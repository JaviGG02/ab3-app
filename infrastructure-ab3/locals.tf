locals {
  name   = var.cluster_name
  region = var.region

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  # Merge default tags with user provided tags
  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${local.name}" = "owned"
      "terraform-managed"                   = "true"
    }
  )
}