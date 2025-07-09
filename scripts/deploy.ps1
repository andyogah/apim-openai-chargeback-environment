param(
    [string]$ContainerRegistryName = "doichatgpt",
    [string]$BackendImageName = "chargeback-backend",
    [string]$FrontendImageName = "chargeback-frontend",
    [string]$FunctionAppImageName = "chargeback-func-app",
    [string]$ImageTag = "$(Get-Date -Format 'yyyyMMdd-HHmm')"
)

#region Function Definitions
# Function to test if a resource exists in Azure
function Test-ResourceExists($resourceType, $resourceName, $resourceGroup) {
    try {
        switch ($resourceType) {
            "functionApp" { 
                return (az functionapp show --name $resourceName --resource-group $resourceGroup --query "name" -o tsv) 
            }
            "apim" { 
                return (az resource show --resource-type "Microsoft.ApiManagement/service" --name $resourceName --resource-group $resourceGroup --query "name" -o tsv) 
            }
            "redis" { 
                return (az redis show --name $resourceName --resource-group $resourceGroup --query "name" -o tsv) 
            }
            "logAnalytics" { 
                return (az monitor log-analytics workspace show --workspace-name $resourceName --resource-group $resourceGroup --query "name" -o tsv) 
            }
            "storage" { 
                return (az storage account show --name $resourceName --resource-group $resourceGroup --query "name" -o tsv) 
            }
            "appServicePlan" { 
                return (az resource show --resource-type "Microsoft.Web/serverfarms" --name $resourceName --resource-group $resourceGroup --query "name" -o tsv) 
            }
            default { 
                Write-Host "Error: Unsupported resource type '$resourceType'." -ForegroundColor Yellow
                return $null 
            }
        }
    } catch {
        Write-Host "Error testing $resourceType '$resourceName' in resource group '$resourceGroup'. It may not exist or there was an issue with the Azure CLI command." -ForegroundColor Yellow
        return $null
    }
}

# Function to generate or get resources
function New-OrGetResource($resourceType, $resourceName, $resourceGroup, $generateName) {
    try {
        if ($useExistingResources -eq "yes") {
            if (-not $resourceName) {
                if ($resourceType -eq "resourceGroup") {
                    # Automatically create the resource group if it doesn't exist
                    Write-Host "The specified resource group '$resourceName' does not exist. Creating it..."
                    az group create --name $generateName --location $location | Out-Null
                    Write-Host "Resource group '$generateName' created successfully."
                    return $generateName
                } else {
                    Write-Host "The specified $resourceType '$resourceName' does not exist. A new resource will be created automatically."
                    $resourceName = $generateName
                    Write-Host "Generated new ${resourceType}: $resourceName"
                }
            } else {
                # Check if the resource exists
                $exists = Test-ResourceExists $resourceType $resourceName $resourceGroup
                if (-not $exists) {
                    Write-Host "Error: The specified $resourceType '$resourceName' does not exist in resource group '$resourceGroup'." -ForegroundColor Red
                    exit 1
                }
                Write-Host "Using existing ${resourceType}: $resourceName"
            }
        } else {
            if (-not $resourceName) {
                $resourceName = $generateName
                Write-Host "Generated new ${resourceType}: $resourceName"
            }
        }
        return $resourceName
    } catch {
        Write-Host "Error handling $resourceType '$resourceName' in resource group '$resourceGroup'. Exception: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Function to update or add variables in the .env file
function Set-EnvFileVariable($envFilePath, $variableName, $variableValue) {
    if (Select-String -Path $envFilePath -Pattern $variableName -Quiet) {
        (Get-Content $envFilePath) | ForEach-Object {
            $_ -replace "$variableName=.*", "$variableName=$variableValue"
        } | Set-Content $envFilePath
    } else {
        Add-Content -Path $envFilePath -Value "$variableName=$variableValue"
    }
}
#endregion

#region Docker Validation Function
function Test-DockerAvailability {
    Write-Host "Checking Docker availability..." -ForegroundColor Cyan
    
    try {
        # Test if Docker Desktop is running
        docker --version | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker command not found"
        }
        
        # Test if Docker daemon is accessible
        docker info | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker daemon not accessible"
        }
        
        Write-Host "Docker is available and running" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Docker validation failed: $_" -ForegroundColor Red
        Write-Host "Please ensure Docker Desktop is installed and running." -ForegroundColor Yellow
        return $false
    }
}
#endregion

#region Initial Setup and Variables
# Get the script path early
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Host "Script path: $scriptPath"

# Define the Azure region for deployment
$location = "eastus"    #ensure this is the same region for the shared function app ASP 

