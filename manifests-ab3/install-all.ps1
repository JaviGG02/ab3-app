# PowerShell script to install all microservices
Write-Host "Installing all microservices to your Kubernetes cluster..." -ForegroundColor Cyan

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short
    Write-Host "Using kubectl: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: kubectl is not installed or not in PATH. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Install catalog service
Write-Host "`nInstalling Catalog service..." -ForegroundColor Cyan
Push-Location -Path ".\catalog"
& .\install.ps1
Pop-Location

# Install carts service
Write-Host "`nInstalling Carts service..." -ForegroundColor Cyan
Push-Location -Path ".\carts"
& .\install.ps1
Pop-Location

# Install orders service
Write-Host "`nInstalling Orders service..." -ForegroundColor Cyan
Push-Location -Path ".\orders"
& .\install.ps1
Pop-Location

# Install checkout service
Write-Host "`nInstalling Checkout service..." -ForegroundColor Cyan
Push-Location -Path ".\checkout"
& .\install.ps1
Pop-Location

# Install UI service
Write-Host "`nInstalling UI service..." -ForegroundColor Cyan
Push-Location -Path ".\ui"
& .\install.ps1
Pop-Location

Write-Host "`nAll microservices have been deployed to your cluster." -ForegroundColor Green
Write-Host "You can access the UI through the ALB Ingress once it's provisioned." -ForegroundColor Green