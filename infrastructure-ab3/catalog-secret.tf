resource "kubectl_manifest" "catalog_db_secret_catalog_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: catalog-db-secret
  namespace: catalog
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

resource "kubectl_manifest" "catalog_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Namespace
metadata:
  name: catalog
YAML

  depends_on = [module.eks]
}