# Validate Docker availability and Container Registry
$dockerAvailable = Test-DockerAvailability
if (-not $dockerAvailable) {
    Write-Host "Docker is required for deployment but is not available." -ForegroundColor Red
    Write-Host "Please install and start Docker Desktop, then run this script again." -ForegroundColor Red
    exit 1
}

if (-not $ContainerRegistryName) {
    Write-Host "Container Registry Name is required for Docker deployment." -ForegroundColor Red
    exit 1
}

Write-Host "Will use Docker deployment for all apps with ACR: $ContainerRegistryName" -ForegroundColor Cyan
#endregion

#region Azure Login and Subscription Selection
# Check if the user is logged in to Azure
Write-Host "Checking if logged in to Azure..."
$loggedIn = az account show --query "name" -o tsv

# If not logged in, prompt for login
if (-not $loggedIn) {
    Write-Host "You are not logged in. Logging in..."
    az login
    $loggedIn = az account show --query "name" -o tsv
}

Write-Host "Logged in as: $loggedIn"

# Retrieve the list of subscriptions
$subscriptions = az account list --query "[].{Name:name, Id:id, IsDefault:isDefault}" -o json | ConvertFrom-Json

# Display the subscriptions
Write-Host "Available subscriptions:"
$subscriptions | ForEach-Object { Write-Host "$($_.Name) - $($_.Id) (Default: $($_.IsDefault))" }

# Prompt the user to select a subscription or use the default
$selectedSubscriptionId = Read-Host "Enter the subscription ID to use (leave blank to use the default subscription)"

if (-not $selectedSubscriptionId) {
    # Use the default subscription
    $defaultSubscription = $subscriptions | Where-Object { $_.IsDefault -eq $true }
    if (-not $defaultSubscription) {
        Write-Host "No default subscription found. Please select a subscription." -ForegroundColor Red
        exit 1
    }
    $selectedSubscriptionId = $defaultSubscription.Id
    Write-Host "Using default subscription: $($defaultSubscription.Name) - $selectedSubscriptionId"
} else {
    # Validate the selected subscription
    $validSubscription = $subscriptions | Where-Object { $_.Id -eq $selectedSubscriptionId }
    if (-not $validSubscription) {
        Write-Host "Invalid subscription ID. Please check and try again." -ForegroundColor Red
        exit 1
    }
    Write-Host "Using selected subscription: $($validSubscription.Name) - $selectedSubscriptionId"
}

# Set the subscription
az account set --subscription $selectedSubscriptionId
Write-Host "Subscription set to $selectedSubscriptionId"
#endregion

#region Existing Resources Configuration
# Ask the user if they want to use existing resources
$useExistingResources = Read-Host "Do you want to use existing resources? (yes/no)"

