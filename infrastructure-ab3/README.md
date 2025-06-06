# AB3 Infrastructure

This repository contains Terraform code for deploying a comprehensive AWS infrastructure for the AB3 application, including EKS with Karpenter, Aurora MySQL, and ArgoCD integration.

## Architecture

The infrastructure consists of the following components:

- **VPC**: A dedicated VPC with public and private subnets across multiple availability zones
- **EKS Cluster**: Managed Kubernetes cluster with proper IAM roles and security configurations
- **Karpenter**: Auto-scaling solution for Kubernetes with support for AMD and ARM processors, as well as spot and on-demand instances
- **Aurora MySQL**: (Placeholder) Managed MySQL-compatible database for application data
- **ArgoCD**: (Placeholder) GitOps continuous delivery tool for Kubernetes

## Directory Structure

```
ab3-app/
├── infrastructure-ab3/    # Terraform infrastructure code
│   ├── main.tf           # Provider configuration and common resources
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── locals.tf         # Local variables
│   ├── vpc.tf            # VPC configuration
│   ├── eks.tf            # EKS cluster configuration
│   ├── karpenter.tf      # Karpenter configuration
│   ├── aurora.tf         # Aurora MySQL configuration (placeholder)
│   ├── argocd.tf         # ArgoCD configuration (placeholder)
│   └── state.tf          # Terraform state management
└── manifests-ab3/        # Kubernetes manifests
    ├── karpenter.yaml    # Karpenter NodePool and EC2NodeClass
    ├── argocd-placeholder.yaml  # ArgoCD Application placeholder
    └── aurora-placeholder.yaml  # Aurora MySQL connection information
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.3
- kubectl
- helm

## Deployment

1. Initialize Terraform:

```bash
cd infrastructure-ab3
terraform init
```

2. Review the plan:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

4. Configure kubectl to connect to the EKS cluster:

```bash
aws eks --region <region> update-kubeconfig --name <cluster-name>
```

## State Management

This project uses remote state management with:

- S3 bucket for state storage
- DynamoDB table for state locking

## Security Considerations

- EKS cluster with private endpoint
- Proper IAM roles with least privilege
- Network security groups with restricted access
- Encrypted storage for sensitive data

## Tagging Strategy

All resources are tagged with:

- Project: AB3
- Environment: (dev/staging/prod)
- ManagedBy: terraform

## Contributing

Please follow the established code structure and naming conventions when contributing to this project.