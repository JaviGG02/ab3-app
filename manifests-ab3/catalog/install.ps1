# PowerShell script to install Catalog component
Write-Host "Installing Catalog component to your Kubernetes cluster..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# First, ensure the catalog namespace exists
Write-Host "Ensuring catalog namespace exists..." -ForegroundColor Cyan
kubectl create namespace catalog --dry-run=client -o yaml | kubectl apply -f -

# Check if catalog-db-secret exists
$secretExists = kubectl get secret catalog-db-secret -n catalog --ignore-not-found
if (-not $secretExists) {
    Write-Host "WARNING: catalog-db-secret not found in catalog namespace." -ForegroundColor Yellow
    Write-Host "Make sure to apply the infrastructure-ab3/catalog-secret.tf first." -ForegroundColor Yellow
}

# Update the catalog-db-service.yaml with Aurora endpoint
Write-Host "Updating catalog-db-service.yaml with Aurora endpoint..." -ForegroundColor Cyan
./update-catalog-db-service.ps1

# Apply all resources using kustomize
Write-Host "Applying Catalog resources using kustomize..." -ForegroundColor Cyan
kubectl apply -k .

# Check if the deployment was successful
Write-Host "Checking deployment status..." -ForegroundColor Cyan
kubectl rollout status deployment/catalog -n catalog

Write-Host "Catalog component has been deployed to your cluster." -ForegroundColor Green