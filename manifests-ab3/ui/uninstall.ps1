# PowerShell script to uninstall UI component
Write-Host "Uninstalling UI component from your Kubernetes cluster..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Delete all resources using kustomize
Write-Host "Deleting UI resources using kustomize..." -ForegroundColor Cyan
kubectl delete -k . --ignore-not-found

# Ensure the ingress is deleted
Write-Host "Ensuring ingress is deleted..." -ForegroundColor Cyan
kubectl delete ingress ui -n ui --ignore-not-found

# Check if there are any remaining resources in the namespace
$remainingResources = kubectl get all -n ui 2>$null
if ($remainingResources) {
    Write-Host "WARNING: Some resources still exist in the ui namespace:" -ForegroundColor Yellow
    kubectl get all -n ui
    
    $forceDelete = Read-Host "Do you want to force delete the namespace? (y/n)"
    if ($forceDelete -eq "y" -or $forceDelete -eq "Y") {
        Write-Host "Force deleting ui namespace..." -ForegroundColor Cyan
        kubectl delete namespace ui --force --grace-period=0
    }
}

# Check if the namespace still exists
$namespaceExists = kubectl get namespace ui 2>$null
if (-not $namespaceExists) {
    Write-Host "UI namespace has been successfully removed." -ForegroundColor Green
}

Write-Host "UI component has been uninstalled from your cluster." -ForegroundColor Green