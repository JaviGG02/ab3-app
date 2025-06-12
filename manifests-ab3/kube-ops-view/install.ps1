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

# Check if AWS Load Balancer Controller is installed
Write-Host "Checking for AWS Load Balancer Controller..." -ForegroundColor Cyan
$ingressControllerPods = kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -o name 2>$null
if (-not $ingressControllerPods) {
    Write-Host "WARNING: AWS Load Balancer Controller is not installed. The Ingress will not work." -ForegroundColor Yellow
    Write-Host "Please ensure AWS Load Balancer Controller is installed via Terraform." -ForegroundColor Yellow
    
    $continue = Read-Host "Do you want to continue anyway? (y/n)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "Installation aborted." -ForegroundColor Red
        exit 1
    }
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

# Wait for ingress to be created
Write-Host "Checking ingress status (this may take a few minutes to provision)..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host "Ingress status:" -ForegroundColor Cyan
kubectl get ingress -n kube-ops-view

Write-Host "`nkube-ops-view installation complete!" -ForegroundColor Green
Write-Host "`nAccess options:" -ForegroundColor Cyan
Write-Host "1. ALB URL (may take 3-5 minutes to provision):" -ForegroundColor Cyan
Write-Host "   kubectl get ingress -n kube-ops-view -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'`n" -ForegroundColor White

Write-Host "2. Port forwarding (for immediate local access):" -ForegroundColor Cyan
Write-Host "   Run: ./port-forward.ps1`n" -ForegroundColor White

Write-Host "Note: It may take a few minutes for metrics to be collected and displayed." -ForegroundColor Yellow