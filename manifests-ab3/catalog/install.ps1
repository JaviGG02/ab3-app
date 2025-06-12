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

# Apply all resources using kustomize
Write-Host "Applying Catalog resources using kustomize..." -ForegroundColor Cyan
kubectl apply -k .

# Check if the deployment was successful
Write-Host "Checking deployment status..." -ForegroundColor Cyan
kubectl rollout status deployment/catalog -n catalog

Write-Host "Catalog component has been deployed to your cluster." -ForegroundColor Green