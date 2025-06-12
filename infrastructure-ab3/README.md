# AB3 Infrastructure

This repository contains Terraform code for deploying a comprehensive AWS infrastructure for the AB3 application, including EKS with Karpenter, Aurora MySQL, and ArgoCD integration.

## Architecture

The infrastructure consists of the following components:

- **VPC**: A dedicated VPC with public and private subnets across multiple availability zones
- **EKS Cluster**: Managed Kubernetes cluster with proper IAM roles and security configurations
- **Karpenter**: Auto-scaling solution for Kubernetes with support for AMD and ARM processors, as well as spot and on-demand instances
- **Aurora MySQL**: Managed MySQL-compatible database for application data

## Directory Structure

```
ab3-app/
├── infrastructure-ab3/    # Terraform infrastructure code
│   ├── main.tf           # Provider configuration and common resources
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── vpc.tf            # VPC configuration
│   ├── eks.tf           # EKS cluster configuration
│   ├── automode.tf       # EKS AutoMode configuration
│   ├── aurora.tf         # Aurora MySQL configuration
│   └── upload_db_secrets.sh # Database secrets setup script
└── eks-automode-config/  # EKS AutoMode configuration files
    ├── nodeclass-basic.yaml
    ├── nodepool-amd64.yaml
    └── nodepool-graviton.yaml

```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.3
- kubectl
- helm
- AWS Secrets Manager access for database credentials
- upload_db_secrets.sh script executed (required for Aurora MySQL deployment)

## Deployment Process

The deployment process follows a specific order to ensure proper resource creation and dependencies:

1. **Database Secrets Setup**:
   ```bash
   #!/bin/bash
   
   # Set your database credentials
   DB_NAME="ab3db"
   DB_USERNAME="admin"
   DB_PASSWORD="<your-secure-password>"
   
   # Create JSON payload
   SECRET_JSON=$(jq -n \
   --arg username "$DB_USERNAME" \
   --arg password "$DB_PASSWORD" \
   --arg dbname "$DB_NAME" \
   '{username: $username, password: $password, dbname: $dbname}')

   # Try to create the secret
   CREATE_RESULT=$(aws secretsmanager create-secret \
   --name "ab3/aurora/credentials" \
   --description "Aurora MySQL database credentials" \
   --secret-string "$SECRET_JSON" 2>&1)

   # Check if the secret already exists
   if echo "$CREATE_RESULT" | grep -q "ResourceExistsException"; then
   aws secretsmanager update-secret \
      --secret-id "ab3/aurora/credentials" \
      --secret-string "$SECRET_JSON"
   echo "Database credentials updated in AWS Secrets Manager"
   else
   echo "Database credentials uploaded to AWS Secrets Manager"
   fi
   ```
   This creates the required secrets in AWS Secrets Manager for Aurora MySQL credentials.

2. **Deploy Infrastructure**:
   ```bash
   cd infrastructure-ab3
   terraform init
   terraform plan
   terraform apply
   ```

3. **Kubernetes Configuration**:
   ```bash
   # Configure kubectl to connect to the EKS cluster
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