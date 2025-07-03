# AB3-App Project

This project contains the infrastructure and application manifests for the AB3 application deployment on AWS EKS.

## Project Structure

```
ab3-app/
├── infrastructure-staged/     # Staged Terraform infrastructure deployment
│   ├── 01-foundation/        # VPC, IAM, and Aurora database
│   ├── 02-eks-cluster/       # EKS cluster configuration
│   ├── 03-eks-addons/        # EKS add-ons and extensions
│   ├── 04-web-layer/         # Web layer infrastructure
│   └── patch-metrics-server.sh  # Metrics server patch script
├── infrastructure-ab3/       # Alternative infrastructure configuration
├── manifests-ab3/           # Kubernetes manifests and applications
│   ├── argocd/              # ArgoCD configuration
│   ├── eks-automode-config/ # EKS auto-mode configuration
│   ├── kube-ops-view/       # Kubernetes operations view
│   └── retail-sample-app/   # Sample retail application
└── stress-tests/            # Performance and stress testing tools
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl configured
- Bash shell environment

## Deployment Overview

The infrastructure is deployed in a staged approach using Terraform modules. Each stage must be deployed sequentially as they have dependencies on previous stages.

### Infrastructure Deployment Stages

1. **Foundation** - Core networking, IAM roles, and database
2. **EKS Cluster** - Kubernetes cluster setup
3. **EKS Add-ons** - Essential cluster extensions and monitoring
4. **Web Layer** - Application load balancers and web infrastructure

## Quick Start

For detailed deployment instructions, see the [infrastructure-staged documentation](./infrastructure-staged/README.md).

## Components

### Infrastructure (Terraform)
- **infrastructure-staged/**: Production-ready staged deployment approach

### Applications (Kubernetes)
- **manifests-ab3/**: Kubernetes application manifests and configurations
- **stress-tests/**: Performance testing and load generation tools

## Important Notes

- All Terraform deployments require `terraform init` before `terraform apply`
- Stages must be deployed sequentially (01 → 02 → 03 → 04)
- After deploying stage 03 (EKS add-ons), the metrics server patch script must be executed
- Ensure proper AWS credentials and permissions before deployment

## Support

For issues or questions regarding this deployment, refer to the individual component documentation or contact the infrastructure team.
