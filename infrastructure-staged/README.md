# Infrastructure Staged Deployment

This directory contains the staged Terraform infrastructure deployment for the AB3 application on AWS EKS. The infrastructure is deployed in four sequential stages, each building upon the previous stage.

## Deployment Architecture

The staged deployment approach ensures proper dependency management and allows for incremental infrastructure provisioning:

```
01-foundation → 02-eks-cluster → 03-eks-addons → 04-web-layer
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- kubectl installed and configured
- Bash shell environment

## Deployment Stages

### Stage 1: Foundation (01-foundation/)

**Purpose**: Establishes the core infrastructure foundation

**Components**:
- VPC with public and private subnets
- Internet Gateway and NAT Gateways
- IAM roles and policies for EKS
- Aurora PostgreSQL database cluster
- Security groups and networking rules

**Files**:
- `vpc.tf` - VPC and networking configuration
- `iam.tf` - IAM roles and policies
- `aurora.tf` - Aurora database cluster
- `main.tf` - Provider and general configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values for next stages

### Stage 2: EKS Cluster (02-eks-cluster/)

**Purpose**: Creates the EKS cluster and managed node groups

**Components**:
- EKS cluster with specified Kubernetes version
- Managed node groups with auto-scaling
- EKS cluster security groups
- Node group IAM roles and policies

**Files**:
- `eks.tf` - EKS cluster and node group configuration
- `main.tf` - Provider and data sources
- `variables.tf` - Input variables
- `outputs.tf` - Cluster information for next stages

### Stage 3: EKS Add-ons (03-eks-addons/)

**Purpose**: Installs essential EKS add-ons and monitoring components

**Components**:
- AWS Load Balancer Controller
- EBS CSI Driver
- Metrics Server
- CoreDNS
- kube-proxy
- VPC CNI

**Files**:
- `addons.tf` - EKS add-ons configuration
- `main.tf` - Provider and data sources
- `variables.tf` - Input variables
- `outputs.tf` - Add-on information

**⚠️ Important**: After deploying this stage, you must execute the metrics server patch script:
```bash
./patch-metrics-server.sh
```

### Stage 4: Web Layer (04-web-layer/)

**Purpose**: Provisions web-facing infrastructure components

**Components**:
- Application Load Balancer (ALB)
- Target groups and listeners
- Security groups for web traffic
- Route 53 DNS records (if configured)

**Files**:
- `web-layer.tf` - ALB and web infrastructure
- `main.tf` - Provider and data sources
- `variables.tf` - Input variables
- `outputs.tf` - Web layer endpoints and information

## Deployment Instructions

### Step-by-Step Deployment

**Important**: Each stage must be deployed sequentially and requires `terraform init` before deployment.

#### 1. Deploy Foundation
```bash
cd 01-foundation/
terraform init
terraform plan
terraform apply
```

#### 2. Deploy EKS Cluster
```bash
cd ../02-eks-cluster/
terraform init
terraform plan
terraform apply
```

#### 3. Deploy EKS Add-ons
```bash
cd ../03-eks-addons/
terraform init
terraform plan
terraform apply
```

#### 4. Patch Metrics Server (Required)
After stage 3 deployment, execute the metrics server patch:
```bash
cd ../
./patch-metrics-server.sh
```

#### 5. Deploy Web Layer
```bash
cd 04-web-layer/
terraform init
terraform plan
terraform apply
```

### Cleanup

To destroy the infrastructure, reverse the deployment order:

```bash
# Destroy in reverse order
cd 04-web-layer/ && terraform destroy
cd ../03-eks-addons/ && terraform destroy
cd ../02-eks-cluster/ && terraform destroy
cd ../01-foundation/ && terraform destroy
```

## Variables and Configuration

Each stage accepts various input variables. Check the `variables.tf` file in each directory for available configuration options. Common variables include:

- `region` - AWS region for deployment
- `cluster_name` - EKS cluster name
- `node_group_instance_types` - EC2 instance types for worker nodes
- `desired_capacity` - Number of worker nodes

## Outputs

Each stage produces outputs that are consumed by subsequent stages. Key outputs include:

- **Stage 1**: VPC ID, subnet IDs, IAM role ARNs, database endpoints
- **Stage 2**: Cluster endpoint, cluster security group ID, node group ARNs
- **Stage 3**: Add-on status and configurations
- **Stage 4**: Load balancer DNS names, target group ARNs

## Security Considerations

- All IAM roles follow the principle of least privilege
- Security groups restrict access to necessary ports only
- EKS cluster endpoint can be configured for private access
- Database is deployed in private subnets
- Encryption at rest and in transit is enabled where applicable

## Monitoring and Logging

You have to go to the console, to your EKS cluster and enable the cloudwatch observability add-on