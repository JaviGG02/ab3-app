# PowerShell script to update catalog-db-service.yaml with Aurora endpoint
Write-Host "Updating catalog-db-service.yaml with Aurora endpoint..." -ForegroundColor Cyan

# Get the Aurora endpoint from kubectl secret
$auroraEndpoint = kubectl get secret catalog-db-secret -n catalog -o jsonpath="{.data.RETAIL_CATALOG_PERSISTENCE_ENDPOINT}" | 
                  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Extract just the hostname part (remove port)
$endpointParts = $auroraEndpoint -split ':'
$hostname = $endpointParts[0]

Write-Host "Found Aurora endpoint: $hostname" -ForegroundColor Green

# Update the catalog-db-service.yaml file
$serviceYaml = Get-Content -Path "catalog-db-service.yaml" -Raw
$updatedYaml = $serviceYaml -replace 'externalName: .*', "externalName: $hostname"
Set-Content -Path "catalog-db-service.yaml" -Value $updatedYaml

Write-Host "Updated catalog-db-service.yaml with Aurora endpoint." -ForegroundColor Green