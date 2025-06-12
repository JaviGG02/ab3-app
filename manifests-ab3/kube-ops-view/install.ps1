# PowerShell script to install kube-ops-view
Write-Host "Installing kube-ops-view to your Kubernetes cluster..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Apply metrics-server first if it doesn't exist
Write-Host "Checking if metrics-server is already installed..." -ForegroundColor Cyan
$metricsServerDeployment = kubectl get deployment -n kube-system metrics-server 2>$null
if (-not $metricsServerDeployment) {
    Write-Host "Installing metrics-server..." -ForegroundColor Cyan
    kubectl apply -f metrics-server.yaml
    
    Write-Host "Waiting for metrics-server deployment to be ready..." -ForegroundColor Cyan
    kubectl -n kube-system rollout status deployment metrics-server --timeout=60s
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARNING: metrics-server deployment timed out. Continuing anyway..." -ForegroundColor Yellow
    } else {
        Write-Host "metrics-server successfully deployed!" -ForegroundColor Green
    }
} else {
    Write-Host "metrics-server is already installed, skipping..." -ForegroundColor Green
}

# Create namespace if it doesn't exist
Write-Host "Creating kube-ops-view namespace if it doesn't exist..." -ForegroundColor Cyan
kubectl apply -f namespace.yaml

# Apply RBAC permissions
Write-Host "Applying RBAC permissions..." -ForegroundColor Cyan
kubectl apply -f rbac.yaml

# Apply all resources using kustomize
Write-Host "Applying kube-ops-view resources using kustomize..." -ForegroundColor Cyan
kubectl apply -k .

Write-Host "Waiting for kube-ops-view deployment to be ready..." -ForegroundColor Cyan
kubectl -n kube-ops-view rollout status deployment kube-ops-view --timeout=90s

Write-Host "Waiting for kube-ops-view-redis deployment to be ready..." -ForegroundColor Cyan
kubectl -n kube-ops-view rollout status deployment kube-ops-view-redis --timeout=60s

# Get the service details
Write-Host "Checking LoadBalancer service status..." -ForegroundColor Cyan
kubectl get service kube-ops-view -n kube-ops-view

Write-Host "`nkube-ops-view installation complete!" -ForegroundColor Green
Write-Host "`nAccess options:" -ForegroundColor Cyan
Write-Host "1. LoadBalancer URL (may take a few minutes to provision):" -ForegroundColor Cyan
Write-Host "   kubectl get service kube-ops-view -n kube-ops-view -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`n" -ForegroundColor White

Write-Host "2. Port forwarding (for immediate local access):" -ForegroundColor Cyan
Write-Host "   Run: ./port-forward.ps1`n" -ForegroundColor White

Write-Host "Note: It may take a few minutes for metrics to be collected and displayed." -ForegroundColor Yellow