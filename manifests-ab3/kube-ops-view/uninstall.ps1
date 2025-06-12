# PowerShell script to uninstall kube-ops-view
Write-Host "Uninstalling kube-ops-view from your Kubernetes cluster..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Delete all resources using kustomize
Write-Host "Deleting kube-ops-view resources using kustomize..." -ForegroundColor Cyan
kubectl delete -k . --ignore-not-found

# Check if there are any remaining resources in the namespace
$remainingResources = kubectl get all -n kube-ops-view 2>$null
if ($remainingResources) {
    Write-Host "WARNING: Some resources still exist in the kube-ops-view namespace:" -ForegroundColor Yellow
    kubectl get all -n kube-ops-view
    
    $forceDelete = Read-Host "Do you want to force delete the namespace? (y/n)"
    if ($forceDelete -eq "y" -or $forceDelete -eq "Y") {
        Write-Host "Force deleting kube-ops-view namespace..." -ForegroundColor Cyan
        kubectl delete namespace kube-ops-view --force --grace-period=0
    }
}

# Ask if metrics-server should be removed
$removeMetricsServer = Read-Host "Do you want to remove metrics-server as well? (y/n)"
if ($removeMetricsServer -eq "y" -or $removeMetricsServer -eq "Y") {
    Write-Host "Removing metrics-server..." -ForegroundColor Cyan
    kubectl delete -f metrics-server.yaml --ignore-not-found
    Write-Host "metrics-server has been removed." -ForegroundColor Green
} else {
    Write-Host "Keeping metrics-server installed." -ForegroundColor Green
}

# Check if the namespace still exists
$namespaceExists = kubectl get namespace kube-ops-view 2>$null
if (-not $namespaceExists) {
    Write-Host "kube-ops-view namespace has been successfully removed." -ForegroundColor Green
}

Write-Host "kube-ops-view has been uninstalled from your cluster." -ForegroundColor Green