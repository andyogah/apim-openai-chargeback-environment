# File type: PowerShell script (.ps1)
# filepath: 4-verify-deployment.ps1

# Deployment Verification Script

Write-Host "=== Deployment Verification - Step 4 ===" -ForegroundColor Green

# Load configuration
if (-not (Test-Path "deployment-config.json")) {
    Write-Error "deployment-config.json not found. Please run previous steps first."
    exit 1
}

$config = Get-Content "deployment-config.json" | ConvertFrom-Json
$resourceGroup = $config.ResourceGroup

Write-Host "Checking deployment status..." -ForegroundColor Yellow

# Check MongoDB status
$mongoStatus = az containerapp show `
    --name mongodb `
    --resource-group $resourceGroup `
    --query properties.provisioningState `
    --output tsv

Write-Host "MongoDB Status: $mongoStatus" -ForegroundColor Cyan

# Check LibreChat status
$librechatStatus = az containerapp show `
    --name librechat `
    --resource-group $resourceGroup `
    --query properties.provisioningState `
    --output tsv

Write-Host "LibreChat Status: $librechatStatus" -ForegroundColor Cyan

# Get LibreChat URL
$librechatUrl = az containerapp show `
    --name librechat `
    --resource-group $resourceGroup `
    --query properties.configuration.ingress.fqdn `
    --output tsv

if ($librechatUrl) {
    Write-Host "LibreChat URL: https://$librechatUrl" -ForegroundColor Green
    Write-Host "Access your LibreChat instance at the URL above!" -ForegroundColor Green
} else {
    Write-Host "Unable to retrieve LibreChat URL. Checking logs..." -ForegroundColor Yellow
    
    # Show recent logs
    az containerapp logs show `
        --name librechat `
        --resource-group $resourceGroup `
        --tail 50
}

Write-Host "Deployment verification completed!" -ForegroundColor Green
Write-Host "If there are issues, check the logs with:" -ForegroundColor Cyan
Write-Host "az containerapp logs show --name librechat --resource-group $resourceGroup --follow" -ForegroundColor Cyan