# Prompt for existing APIM instance, App Service Plan, Resource Group, and Storage Account
if ($useExistingResources -eq "yes") {
    $existingSharedResourcesResourceGroup = Read-Host "Enter the name of the existing Shared Resources Resource Group"
    $existingApimInstanceName = Read-Host "Enter the name of the existing API Management instance"
    $existingAppServicePlanName = Read-Host "Enter the name of the existing App Service Plan"
    $existingLogAnalyticsWorkspaceName = Read-Host "Enter the name of the existing Log Analytics Workspace"
    $existingOpenAiServiceUrl = Read-Host "Enter the URL of the existing OpenAI Service"
    $existingStorageAccountResourceGroup = Read-Host "Enter the name of the existing Storage Account Resource Group"
    $existingStorageAccountName = Read-Host "Enter the name of the existing Storage Account"

    # Validate the existing Shared Resources Resource Group
    Write-Host "Checking if the resource group '$existingSharedResourcesResourceGroup' exists..."
    $resourceGroupExists = az group exists --name $existingSharedResourcesResourceGroup | ConvertFrom-Json
    if (-not $resourceGroupExists) {
        Write-Host "Error: The specified resource group '$existingSharedResourcesResourceGroup' does not exist." -ForegroundColor Red
        exit 1
    }
    Write-Host "Resource group '$existingSharedResourcesResourceGroup' exists."

    # Validate the existing APIM instance
    Write-Host "Checking if the APIM instance '$existingApimInstanceName' exists in resource group '$existingSharedResourcesResourceGroup'..."
    $apimExists = Test-ResourceExists "apim" $existingApimInstanceName $existingSharedResourcesResourceGroup
    if (-not $apimExists) {
        Write-Host "Error: The specified APIM instance '$existingApimInstanceName' does not exist in resource group '$existingSharedResourcesResourceGroup'." -ForegroundColor Red
        exit 1
    }
    Write-Host "APIM instance '$existingApimInstanceName' exists in resource group '$existingSharedResourcesResourceGroup'."

    # Validate the existing App Service Plan
    Write-Host "Checking if the App Service Plan '$existingAppServicePlanName' exists in resource group '$existingSharedResourcesResourceGroup'..."
    $appServicePlanExists = Test-ResourceExists "appServicePlan" $existingAppServicePlanName $existingSharedResourcesResourceGroup
    if (-not $appServicePlanExists) {
        Write-Host "Error: The specified App Service Plan '$existingAppServicePlanName' does not exist in resource group '$existingSharedResourcesResourceGroup'." -ForegroundColor Red
        exit 1
    }
    Write-Host "App Service Plan '$existingAppServicePlanName' exists in resource group '$existingSharedResourcesResourceGroup'."

    # Validate the existing Log Analytics Workspace
    Write-Host "Checking if the Log Analytics Workspace '$existingLogAnalyticsWorkspaceName' exists in resource group '$existingSharedResourcesResourceGroup'..."
    $logAnalyticsWorkspaceExists = Test-ResourceExists "logAnalytics" $existingLogAnalyticsWorkspaceName $existingSharedResourcesResourceGroup
    if (-not $logAnalyticsWorkspaceExists) {
        Write-Host "Error: The specified Log Analytics Workspace '$existingLogAnalyticsWorkspaceName' does not exist in resource group '$existingSharedResourcesResourceGroup'." -ForegroundColor Red
        exit 1
    }
    Write-Host "Log Analytics Workspace '$existingLogAnalyticsWorkspaceName' exists in resource group '$existingSharedResourcesResourceGroup'."

    # Validate the existing OpenAI Service URL
    if (-not $existingOpenAiServiceUrl) {
        Write-Host "Error: The OpenAI Service URL is required." -ForegroundColor Red
        exit 1
    }
    Write-Host "OpenAI Service URL '$existingOpenAiServiceUrl' is valid."

    # Validate the existing Storage Account Resource Group
    Write-Host "Checking if the resource group '$existingStorageAccountResourceGroup' exists..."
    $storageResourceGroupExists = az group exists --name $existingStorageAccountResourceGroup | ConvertFrom-Json
    if (-not $storageResourceGroupExists) {
        Write-Host "Error: The specified resource group '$existingStorageAccountResourceGroup' does not exist." -ForegroundColor Red
        exit 1
    }
    Write-Host "Resource group '$existingStorageAccountResourceGroup' exists."

    # Validate the existing Storage Account
    Write-Host "Checking if the Storage Account '$existingStorageAccountName' exists in resource group '$existingStorageAccountResourceGroup'..."
    $storageAccountExists = Test-ResourceExists "storage" $existingStorageAccountName $existingStorageAccountResourceGroup
    if (-not $storageAccountExists) {
        Write-Host "Error: The specified Storage Account '$existingStorageAccountName' does not exist in resource group '$existingStorageAccountResourceGroup'." -ForegroundColor Red
        exit 1
    }
    Write-Host "Storage Account '$existingStorageAccountName' exists in resource group '$existingStorageAccountResourceGroup'."
}

# Adding the path to the openai service url
$existingOpenAiServiceUrl = $existingOpenAiServiceUrl.TrimEnd('/') + "/openai"
#endregion

#region New Resource Configuration
# Automatically create new resources
Write-Host "Creating new resources..."
$newResourceGroup = "rg-tmp-apim-aogah"

# Check if the resource group exists
Write-Host "Checking if the resource group '$newResourceGroup' exists..."
$resourceGroupExists = az group exists --name $newResourceGroup | ConvertFrom-Json

if (-not $resourceGroupExists) {
    Write-Host "Resource group '$newResourceGroup' does not exist. Creating resource group..."
    az group create --name $newResourceGroup --location $location
} else {
    Write-Host "Resource group '$newResourceGroup' already exists."
}

