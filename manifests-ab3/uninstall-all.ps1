# PowerShell script to uninstall all microservices
Write-Host "Uninstalling all microservices from your Kubernetes cluster..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Function to force delete a namespace if it gets stuck
function Force-DeleteNamespace {
    param (
        [string]$namespace
    )
    
    Write-Host "Checking if namespace $namespace exists and is stuck..." -ForegroundColor Yellow
    $nsStatus = kubectl get namespace $namespace --ignore-not-found -o jsonpath="{.status.phase}" 2>$null
    
    if ($nsStatus -eq "Terminating") {
        Write-Host "Namespace $namespace is stuck in Terminating state. Forcing deletion..." -ForegroundColor Red
        
        # Export namespace to JSON
        kubectl get namespace $namespace -o json | Out-File -FilePath "$namespace-ns.json"
        
        # Remove finalizers using ConvertFrom-Json and ConvertTo-Json
        $json = Get-Content -Raw -Path "$namespace-ns.json" | ConvertFrom-Json
        $json.spec.finalizers = @()
        $json | ConvertTo-Json -Depth 100 | Out-File -FilePath "$namespace-ns-nofinalizers.json"
        
        # Use kubectl replace to update the namespace without finalizers
        kubectl replace --raw "/api/v1/namespaces/$namespace/finalize" -f "$namespace-ns-nofinalizers.json"
        
        # Clean up temporary files
        Remove-Item -Path "$namespace-ns.json" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$namespace-ns-nofinalizers.json" -Force -ErrorAction SilentlyContinue
        
        Write-Host "Forced deletion of namespace $namespace completed." -ForegroundColor Green
    }
}

# Uninstall UI service first
Write-Host "`nUninstalling UI service..." -ForegroundColor Cyan
Push-Location -Path ".\ui"
& .\uninstall.ps1
Pop-Location
Force-DeleteNamespace -namespace "ui"

# Uninstall checkout service
Write-Host "`nUninstalling Checkout service..." -ForegroundColor Cyan
Push-Location -Path ".\checkout"
& .\uninstall.ps1
Pop-Location
Force-DeleteNamespace -namespace "checkout"

# Uninstall orders service
Write-Host "`nUninstalling Orders service..." -ForegroundColor Cyan
Push-Location -Path ".\orders"
& .\uninstall.ps1
Pop-Location
Force-DeleteNamespace -namespace "orders"

# Uninstall carts service
Write-Host "`nUninstalling Carts service..." -ForegroundColor Cyan
Push-Location -Path ".\carts"
& .\uninstall.ps1
Pop-Location
Force-DeleteNamespace -namespace "carts"

# Uninstall catalog service
Write-Host "`nUninstalling Catalog service..." -ForegroundColor Cyan
Push-Location -Path ".\catalog"
& .\uninstall.ps1
Pop-Location
Force-DeleteNamespace -namespace "catalog"

Write-Host "`nAll microservices have been uninstalled from your cluster." -ForegroundColor Green