# Retail Sample Application with GitOps-based Deployment on EKS

A comprehensive retail microservices application deployed on Amazon EKS using ArgoCD for GitOps. The application provides a complete e-commerce solution with UI, catalog, cart, checkout, and order management capabilities, featuring automatic scaling and multi-architecture support (AMD64 and ARM64/Graviton).

The application demonstrates modern cloud-native practices including:
- Microservices architecture with independent scaling
- GitOps-based continuous deployment using ArgoCD
- Multi-architecture support with AMD64 and ARM64/Graviton nodes
- Infrastructure as Code using Kubernetes manifests
- Automatic scaling based on resource utilization
- Persistent storage using PostgreSQL, Redis, and DynamoDB
- Message queuing with RabbitMQ
- Operational visibility through kube-ops-view

## Repository Structure
```
manifests-ab3/
├── argocd/                     # ArgoCD deployment and application configurations
│   ├── retail-apps/           # Individual retail application components
│   └── argocd-key.ps1         # Script for ArgoCD SSH key setup
├── eks-automode-config/        # EKS node configuration for AMD64 and Graviton
├── kube-ops-view/             # Kubernetes cluster visualization tool
└── retail-sample-app/         # Core retail application components
    ├── ui/                    # Frontend UI service
    ├── catalog/               # Product catalog service
    ├── carts/                # Shopping cart service with DynamoDB
    ├── checkout/             # Checkout service with Redis
    └── orders/               # Order management with PostgreSQL and RabbitMQ
```

## Usage Instructions
### Prerequisites
- Amazon EKS cluster
- kubectl configured for your EKS cluster
- ArgoCD CLI
- Git credentials with access to the repository
- AWS CLI configured with appropriate permissions

### Installation

1. Deploy ArgoCD:
```bash
kubectl create namespace argocd
kubectl apply -k manifests-ab3/argocd
```

2. Set up ArgoCD SSH keys:
```powershell
./manifests-ab3/argocd/argocd-key.ps1
```

3. Configure EKS node pools:
```bash
kubectl apply -k manifests-ab3/eks-automode-config
```

4. Deploy the visualization tool:
```bash
kubectl apply -k manifests-ab3/kube-ops-view
```

### Quick Start
1. Access ArgoCD UI:
```bash
kubectl get svc argocd-server -n argocd
```
Use the external IP address to access the ArgoCD UI.

2. Log in to ArgoCD:
- Username: admin
- Password: (Get initial password using the command below)
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

3. The retail applications will be automatically synchronized by ArgoCD.

### More Detailed Examples
1. Accessing the UI:
```bash
kubectl get svc ui -n default
```
Use the external IP to access the retail store UI.

2. Scaling services:
```bash
kubectl get hpa
```
Services will automatically scale based on CPU utilization.

### Troubleshooting
1. ArgoCD Sync Issues:
- Check application status:
```bash
argocd app get retail-ui
```
- Force sync if needed:
```bash
argocd app sync retail-ui
```

2. Pod Issues:
- Check pod status:
```bash
kubectl get pods
kubectl describe pod <pod-name>
```

3. Service Connectivity:
- Verify service endpoints:
```bash
kubectl get endpoints
```
- Test service connectivity:
```bash
kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- curl http://service-name
```

## Data Flow
The retail application processes customer interactions through a series of microservices, from browsing products to completing orders.

```ascii
User -> UI -> Catalog
                 |
Cart <-> DynamoDB
  |
Checkout <-> Redis
  |
Orders <-> PostgreSQL
  |
RabbitMQ (Event Bus)
```

Component interactions:
1. UI service provides the frontend interface and coordinates with other services
2. Catalog service manages product information
3. Cart service stores shopping cart data in DynamoDB
4. Checkout service manages checkout process with Redis for session storage
5. Orders service handles order processing with PostgreSQL for persistence
6. RabbitMQ handles asynchronous communication between services

## Infrastructure

### EKS Node Pools
- NodePool `amd64`: On-demand AMD64 instances (c, t, m, r families)
- NodePool `graviton`: On-demand ARM64 instances (c, t, m, r families)

### ArgoCD Resources
- Namespace: `argocd`
- Applications:
  - retail-ui
  - retail-carts
  - retail-catalog
  - retail-checkout
  - retail-orders

### Services
- LoadBalancer for ArgoCD server
- ClusterIP services for internal communication
- Ingress for UI access

### Storage
- PostgreSQL StatefulSet for orders
- Redis Deployments for checkout
- DynamoDB for cart storage

### Note

If the ArgoCD load balancer DNS doesn't resolve at the first deployment. Comment out the Loadalancer patch in the kustomization file. Then apply the change (ALB will be removed), uncomment the same lines and apply for a second time. Now a Classic LB will be deployed and the DNS name will be available