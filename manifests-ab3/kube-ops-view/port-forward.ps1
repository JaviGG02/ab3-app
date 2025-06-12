# PowerShell script to access kube-ops-view using port-forwarding
Write-Host "Setting up port-forwarding to access kube-ops-view..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Check if kube-ops-view pod is running
$podName = kubectl get pods -n kube-ops-view -l "application=kube-ops-view,component=frontend" -o jsonpath="{.items[0].metadata.name}" 2>$null

if ([string]::IsNullOrEmpty($podName)) {
    Write-Host "Error: kube-ops-view pod not found. Make sure it's deployed correctly." -ForegroundColor Red
    Write-Host "Run ./install.ps1 to deploy kube-ops-view first." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found kube-ops-view pod: $podName" -ForegroundColor Green
Write-Host "Starting port-forwarding from localhost:8080 to the pod..." -ForegroundColor Cyan
Write-Host "Access kube-ops-view at: http://localhost:8080" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop port-forwarding" -ForegroundColor Yellow

# Start port-forwarding
kubectl port-forward -n kube-ops-view $podName 8080:8080