$newFunctionAppName = New-OrGetResource "functionApp" $null $newResourceGroup "funcApp$(Get-Date -Format 'yyyyMMddHHmmss')"
$newRedisCacheName = New-OrGetResource "redis" $null $newResourceGroup "redisCache$(Get-Date -Format 'yyyyMMddHHmmss')"
$newFuncApiName = New-OrGetResource "funcApi" $null $newResourceGroup "funcApi$(Get-Date -Format 'yyyyMMddHHmmss')"
$newOaiApiName = New-OrGetResource "oaiApi" $null $newResourceGroup "oaiApi$(Get-Date -Format 'yyyyMMddHHmmss')"
$newBackendFunctionAppServiceUrl = "https://${newFunctionAppName}.azurewebsites.net/api"
$newBackendAppName = New-OrGetResource "backendApp" $null $newResourceGroup "backendApp$(Get-Date -Format 'yyyyMMddHHmmss')"
$newFrontendAppName = New-OrGetResource "frontendApp" $null $newResourceGroup "frontendApp$(Get-Date -Format 'yyyyMMddHHmmss')"

# Confirm the resource names being used
Write-Host "Using the following resource names:"
Write-Host "Existing APIM Resource Group: $existingSharedResourcesResourceGroup"
Write-Host "Existing Storage Account Resource Group: $existingStorageAccountResourceGroup"
Write-Host "Existing Storage Account Name: $existingStorageAccountName"
Write-Host "Existing APIM Instance Name: $existingApimInstanceName"
Write-Host "Existing App Service Plan Name: $existingAppServicePlanName"
Write-Host "Existing Log Analytics Workspace Name: $existingLogAnalyticsWorkspaceName"
Write-Host "Existing OpenAI Service URL: $existingOpenAiServiceUrl"
Write-Host "New Resource Group: $newResourceGroup"
Write-Host "New Function App Name: $newFunctionAppName"
Write-Host "New Redis Cache Name: $newRedisCacheName"
Write-Host "New Function API Name: $newFuncApiName"
Write-Host "New OpenAPI API Name: $newOaiApiName"
Write-Host "New Backend Function App Service URL: $newBackendFunctionAppServiceUrl"
Write-Host "New Backend App Name: $newBackendAppName"
Write-Host "New Frontend App Name: $newFrontendAppName"
#endregion

#region File Path Configuration
# Build the functionAppFolderPath using the scriptPath
$functionAppFolder = Join-Path -Path $scriptPath -ChildPath "..\src"
Write-Host "functionAppFolder: $functionAppFolder"

# Check if the functionapp folder exists
if (-Not (Test-Path -Path $functionAppFolder)) {
    Write-Host "The functionapp directory does not exist. Please check the path."
    exit 1
}

# Get the path to the main.bicep file
$bicepFile = Join-Path -Path $scriptPath -ChildPath "../apim-infras/main.bicep"
Write-Host "bicepFile path: $bicepFile"

# Get the path to the apimLogger.bicep file
$apimLoggerBicepFile = Join-Path -Path $scriptPath -ChildPath "../apim-infras/logger.bicep"
Write-Host "apimLoggerBicepFile path: $apimLoggerBicepFile"

# Get the path to the parameter.json file
$parametersFile = Join-Path -Path $scriptPath -ChildPath "../apim-infras/parameter.json"
Write-Host "parametersFile path: $parametersFile"

# Define folder paths for apps
$backendFolderPath = Join-Path -Path $scriptPath -ChildPath "../app/backend"
$frontendFolderPath = Join-Path -Path $scriptPath -ChildPath "../app/frontend"
#endregion

