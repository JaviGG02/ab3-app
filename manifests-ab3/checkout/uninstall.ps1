# PowerShell script to uninstall Checkout component
Write-Host "Uninstalling Checkout component from your Kubernetes cluster..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Delete all resources using kustomize
Write-Host "Deleting Checkout resources using kustomize..." -ForegroundColor Cyan
kubectl delete -k . --ignore-not-found

# Force delete the namespace without prompting
Write-Host "Force deleting checkout namespace..." -ForegroundColor Cyan
kubectl delete namespace checkout --force --grace-period=0

# If namespace is still stuck, use the patch method to remove finalizers
$namespaceExists = kubectl get namespace checkout --ignore-not-found
if ($namespaceExists) {
    Write-Host "Namespace still exists, removing finalizers..." -ForegroundColor Yellow
    
    # Export namespace to JSON
    kubectl get namespace checkout -o json | Out-File -FilePath checkout-ns.json
    
    # Remove finalizers using ConvertFrom-Json and ConvertTo-Json
    $json = Get-Content -Raw -Path checkout-ns.json | ConvertFrom-Json
    $json.spec.finalizers = @()
    $json | ConvertTo-Json -Depth 100 | Out-File -FilePath checkout-ns-nofinalizers.json
    
    # Use kubectl replace to update the namespace without finalizers
    kubectl replace --raw "/api/v1/namespaces/checkout/finalize" -f checkout-ns-nofinalizers.json
    
    # Clean up temporary files
    Remove-Item -Path checkout-ns.json -Force -ErrorAction SilentlyContinue
    Remove-Item -Path checkout-ns-nofinalizers.json -Force -ErrorAction SilentlyContinue
}

Write-Host "Checkout component has been uninstalled from your cluster." -ForegroundColor Green