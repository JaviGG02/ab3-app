# ################################################################################
# # Kubernetes Provider Configuration
# ################################################################################

# provider "kubernetes" {
#   alias = "eks"
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#   }
# }

# ################################################################################
# # Catalog Namespace and DB Secret
# ################################################################################

# resource "kubernetes_namespace" "catalog" {
#   provider = kubernetes.eks
#   metadata {
#     name = "catalog"
#   }

#   depends_on = [module.eks]
# }

# resource "kubernetes_secret" "catalog_db_secret" {
#   provider = kubernetes.eks
#   metadata {
#     name      = "catalog-db"
#     namespace = "default"
#   }

#   data = {
#     RETAIL_CATALOG_PERSISTENCE_PROVIDER  = "mysql"
#     RETAIL_CATALOG_PERSISTENCE_ENDPOINT  = "${aws_rds_cluster.aurora.endpoint}:3306"
#     RETAIL_CATALOG_PERSISTENCE_DB_NAME   = aws_rds_cluster.aurora.database_name
#     RETAIL_CATALOG_PERSISTENCE_USER      = local.db_creds.username
#     RETAIL_CATALOG_PERSISTENCE_PASSWORD  = local.db_creds.password
#     RETAIL_CATALOG_PERSISTENCE_CONNECT_TIMEOUT = "5"
#   }

#   depends_on = [module.eks, aws_rds_cluster.aurora]
# }

# ################################################################################
# # Apply Catalog Service
# ################################################################################

# /*
# resource "kubernetes_service_account" "catalog" {
#   provider = kubernetes.eks
#   metadata {
#     name = "catalog"
#     labels = {
#       "app.kubernetes.io/name" = "catalog"
#       "app.kubernetes.io/instance" = "catalog"
#       "app.kubernetes.io/component" = "service"
#       "app.kubernetes.io/owner" = "retail-store-sample"
#     }
#   }
#   depends_on = [kubernetes_namespace.catalog]
# }

# resource "kubernetes_service" "catalog" {
#   provider = kubernetes.eks
#   metadata {
#     name = "catalog"
#     labels = {
#       "app.kubernetes.io/name" = "catalog"
#       "app.kubernetes.io/instance" = "catalog"
#       "app.kubernetes.io/component" = "service"
#       "app.kubernetes.io/owner" = "retail-store-sample"
#     }
#   }
#   spec {
#     type = "ClusterIP"
#     port {
#       port = 80
#       target_port = "http"
#       protocol = "TCP"
#       name = "http"
#     }
#     selector = {
#       "app.kubernetes.io/name" = "catalog"
#       "app.kubernetes.io/instance" = "catalog"
#       "app.kubernetes.io/component" = "service"
#       "app.kubernetes.io/owner" = "retail-store-sample"
#     }
#   }
# }

# resource "kubernetes_deployment" "catalog" {
#   provider = kubernetes.eks
#   metadata {
#     name = "catalog"
#     labels = {
#       "app.kubernetes.io/name" = "catalog"
#       "app.kubernetes.io/instance" = "catalog"
#       "app.kubernetes.io/component" = "service"
#       "app.kubernetes.io/owner" = "retail-store-sample"
#     }
#   }
#   spec {
#     replicas = 1
#     selector {
#       match_labels = {
#         "app.kubernetes.io/name" = "catalog"
#         "app.kubernetes.io/instance" = "catalog"
#         "app.kubernetes.io/component" = "service"
#         "app.kubernetes.io/owner" = "retail-store-sample"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           "app.kubernetes.io/name" = "catalog"
#           "app.kubernetes.io/instance" = "catalog"
#           "app.kubernetes.io/component" = "service"
#           "app.kubernetes.io/owner" = "retail-store-sample"
#         }
#         annotations = {
#           "prometheus.io/path" = "/metrics"
#           "prometheus.io/port" = "8080"
#           "prometheus.io/scrape" = "true"
#         }
#       }
#       spec {
#         service_account_name = "catalog"
#         security_context {
#           fs_group = 1000
#         }
#         container {
#           name = "catalog"
#           image = "public.ecr.aws/aws-containers/retail-store-sample-catalog:1.1.0"
#           image_pull_policy = "IfNotPresent"
          
#           env_from {
#             secret_ref {
#               name = kubernetes_secret.catalog_db_secret.metadata[0].name
#             }
#           }
          
#           security_context {
#             capabilities {
#               drop = ["ALL"]
#             }
#             read_only_root_filesystem = true
#             run_as_non_root = true
#             run_as_user = 1000
#           }
          
#           port {
#             name = "http"
#             container_port = 8080
#             protocol = "TCP"
#           }
          
#           readiness_probe {
#             http_get {
#               path = "/health"
#               port = 8080
#             }
#           }
          
#           resources {
#             limits = {
#               memory = "256Mi"
#             }
#             requests = {
#               cpu = "256m"
#               memory = "256Mi"
#             }
#           }
          
#           volume_mount {
#             name = "tmp-volume"
#             mount_path = "/tmp"
#           }
#         }
        
#         volume {
#           name = "tmp-volume"
#           empty_dir {
#             medium = "Memory"
#           }
#         }
#       }
#     }
#   }
  
#   depends_on = [
#     kubernetes_secret.catalog_db_secret,
#     kubernetes_service_account.catalog
#   ]
# }
# */

# ################################################################################
# # Outputs
# ################################################################################

# output "catalog_db_connection" {
#   description = "Aurora database connection details for catalog service"
#   value       = "${aws_rds_cluster.aurora.endpoint}:3306"
#   sensitive   = true
# }

# output "access_ui_command" {
#   value       = "kubectl get svc ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
#   description = "Command to get the UI service endpoint"
# }