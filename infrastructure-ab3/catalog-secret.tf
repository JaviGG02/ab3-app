resource "kubectl_manifest" "catalog_db_secret_catalog_namespace" {
  yaml_body = <<-YAML
apiVersion: v1
kind: Secret
metadata:
  name: catalog-db-secret
  namespace: catalog
type: Opaque
stringData:
  RETAIL_CATALOG_PERSISTENCE_PROVIDER: "mysql"
  RETAIL_CATALOG_PERSISTENCE_ENDPOINT: "${aws_rds_cluster.aurora.endpoint}:3306"
  RETAIL_CATALOG_PERSISTENCE_DB_NAME: "${aws_rds_cluster.aurora.database_name}"
  RETAIL_CATALOG_PERSISTENCE_USER: "${local.db_creds.username}"
  RETAIL_CATALOG_PERSISTENCE_PASSWORD: "${local.db_creds.password}"
  RETAIL_CATALOG_PERSISTENCE_CONNECT_TIMEOUT: "5"

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