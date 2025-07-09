param(
    [string]$ResourceGroupName = "rg-tmp-apim-aogah",
    [string]$Location = "eastus",
    [string]$FunctionAppName = "funcApp$(Get-Date -Format 'yyyyMMddHHmmss')",
    [string]$ExistingSharedResourcesResourceGroup = "DOIChatGPT",
    [string]$ExistingStorageAccountResourceGroup = "DOI-OCIO-Hosting-AutoOps-East",
    [string]$ExistingStorageAccountName = "autoops",
    [string]$RedisCacheName = "redisCache$(Get-Date -Format 'yyyyMMddHHmmss')"
)

Write-Host "Testing Function App deployment without VNet integration..." -ForegroundColor Cyan

# Get the script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script path: $scriptPath"

# Get paths to the required files
$functionAppBicepFile = Join-Path -Path $scriptPath -ChildPath "../apim-infras/functionApp.bicep"
$redisCacheBicepFile = Join-Path -Path $scriptPath -ChildPath "../apim-infras/redisCache.bicep"

Write-Host "Function App Bicep file: $functionAppBicepFile"
Write-Host "Redis Cache Bicep file: $redisCacheBicepFile"

# Check if files exist
if (-not (Test-Path $functionAppBicepFile)) {
    Write-Host "Error: Function App Bicep file not found at $functionAppBicepFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $redisCacheBicepFile)) {
    Write-Host "Error: Redis Cache Bicep file not found at $redisCacheBicepFile" -ForegroundColor Red
    exit 1
}

# Check if logged in to Azure
Write-Host "Checking Azure CLI login status..."
$loggedIn = az account show --query "name" -o tsv
if (-not $loggedIn) {
    Write-Host "Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "Logged in as: $loggedIn"

# Check if resource group exists, create if not
Write-Host "Checking if resource group '$ResourceGroupName' exists..."
$resourceGroupExists = az group exists --name $ResourceGroupName | ConvertFrom-Json
if (-not $resourceGroupExists) {
    Write-Host "Creating resource group '$ResourceGroupName'..."
    az group create --name $ResourceGroupName --location $Location
    Write-Host "Resource group created successfully."
} else {
    Write-Host "Resource group '$ResourceGroupName' already exists."
}

# Get subscription ID
$subscriptionId = az account show --query "id" -o tsv
Write-Host "Using subscription: $subscriptionId"

Write-Host ""
Write-Host "Deployment parameters:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroupName"
Write-Host "  Location: $Location"
Write-Host "  Function App Name: $FunctionAppName"
Write-Host "  Redis Cache Name: $RedisCacheName"
Write-Host "  Existing Shared RG: $ExistingSharedResourcesResourceGroup"
Write-Host "  Existing Storage RG: $ExistingStorageAccountResourceGroup"
Write-Host "  Existing Storage Account: $ExistingStorageAccountName"
Write-Host ""

# First deploy Redis Cache (as Function App depends on it)
Write-Host "Step 1: Deploying Redis Cache..." -ForegroundColor Cyan
try {
    $redisDeployment = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file $redisCacheBicepFile `
        --parameters redisCacheName=$RedisCacheName `
                    location=$Location `
                    redisSubnetId="/subscriptions/39e239f8-7cbe-474b-8aef-624142e297bc/resourceGroups/DOI-OCIO-Hosting-AutoOps-East/providers/Microsoft.Network/virtualNetworks/DOI-OCIO-Hosting-AutoOps-East-vnet-96/subnets/DOI-OCIO-Hosting-AutoOps-vnet-96-sub4" `
        --query 'properties.outputs' -o json | ConvertFrom-Json

    Write-Host "✅ Redis Cache deployment completed successfully." -ForegroundColor Green
} catch {
    Write-Host "❌ Redis Cache deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Now deploy Function App
Write-Host "Step 2: Deploying Function App..." -ForegroundColor Cyan
try {
    $functionAppDeployment = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file $functionAppBicepFile `
        --parameters functionAppName=$FunctionAppName `
                    location=$Location `
                    storageAccountName=$ExistingStorageAccountName `
                    redisCacheName=$RedisCacheName `
                    azureResourceGroup=$ResourceGroupName `
                    subscriptionId=$subscriptionId `
                    existingSharedResourcesResourceGroup=$ExistingSharedResourcesResourceGroup `
                    existingStorageAccountResourceGroup=$ExistingStorageAccountResourceGroup `
        --query 'properties.outputs' -o json | ConvertFrom-Json

    Write-Host "✅ Function App deployment completed successfully." -ForegroundColor Green
    
    # Display outputs
    Write-Host ""
    Write-Host "Deployment Results:" -ForegroundColor Yellow
    Write-Host "  Function App Name: $($functionAppDeployment.name.value)"
    Write-Host "  Function App ID: $($functionAppDeployment.functionAppId.value)"
    Write-Host "  Function App Principal ID: $($functionAppDeployment.functionAppPrincipalId.value)"
    Write-Host "  Function App URL: https://$($functionAppDeployment.name.value).azurewebsites.net"
    
} catch {
    Write-Host "❌ Function App deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Get more detailed error information
    Write-Host ""
    Write-Host "Getting detailed error information..." -ForegroundColor Yellow
    $deploymentName = "functionApp$(Get-Date -Format 'HHmmss')"
    az deployment group show --resource-group $ResourceGroupName --name $deploymentName
    exit 1
}

Write-Host ""
Write-Host "✅ Test deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Test the Function App by visiting: https://$FunctionAppName.azurewebsites.net"
Write-Host "2. If successful, we can add VNet integration back to the template"
Write-Host "3. To clean up: az group delete --name $ResourceGroupName --yes --no-wait"
