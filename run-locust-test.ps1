# PowerShell script to run Locust load test against CloudFront distribution

# Configuration - Update these values
$CLOUDFRONT_URL = "https://your-distribution-id.cloudfront.net" # Replace with your CloudFront URL

# Function to check if Python is installed
function Check-Python {
    try {
        $pythonVersion = & python --version 2>&1
        if ($pythonVersion -match "Python") {
            Write-Host "Python is installed: $pythonVersion"
            return $true
        }
    }
    catch {
        Write-Host "Python is not installed or not in PATH."
        Write-Host "Please download and install Python from https://www.python.org/downloads/"
        return $false
    }
}

# Function to check if Locust is installed
function Check-Locust {
    try {
        $locustVersion = & locust --version 2>&1
        if ($locustVersion -match "Locust") {
            Write-Host "Locust is installed: $locustVersion"
            return $true
        }
    }
    catch {
        Write-Host "Locust is not installed."
        $installLocust = Read-Host "Do you want to install Locust? (y/n)"
        if ($installLocust -eq "y") {
            Write-Host "Installing Locust..."
            & pip install locust
            return $true
        }
        return $false
    }
}

# Function to run Locust test
function Run-LocustTest {
    param (
        [string]$host
    )
    
    Write-Host "Running Locust test against $host..."
    
    # Start Locust in headless mode
    $env:LOCUST_HOST = $host
    Start-Process -FilePath "locust" -ArgumentList "--headless", "-u", "100", "-r", "10", "--run-time", "5m" -NoNewWindow
    
    # Also open the Locust web UI for interactive control
    Start-Process "http://localhost:8089"
    & locust
}

# Function to run Locust with web UI
function Run-LocustWebUI {
    param (
        [string]$host
    )
    
    Write-Host "Starting Locust web UI..."
    Write-Host "Target host: $host"
    Write-Host "Open your browser to http://localhost:8089 to control the test"
    
    $env:LOCUST_HOST = $host
    & locust
}

# Function to monitor EKS scaling during the test
function Monitor-EKSScaling {
    Write-Host "`nMonitoring EKS scaling (Press Ctrl+C to stop)..."
    
    try {
        while ($true) {
            Write-Host "`n--- $(Get-Date) ---"
            
            # Get node status
            Write-Host "`nNode Status:"
            kubectl get nodes
            
            # Get pod status
            Write-Host "`nPod Status:"
            kubectl get pods --all-namespaces | Select-String -Pattern "Running|Pending"
            
            # Get HPA status if any
            Write-Host "`nHPA Status:"
            kubectl get hpa --all-namespaces
            
            # Wait before checking again
            Start-Sleep -Seconds 15
        }
    }
    finally {
        Write-Host "`nStopped monitoring."
    }
}

# Main menu
function Show-Menu {
    Write-Host "`n=== CloudFront Load Testing Menu (Locust) ==="
    Write-Host "1. Configure CloudFront URL"
    Write-Host "2. Run load test with web UI"
    Write-Host "3. Monitor EKS scaling"
    Write-Host "4. Exit"
    
    $choice = Read-Host "Enter your choice"
    
    switch ($choice) {
        "1" {
            $CLOUDFRONT_URL = Read-Host "Enter your CloudFront URL (e.g., https://d123456abcdef8.cloudfront.net)"
            Write-Host "CloudFront URL updated to: $CLOUDFRONT_URL"
        }
        "2" {
            if ([string]::IsNullOrWhiteSpace($CLOUDFRONT_URL) -or $CLOUDFRONT_URL -eq "https://your-distribution-id.cloudfront.net") {
                Write-Host "Please configure your CloudFront URL first (option 1)."
            }
            else {
                if (Check-Python -and Check-Locust) {
                    Run-LocustWebUI -host $CLOUDFRONT_URL
                }
            }
        }
        "3" { Monitor-EKSScaling }
        "4" { return $false }
        default { Write-Host "Invalid choice. Try again." }
    }
    
    return $true
}

# Create requirements.txt file
function Create-RequirementsFile {
    $requirementsContent = @"
locust==2.15.1
"@
    $requirementsContent | Out-File -FilePath "requirements.txt" -Encoding UTF8
    Write-Host "Created requirements.txt file"
}

# Main script
Write-Host "CloudFront Load Testing Tool (Locust)"
Write-Host "===================================="
Write-Host "This script will help you generate load against your CloudFront distribution"
Write-Host "and monitor how your EKS cluster auto-scales in response."

# Create requirements.txt
Create-RequirementsFile

$continue = $true
while ($continue) {
    $continue = Show-Menu
}

Write-Host "Exiting script."