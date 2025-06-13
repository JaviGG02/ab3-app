# Catalog Service Deployment

This directory contains Kubernetes manifests for deploying the Catalog service that connects to an Aurora MySQL database.

## Prerequisites

1. An EKS cluster must be running
2. The Aurora MySQL database must be provisioned
3. The `catalog-db-secret` secret must be created in the `catalog` namespace (via Terraform)

## Deployment

The catalog service is configured to use the Aurora MySQL database provisioned in the infrastructure. The connection details are stored in a Kubernetes secret named `catalog-db-secret` that is created by the Terraform configuration in `infrastructure-ab3/catalog-secret.tf`.

To deploy the catalog service:

1. Make sure the infrastructure has been provisioned using Terraform
2. Run the `install.ps1` script:

```powershell
.\install.ps1
```

This script will:
- Ensure the catalog namespace exists
- Update the catalog-db-service.yaml with the Aurora endpoint from the secret
- Apply all Kubernetes resources using kustomize
- Check the deployment status

## Uninstallation

To remove the catalog service:

```powershell
.\uninstall.ps1
```

## Architecture

- `deployment.yaml`: Defines the catalog service deployment
- `service.yaml`: Exposes the catalog service within the cluster
- `catalog-db-service.yaml`: Creates an ExternalName service that points to the Aurora database
- `kustomization.yaml`: Defines the resources to be applied
- `update-catalog-db-service.ps1`: Helper script to update the catalog-db-service.yaml with the Aurora endpoint