# File type: PowerShell script (.ps1)
# filepath: 3-build-and-deploy.ps1

# Build and Deploy Applications Script
param(
    [Parameter(Mandatory=$true)]
    [string]$ApimSubscriptionKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ApimEndpoint
)

Write-Host "=== Build and Deploy Applications - Step 3 ===" -ForegroundColor Green

# Load configuration from previous step
if (-not (Test-Path "deployment-config.json")) {
    Write-Error "deployment-config.json not found. Please run 2-deploy-infrastructure.ps1 first."
    exit 1
}

$config = Get-Content "deployment-config.json" | ConvertFrom-Json
$resourceGroup = $config.ResourceGroup
$acrName = $config.AcrName
$containerAppEnv = $config.ContainerAppEnv

# Navigate to LibreChat directory
Set-Location LibreChat

Write-Host "Logging into Azure Container Registry..." -ForegroundColor Yellow
az acr login --name $acrName

Write-Host "Building and pushing LibreChat image..." -ForegroundColor Yellow
az acr build `
    --registry $acrName `
    --image librechat:latest `
    --file Dockerfile `
    .

# Get ACR login server
$acrLoginServer = az acr show --name $acrName --query loginServer --output tsv

Write-Host "Deploying MongoDB container..." -ForegroundColor Yellow
az containerapp create `
    --name mongodb `
    --resource-group $resourceGroup `
    --environment $containerAppEnv `
    --image mongo:6.0 `
    --target-port 27017 `
    --ingress internal `
    --min-replicas 1 `
    --max-replicas 1 `
    --cpu 1.0 `
    --memory 2Gi `
    --env-vars MONGO_INITDB_DATABASE=LibreChat

Write-Host "Waiting for MongoDB to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Get ACR credentials
$acrUsername = az acr credential show --name $acrName --query "username" --output tsv
$acrPassword = az acr credential show --name $acrName --query "passwords[0].value" --output tsv

Write-Host "Deploying LibreChat container..." -ForegroundColor Yellow
az containerapp create `
    --name librechat `
    --resource-group $resourceGroup `
    --environment $containerAppEnv `
    --image "$acrLoginServer/librechat:latest" `
    --target-port 3080 `
    --ingress external `
    --min-replicas 1 `
    --max-replicas 3 `
    --cpu 1.0 `
    --memory 2Gi `
    --registry-server $acrLoginServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --env-vars `
        NODE_ENV=production `
        PORT=3080 `
        HOST=0.0.0.0 `
        ENDPOINTS=azureOpenAI `
        AZURE_OPENAI_ENDPOINT=$ApimEndpoint `
        AZURE_OPENAI_API_VERSION=2024-02-15-preview `
        AZURE_OPENAI_API_KEY=$ApimSubscriptionKey `
        MONGO_URI="mongodb://mongodb:27017/LibreChat" `
        JWT_SECRET=(New-Guid).ToString() `
        JWT_REFRESH_SECRET=(New-Guid).ToString()

Write-Host "Step 3 completed successfully!" -ForegroundColor Green
Write-Host "Next: Run 4-verify-deployment.ps1" -ForegroundColor Cyan