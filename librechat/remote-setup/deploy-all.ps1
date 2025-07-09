# File type: PowerShell script (.ps1)
# filepath: deploy-all.ps1

# Master Deployment Script - Runs all steps sequentially
param(
    [Parameter(Mandatory=$true)]
    [string]$ApimSubscriptionKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ApimEndpoint,
    
    [string]$ResourceGroup = "librechat-rg",
    [string]$Location = "eastus"
)

Write-Host "=== LibreChat Complete Deployment ===" -ForegroundColor Magenta
Write-Host "This will deploy LibreChat with MongoDB to Azure Container Apps" -ForegroundColor Magenta

# Step 1: Setup
Write-Host "`n--- Running Step 1: Setup ---" -ForegroundColor Blue
& .\1-setup-librechat.ps1 -ApimSubscriptionKey $ApimSubscriptionKey -ApimEndpoint $ApimEndpoint

# Step 2: Infrastructure
Write-Host "`n--- Running Step 2: Infrastructure ---" -ForegroundColor Blue
& .\2-deploy-infrastructure.ps1 -ResourceGroup $ResourceGroup -Location $Location

# Step 3: Build and Deploy
Write-Host "`n--- Running Step 3: Build and Deploy ---" -ForegroundColor Blue
& .\3-build-and-deploy.ps1 -ApimSubscriptionKey $ApimSubscriptionKey -ApimEndpoint $ApimEndpoint

# Step 4: Verify
Write-Host "`n--- Running Step 4: Verification ---" -ForegroundColor Blue
& .\4-verify-deployment.ps1

Write-Host "`n=== Complete Deployment Finished ===" -ForegroundColor Magenta