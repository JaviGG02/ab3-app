param(
    [Parameter(Mandatory=$true)]
    [string]$namespace,
    
    [Parameter(Mandatory=$true)]
    [string]$ingressName
)

# Function to convert to JSON for Terraform external data source
function ConvertTo-Json20([object] $item) {
    Add-Type -AssemblyName System.Web.Extensions
    $js = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    return $js.Serialize($item)
}

# Wait for the ingress to be created and get its hostname
Write-Host "Waiting for ALB to be provisioned (this may take several minutes)..."
$attempts = 0
$maxAttempts = 30
$hostname = $null

while ($attempts -lt $maxAttempts) {
    try {
        $ingress = kubectl get ingress $ingressName -n $namespace -o json | ConvertFrom-Json
        
        if ($ingress.status.loadBalancer.ingress -and $ingress.status.loadBalancer.ingress[0].hostname) {
            $hostname = $ingress.status.loadBalancer.ingress[0].hostname
            Write-Host "ALB hostname found: $hostname"
            break
        }
    } catch {
        # Ignore errors and continue waiting
    }
    
    Write-Host "Attempt $($attempts+1)/$maxAttempts: ALB not ready yet, waiting 30 seconds..."
    Start-Sleep -Seconds 30
    $attempts++
}

if (-not $hostname) {
    Write-Host "Failed to get ALB hostname after $maxAttempts attempts"
    # Return a placeholder for Terraform to continue
    $result = @{
        hostname = "pending-alb-creation.elb.amazonaws.com"
    }
    Write-Output (ConvertTo-Json20 $result)
    exit 0
}

# Return the hostname in JSON format for Terraform external data source
$result = @{
    hostname = $hostname
}

Write-Output (ConvertTo-Json20 $result)