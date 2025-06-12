resource "kubectl_manifest" "orders_db_secret_orders_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: orders-db-secret
  namespace: orders
type: Opaque
stringData:
  DB_HOST: "${aws_rds_cluster.aurora.endpoint}"
  DB_PORT: "3306"
  DB_NAME: "orders"
  DB_USER: "${local.db_creds.username}"
  DB_PASSWORD: "${local.db_creds.password}"
YAML

  depends_on = [module.eks]
}

resource "kubectl_manifest" "orders_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: orders
YAML

  depends_on = [module.eks]
}