#region Bicep Deployment
# Deploy resources
Write-Host "Deploying resources..."
try {
    $deploymentOutputs = (az deployment group create `
        --resource-group $newResourceGroup `
        --template-file $bicepFile `
        --parameters @$parametersFile `
        --parameters existingSharedResourcesResourceGroup=$existingSharedResourcesResourceGroup `
                    existingStorageAccountResourceGroup=$existingStorageAccountResourceGroup `
                    existingStorageAccountName=$existingStorageAccountName `
                    existingApimInstanceName=$existingApimInstanceName `
                    existingAppServicePlanName=$existingAppServicePlanName `
                    existingLogAnalyticsWorkspaceName=$existingLogAnalyticsWorkspaceName `
                    existingOpenAiServiceUrl=$existingOpenAiServiceUrl `
                    newFunctionAppName=$newFunctionAppName `
                    location=$location `
                    newFuncApiName=$newFuncApiName `
                    newOaiApiName=$newOaiApiName `
                    newRedisCacheName=$newRedisCacheName `
                    newBackendFunctionAppServiceUrl=$newBackendFunctionAppServiceUrl `
                    newBackendAppName=$newBackendAppName `
                    newFrontendAppName=$newFrontendAppName `
                    acrName=$ContainerRegistryName `
                    functionAppDockerImageName=$FunctionAppImageName `
                    backendDockerImageName=$BackendImageName `
                    frontendDockerImageName=$FrontendImageName `
                    dockerImageTag=$ImageTag `
        --query 'properties.outputs' -o json) | ConvertFrom-Json

    Write-Host "Deployment of resources completed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error during resource deployment: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
#endregion

#region Output Processing
# Save the deployment outputs to a JSON file
Write-Host "Saving deployment outputs to a JSON file..."
$deploymentOutputs | ConvertTo-Json -Depth 10 | Out-File -FilePath '../infraOutputs.json' -Encoding utf8

# Extract various outputs from the deployment
Write-Host "Extracting deployment outputs..."
$resourceGroupName = $deploymentOutputs.resourceGroupInfo.value
$redisName = $deploymentOutputs.redisInfo.value.name
$redisHostName = $deploymentOutputs.redisInfo.value.hostName
$newRedisHostName = $redisHostName  # Assign redisHostName to newRedisHostName
$backendAppUrl = $deploymentOutputs.backendAppUrlInfo.value
$frontendAppUrl = $deploymentOutputs.frontendAppUrlInfo.value
$functionAppUrl = $deploymentOutputs.functionAppInfo.value

# Save the deployment outputs to a .env file
Write-Host "Saving the deployment outputs to a .env file..."

# Define the .env file path in the backend folder
$envFilePath = Join-Path -Path $scriptPath -ChildPath "../app/backend/.env"

# Create the .env file if it doesn't exist
if (-not (Test-Path $envFilePath)) {
    New-Item -Path $envFilePath -ItemType "file" -Value ""
}

# Use the selected subscription ID from earlier in the script
Write-Host "Using the selected subscription ID: $selectedSubscriptionId"

# Set variables in the .env file
Set-EnvFileVariable $envFilePath "AZURE_SUBSCRIPTION_ID" $selectedSubscriptionId
Set-EnvFileVariable $envFilePath "AZURE_RESOURCE_GROUP" $resourceGroupName
Set-EnvFileVariable $envFilePath "REDIS_NAME" $redisName
Set-EnvFileVariable $envFilePath "Redis__redisHostName" $redisHostName
Set-EnvFileVariable $envFilePath "BACKEND_APP_URL" $backendAppUrl
Set-EnvFileVariable $envFilePath "FRONTEND_APP_URL" $frontendAppUrl
Set-EnvFileVariable $envFilePath "FUNCTION_APP_URL" $functionAppUrl

Write-Host ".env file updated successfully with subscription ID and other variables at $envFilePath"

# Retrieve the storage account connection string
Write-Host "Retrieving the storage account connection string..."
$azureWebJobsStorage = az storage account show-connection-string --name $existingStorageAccountName --resource-group $existingStorageAccountResourceGroup --query connectionString --output tsv
#endregion

#region App Configuration
# Set the necessary app settings for Docker deployment
Write-Host "Setting Docker-specific app settings..." -ForegroundColor Cyan

# Function App settings for Docker (corrected for private endpoints)
Write-Host "Setting Function App settings..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $newResourceGroup --name $newFunctionAppName --settings `
"FUNCTIONS_EXTENSION_VERSION=~4" `
"FUNCTIONS_WORKER_RUNTIME=python" `
"FUNCTIONS_WORKER_PROCESS_COUNT=1" `
"PYTHON_THREADPOOL_THREAD_COUNT=1" `
"WEBSITE_RUN_FROM_PACKAGE=1" `
"SCM_DO_BUILD_DURING_DEPLOYMENT=false" `
"ENABLE_ORYX_BUILD=false" `
"AzureWebJobsStorage=DefaultEndpointsProtocol=https;AccountName=$existingStorageAccountName;AccountKey=$(az storage account keys list --account-name $existingStorageAccountName --resource-group $existingStorageAccountResourceGroup --query '[0].value' -o tsv);BlobEndpoint=https://$existingStorageAccountName.privatelink.blob.core.windows.net/;QueueEndpoint=https://$existingStorageAccountName.privatelink.queue.core.windows.net/;TableEndpoint=https://$existingStorageAccountName.privatelink.table.core.windows.net/;FileEndpoint=https://$existingStorageAccountName.privatelink.file.core.windows.net/" `
"AzureWebJobsSecretStorageType=Files" `
"WEBSITE_CONTENTAZUREFILECONNECTIONSTRING=DefaultEndpointsProtocol=https;AccountName=$existingStorageAccountName;AccountKey=$(az storage account keys list --account-name $existingStorageAccountName --resource-group $existingStorageAccountResourceGroup --query '[0].value' -o tsv);FileEndpoint=https://$existingStorageAccountName.privatelink.file.core.windows.net/" `
"WEBSITE_CONTENTSHARE=$($newFunctionAppName.ToLower())" `
"WEBSITE_MOUNT_ENABLED=1" `
"AZURE_SUBSCRIPTION_ID=$selectedSubscriptionId" `
"AZURE_RESOURCE_GROUP=$newResourceGroup" `
"REDIS_NAME=$newRedisCacheName" `
"Redis__redisHostName=$newRedisCacheName.privatelink.redis.cache.windows.net" `
"WEBSITES_ENABLE_APP_SERVICE_STORAGE=false" `
"DOCKER_REGISTRY_SERVER_URL=https://$ContainerRegistryName.azurecr.io" `
"WEBSITES_CONTAINER_START_TIME_LIMIT=1600" `
"WEBSITE_VNET_ROUTE_ALL=1" `
"WEBSITE_DNS_SERVER=168.63.129.16" `
"WEBSITE_DNS_ALT_SERVER=1.1.1.1" `
"WEBSITE_CONTENTOVERVNET=1"

Write-Host "Function App settings set." -ForegroundColor Green

# Backend app settings for Docker (corrected for private endpoints)
Write-Host "Setting Backend App settings..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $newResourceGroup --name $newBackendAppName --settings `
"WEBSITES_ENABLE_APP_SERVICE_STORAGE=false" `
"WEBSITES_PORT=8000" `
"ENVIRONMENT=development" `
"AZURE_SUBSCRIPTION_ID=$selectedSubscriptionId" `
"AZURE_RESOURCE_GROUP=$newResourceGroup" `
"REDIS_NAME=$newRedisCacheName" `
"Redis__redisHostName=$newRedisCacheName.privatelink.redis.cache.windows.net" `
"STORAGE_ACCOUNT_CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=$existingStorageAccountName;AccountKey=$(az storage account keys list --account-name $existingStorageAccountName --resource-group $existingStorageAccountResourceGroup --query '[0].value' -o tsv);BlobEndpoint=https://$existingStorageAccountName.privatelink.blob.core.windows.net/;QueueEndpoint=https://$existingStorageAccountName.privatelink.queue.core.windows.net/;TableEndpoint=https://$existingStorageAccountName.privatelink.table.core.windows.net/;FileEndpoint=https://$existingStorageAccountName.privatelink.file.core.windows.net/" `
"WEBSITES_CONTAINER_START_TIME_LIMIT=1600" `
"DOCKER_REGISTRY_SERVER_URL=https://$ContainerRegistryName.azurecr.io" `
"WEBSITE_VNET_ROUTE_ALL=1" `
"WEBSITE_DNS_SERVER=168.63.129.16" `
"WEBSITE_DNS_ALT_SERVER=1.1.1.1"

Write-Host "Backend App settings set." -ForegroundColor Green

# Frontend app settings for Docker (hybrid access)
Write-Host "Setting Frontend App settings..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $newResourceGroup --name $newFrontendAppName --settings `
"WEBSITES_ENABLE_APP_SERVICE_STORAGE=false" `
"WEBSITES_PORT=8000" `
"ENVIRONMENT=development" `
"STORAGE_ACCOUNT_CONNECTION_STRING=DefaultEndpointsProtocol=https;AccountName=$existingStorageAccountName;AccountKey=$(az storage account keys list --account-name $existingStorageAccountName --resource-group $existingStorageAccountResourceGroup --query '[0].value' -o tsv);BlobEndpoint=https://$existingStorageAccountName.privatelink.blob.core.windows.net/;QueueEndpoint=https://$existingStorageAccountName.privatelink.queue.core.windows.net/;TableEndpoint=https://$existingStorageAccountName.privatelink.table.core.windows.net/;FileEndpoint=https://$existingStorageAccountName.privatelink.file.core.windows.net/" `
"WEBSITES_CONTAINER_START_TIME_LIMIT=1600" `
"BACKEND_API_URL=https://$backendAppUrl/logs" `
"DOCKER_REGISTRY_SERVER_URL=https://$ContainerRegistryName.azurecr.io" `
"WEBSITE_VNET_ROUTE_ALL=0" `
"WEBSITE_DNS_SERVER=168.63.129.16" `
"WEBSITE_DNS_ALT_SERVER=1.1.1.1"

Write-Host "Docker app settings configured." -ForegroundColor Green
#endregion

#region Application Deployment
# Login to Azure Container Registry
Write-Host "Logging into Azure Container Registry..." -ForegroundColor Cyan
try {
    az acr login --name $ContainerRegistryName
    Write-Host "Successfully logged into ACR: $ContainerRegistryName" -ForegroundColor Green
} catch {
    Write-Host "Failed to login to ACR: $_" -ForegroundColor Red
    exit 1
}

# Build and push Function App Docker image
Write-Host "Building and pushing Function App Docker image..." -ForegroundColor Cyan
try {
    Push-Location $functionAppFolder
    $functionAppImage = "$ContainerRegistryName.azurecr.io/${FunctionAppImageName}:${ImageTag}"
    Write-Host "Building Function App image: $functionAppImage" -ForegroundColor Yellow
    
    # Check if Dockerfile exists
    $dockerfilePath = Join-Path $functionAppFolder "Dockerfile"
    if (-not (Test-Path $dockerfilePath)) {
        Write-Host "Error: Dockerfile not found in $functionAppFolder" -ForegroundColor Red
        Write-Host "Please create a Dockerfile for the Function App" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Using existing Dockerfile: $dockerfilePath" -ForegroundColor Green
    docker build -t $functionAppImage .
    docker push $functionAppImage
    Write-Host "Function App image pushed successfully: $functionAppImage" -ForegroundColor Green
} catch {
    Write-Host "Failed to build/push Function App image: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

# Build and push backend Docker image
Write-Host "Building and pushing backend Docker image..." -ForegroundColor Cyan
try {
    Push-Location $backendFolderPath
    $backendImage = "$ContainerRegistryName.azurecr.io/${BackendImageName}:${ImageTag}"
    Write-Host "Building image: $backendImage" -ForegroundColor Yellow
    docker build -t $backendImage .
    docker push $backendImage
    Write-Host "Backend image pushed successfully: $backendImage" -ForegroundColor Green
} catch {
    Write-Host "Failed to build/push backend image: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

# Build and push frontend Docker image
Write-Host "Building and pushing frontend Docker image..." -ForegroundColor Cyan
try {
    Push-Location $frontendFolderPath
    $frontendImage = "$ContainerRegistryName.azurecr.io/${FrontendImageName}:${ImageTag}"
    Write-Host "Building image: $frontendImage" -ForegroundColor Yellow
    docker build -t $frontendImage .
    docker push $frontendImage
    Write-Host "Frontend image pushed successfully: $frontendImage" -ForegroundColor Green
} catch {
    Write-Host "Failed to build/push frontend image: $_" -ForegroundColor Red
    Pop-Location
    exit 1
} finally {
    Pop-Location
}

# Get ACR credentials and update App Services to use Docker images
Write-Host "Retrieving ACR credentials and updating App Services..." -ForegroundColor Cyan
try {
    $acrCreds = az acr credential show --name $ContainerRegistryName --query "{username:username,password:passwords[0].value}" --output json | ConvertFrom-Json
    
    # Update Function App with Docker image
    az functionapp config container set --name $newFunctionAppName --resource-group $newResourceGroup --container-image-name $functionAppImage --container-registry-url "https://$ContainerRegistryName.azurecr.io" --container-registry-user $acrCreds.username --container-registry-password $acrCreds.password
    Write-Host "Function App updated with Docker image" -ForegroundColor Green
    
    # Update backend app with Docker image
    az webapp config container set --name $newBackendAppName --resource-group $newResourceGroup --container-image-name $backendImage --container-registry-url "https://$ContainerRegistryName.azurecr.io" --container-registry-user $acrCreds.username --container-registry-password $acrCreds.password
    Write-Host "Backend app updated with Docker image" -ForegroundColor Green
    
    # Update frontend app with Docker image
    az webapp config container set --name $newFrontendAppName --resource-group $newResourceGroup --container-image-name $frontendImage --container-registry-url "https://$ContainerRegistryName.azurecr.io" --container-registry-user $acrCreds.username --container-registry-password $acrCreds.password
    Write-Host "Frontend app updated with Docker image" -ForegroundColor Green
    
} catch {
    Write-Host "Failed to update App Services with Docker images: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Docker deployment completed for all apps!" -ForegroundColor Green

# Apply VNet fixes for private endpoint connectivity
Write-Host "Applying VNet configuration for private endpoints..." -ForegroundColor Cyan

# Function App VNet configuration - Enable routing for private endpoints
Write-Host "Configuring Function App for private endpoint access..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $newResourceGroup --name $newFunctionAppName --settings `
    "WEBSITE_VNET_ROUTE_ALL=1" `
    "WEBSITE_DNS_SERVER=168.63.129.16" `
    "WEBSITE_DNS_ALT_SERVER=1.1.1.1" `
    "WEBSITE_CONTENTOVERVNET=1" | Out-Null

try {
    az webapp config set --resource-group $newResourceGroup --name $newFunctionAppName --vnet-route-all-enabled true | Out-Null
    Write-Host "Function App VNet routing enabled for private endpoints" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not update Function App vnetRouteAllEnabled: $_" -ForegroundColor Yellow
}

# Backend App VNet configuration - Enable routing for private endpoints
Write-Host "Configuring Backend App for private endpoint access..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $newResourceGroup --name $newBackendAppName --settings `
    "WEBSITE_VNET_ROUTE_ALL=1" `
    "WEBSITE_DNS_SERVER=168.63.129.16" `
    "WEBSITE_DNS_ALT_SERVER=1.1.1.1" | Out-Null

try {
    az webapp config set --resource-group $newResourceGroup --name $newBackendAppName --vnet-route-all-enabled true | Out-Null
    Write-Host "Backend App VNet routing enabled for private endpoints" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not update Backend App vnetRouteAllEnabled: $_" -ForegroundColor Yellow
}

# Frontend App VNet configuration - Hybrid: Allow external access but enable DNS for internal calls
Write-Host "Configuring Frontend App for hybrid access..." -ForegroundColor Yellow
az webapp config appsettings set --resource-group $newResourceGroup --name $newFrontendAppName --settings `
    "WEBSITE_VNET_ROUTE_ALL=0" `
    "WEBSITE_DNS_SERVER=168.63.129.16" `
    "WEBSITE_DNS_ALT_SERVER=1.1.1.1" | Out-Null

try {
    az webapp config set --resource-group $newResourceGroup --name $newFrontendAppName --vnet-route-all-enabled false | Out-Null
    Write-Host "Frontend App configured for external access with internal DNS" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not update Frontend App vnetRouteAllEnabled: $_" -ForegroundColor Yellow
}

# Restart all apps to apply configuration changes
Write-Host "Restarting all apps..." -ForegroundColor Cyan
az functionapp restart --name $newFunctionAppName --resource-group $newResourceGroup
az webapp restart --name $newBackendAppName --resource-group $newResourceGroup
az webapp restart --name $newFrontendAppName --resource-group $newResourceGroup
Start-Sleep -Seconds 30

# Test app accessibility after configuration
Write-Host ""
Write-Host "Testing app accessibility after configuration..." -ForegroundColor Cyan

# Test Function App
try {
    $functionUrl = "https://$newFunctionAppName.azurewebsites.net"
    $response = Invoke-WebRequest -Uri $functionUrl -Method GET -TimeoutSec 30 -ErrorAction Stop
    Write-Host "✅ Function App is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Function App test: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test Backend App
try {
    $backendUrl = "https://$newBackendAppName.azurewebsites.net"
    $response = Invoke-WebRequest -Uri $backendUrl -Method GET -TimeoutSec 30 -ErrorAction Stop
    Write-Host "✅ Backend App is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Backend App test: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test Frontend App
try {
    $frontendUrl = "https://$newFrontendAppName.azurewebsites.net"
    $response = Invoke-WebRequest -Uri $frontendUrl -Method GET -TimeoutSec 30 -ErrorAction Stop
    Write-Host "✅ Frontend App is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Frontend App test: $($_.Exception.Message)" -ForegroundColor Yellow
}
#endregion

Write-Host ""
Write-Host "✅ Docker deployment and VNet configuration completed!" -ForegroundColor Green
Write-Host "Key changes applied:" -ForegroundColor Yellow
Write-Host "• Function App: VNet routing enabled for private endpoint access" -ForegroundColor Gray
Write-Host "• Backend App: VNet routing enabled for private endpoint access" -ForegroundColor Gray
Write-Host "• Frontend App: Hybrid access - external access with internal DNS" -ForegroundColor Gray
Write-Host "• Private endpoint FQDNs configured for storage and Redis" -ForegroundColor Gray
Write-Host "• DNS settings configured for hybrid connectivity" -ForegroundColor Gray
Write-Host "• Apps restarted to apply changes" -ForegroundColor Gray

Write-Host ""
Write-Host "Deployment script completed successfully!" -ForegroundColor Green
Write-Host "Backend URL: https://$backendAppUrl" -ForegroundColor Yellow
Write-Host "Frontend URL: https://$frontendAppUrl" -ForegroundColor Yellow
Write-Host "Function App URL: https://$functionAppUrl" -ForegroundColor Yellow

Write-Host "All apps deployed using Docker containers from ACR: $ContainerRegistryName" -ForegroundColor Cyan
Write-Host "Container image: chargeback-func-app:$ImageTag" -ForegroundColor Gray