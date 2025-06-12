# PowerShell script to uninstall Orders component
Write-Host "Uninstalling Orders component from your Kubernetes cluster..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Delete all resources using kustomize
Write-Host "Deleting Orders resources using kustomize..." -ForegroundColor Cyan
kubectl delete -k . --ignore-not-found

# Check if there are any remaining resources in the namespace
$remainingResources = kubectl get all -n orders 2>$null
if ($remainingResources) {
    Write-Host "WARNING: Some resources still exist in the orders namespace:" -ForegroundColor Yellow
    kubectl get all -n orders
    
    $forceDelete = Read-Host "Do you want to force delete the namespace? (y/n)"
    if ($forceDelete -eq "y" -or $forceDelete -eq "Y") {
        Write-Host "Force deleting orders namespace..." -ForegroundColor Cyan
        kubectl delete namespace orders --force --grace-period=0
    }
}

Write-Host "Orders component has been uninstalled from your cluster." -ForegroundColor Green