# AWS Infrastructure for Retail Store Sample Application

This repository contains the infrastructure code for deploying the retail store sample application. The infrastructure is organized into three deployment stages for better management and dependency handling.

## Repository Structure

```
infrastructure-ab3/
├── modules/              # Reusable Terraform modules
│   ├── vpc/             # VPC and networking
│   ├── eks/             # EKS cluster configuration
│   ├── aurora/          # Aurora database
│   ├── retail-app/      # Retail application deployment
│   └── web-layer/       # Web layer and CDN
├── stages/              # Deployment stages
│   ├── 01-core-infra/   # Core infrastructure (VPC, EKS, Aurora)
│   ├── 02-retail-app/   # Retail application deployment
│   └── 03-web-layer/    # Web layer deployment
└── scripts/             # Utility scripts
```

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.3
3. kubectl
4. helm
5. AWS Secrets Manager secret named "ab3/aurora/credentials" with the following structure:
   ```json
   {
     "username": "admin",
     "password": "your-secure-password",
     "dbname": "retaildb"
   }
   ```

You can create this secret using the AWS CLI:
```bash
aws secretsmanager create-secret \
    --name ab3/aurora/credentials \
    --secret-string '{"username":"admin","password":"your-secure-password","dbname":"retaildb"}'
```

## Deployment Process

The infrastructure is deployed in three stages:

### Stage 1: Core Infrastructure

This stage deploys the foundational AWS infrastructure:
- VPC and networking components
- EKS cluster
- Aurora database cluster

```bash
cd stages/01-core-infra
terraform init
terraform plan
terraform apply
```

Verify the deployment:
```bash
# Verify VPC and subnets
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${CLUSTER_NAME}"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}"

# Verify EKS cluster
aws eks describe-cluster --name ${CLUSTER_NAME}
kubectl get nodes  # Should show AutoMode nodes

# Verify Aurora cluster
aws rds describe-db-clusters --db-cluster-identifier ${CLUSTER_NAME}-aurora
```

### Stage 2: Retail Application

This stage deploys the retail store application to the EKS cluster:
- Application namespaces
- Kubernetes deployments and services
- Database configurations

```bash
cd ../02-retail-app
terraform init
terraform plan
terraform apply
```

Verify the deployment:
```bash
# Verify Kubernetes resources
kubectl get pods -A  # Check all pods are running
kubectl get services # Verify all services are created
kubectl get secrets -n default # Verify database secrets exist

# Verify database connectivity
kubectl exec -it $(kubectl get pod -l app=catalog -o jsonpath='{.items[0].metadata.name}') -- curl localhost:8080/health
```

### Stage 3: Web Layer

This stage deploys the web layer and CDN:
- CloudFront distribution
- SSL/TLS certificates
- DNS configurations
- WAF configuration

```bash
cd ../03-web-layer
terraform init
terraform plan
terraform apply
```

Verify the deployment:
```bash
# Verify CloudFront distribution
aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='UI Distribution']"

# Verify WAF ACL
aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1
aws wafv2 list-web-acls --scope REGIONAL --region ${AWS_REGION}

# Verify ALB and WAF association
aws elbv2 describe-load-balancers --names ${CLUSTER_NAME}*
aws wafv2 list-web-acl-associations --scope REGIONAL --region ${AWS_REGION}

# Test the application
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)
curl -v https://${CLOUDFRONT_URL}/health
```

## State Management

Each stage maintains its own state file in an S3 backend. The stages use remote state data sources to access outputs from previous stages.

## Configuration

1. Create an S3 bucket for Terraform state:
```bash
aws s3 mb s3://your-terraform-state-bucket
```

2. Update the backend configuration in each stage's main.tf with your S3 bucket details.

3. Configure variables for each stage in their respective terraform.tfvars files.

## Cleanup

To destroy the infrastructure, remove the stages in reverse order:

```bash
cd stages/03-web-layer
terraform destroy

cd ../02-retail-app
terraform destroy

cd ../01-core-infra
terraform destroy
```

## Contributing

Please see the CONTRIBUTING.md file for guidelines on contributing to this project.