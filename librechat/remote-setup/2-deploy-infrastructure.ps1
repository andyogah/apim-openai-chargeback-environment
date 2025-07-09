# File type: PowerShell script (.ps1)
# filepath: 2-deploy-infrastructure.ps1

# Azure Infrastructure Deployment Script
param(
    [string]$ResourceGroup = "librechat-rg",
    [string]$Location = "eastus",
    [string]$SubscriptionId = $null
)

Write-Host "=== Azure Infrastructure Deployment - Step 2 ===" -ForegroundColor Green

# Set subscription if provided
if ($SubscriptionId) {
    az account set --subscription $SubscriptionId
}

# Generate unique names
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$acrName = "librechatacr$timestamp"
$containerAppEnv = "librechat-env"
$storageAccount = "librechatstorage$timestamp"

Write-Host "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location

Write-Host "Creating Azure Container Registry: $acrName" -ForegroundColor Yellow
az acr create `
    --resource-group $ResourceGroup `
    --name $acrName `
    --sku Standard `
    --admin-enabled true

Write-Host "Creating Container Apps Environment: $containerAppEnv" -ForegroundColor Yellow
az containerapp env create `
    --name $containerAppEnv `
    --resource-group $ResourceGroup `
    --location $Location

Write-Host "Creating Storage Account for MongoDB: $storageAccount" -ForegroundColor Yellow
az storage account create `
    --name $storageAccount `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS

Write-Host "Creating file share for MongoDB data..." -ForegroundColor Yellow
az storage share create `
    --name mongodb-data `
    --account-name $storageAccount

# Get storage account key
$storageKey = az storage account keys list `
    --account-name $storageAccount `
    --resource-group $ResourceGroup `
    --query "[0].value" `
    --output tsv

Write-Host "Configuring storage for Container Apps..." -ForegroundColor Yellow
az containerapp env storage set `
    --name $containerAppEnv `
    --resource-group $ResourceGroup `
    --storage-name mongodb-storage `
    --azure-file-account-name $storageAccount `
    --azure-file-account-key $storageKey `
    --azure-file-share-name mongodb-data `
    --access-mode ReadWrite

# Save configuration for next steps
$config = @{
    ResourceGroup = $ResourceGroup
    Location = $Location
    AcrName = $acrName
    ContainerAppEnv = $containerAppEnv
    StorageAccount = $storageAccount
}
$config | ConvertTo-Json | Out-File -FilePath "deployment-config.json" -Encoding UTF8

Write-Host "Step 2 completed successfully!" -ForegroundColor Green
Write-Host "Configuration saved to deployment-config.json" -ForegroundColor Cyan
Write-Host "Next: Run 3-build-and-deploy.ps1" -ForegroundColor Cyan