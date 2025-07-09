@description('Name of the App Service Plan')
param appServicePlanName string = 'MyAppServicePlan'

@description('Name of the Backend App Service')
param backendAppName string = 'my-backend-app'

@description('Name of the Frontend App Service')
param frontendAppName string = 'my-frontend-app'

@description('Location for the resources')
param location string = resourceGroup().location

@description('Runtime stack for the App Services')
param runtimeStack string = 'PYTHON|3.11'

param subscriptionId string
param azureResourceGroup string
param redisCacheName string

@description('Name of the existing Storage Account')
param storageAccountName string

resource redisCache 'Microsoft.Cache/Redis@2021-06-01' existing = {
  name: redisCacheName
  scope: resourceGroup()
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'P2v2' // Premium Plan (or use 'S1' for Standard Plan)
    tier: 'PremiumV2' // Change to 'Standard' if using Standard Plan
    size: 'P2v2' // Adjust size as needed (e.g., P1v2, P2v2, etc.)
    capacity: 1
  }
  properties: {
    reserved: true // Linux-based App Service Plan
  }
}

resource backendApp 'Microsoft.Web/sites@2022-03-01' = {
  name: backendAppName
  location: location
  identity: {
    type: 'SystemAssigned' // Enable system-assigned managed identity
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: runtimeStack
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ENVIRONMENT'
          value: 'development' // Changed to development
        }
        {
          name: 'BACKEND_SPECIFIC_SETTING'
          value: 'value'
        }
        {
          name: 'AZURE_SUBSCRIPTION_ID'
          value: subscriptionId // Replace with actual value or parameterize
        }
        {
          name: 'AZURE_RESOURCE_GROUP'
          value: azureResourceGroup // Replace with actual value or parameterize
        }
        {
          name: 'REDIS_NAME'
          value: redisCacheName // Replace with actual value or parameterize
        }
        {
          name: 'Redis__redisHostName'
          value: '${redisCache.name}.redis.cache.windows.net' // Replace with actual value or parameterize
        }
        {
          name: 'Redis__hostName'
          value: redisCache.properties.hostName
        }
        {
          name: 'STORAGE_ACCOUNT_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITES_CONTAINER_START_TIME_LIMIT'
          value: '1600'
        }
      ]
      //appCommandLine: 'python -m backend.app'
      appCommandLine: 'pip install -r requirements.txt && hypercorn app:app --bind 0.0.0.0:$PORT'
    }
  }
}

resource frontendApp 'Microsoft.Web/sites@2022-03-01' = {
  name: frontendAppName
  location: location
  identity: {
    type: 'SystemAssigned' // Enable system-assigned managed identity
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: runtimeStack
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ENVIRONMENT'
          value: 'development' // Changed to development
        }
        {
          name: 'BACKEND_API_URL'
          value: 'https://${backendApp.properties.defaultHostName}/logs'
        }
        {
          name: 'STORAGE_ACCOUNT_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITES_CONTAINER_START_TIME_LIMIT'
          value: '1600'
        }
      ]
      appCommandLine: 'pip install -r requirements.txt && streamlit run uix.py --server.port=8000 --server.enableXsrfProtection=true'
    }
  }
}

// Export the App Service Plan ID for reuse
output appServicePlanId string = appServicePlan.id

output backendAppUrl string = backendApp.properties.defaultHostName
output frontendAppUrl string = frontendApp.properties.defaultHostName

output backendAppPrincipalId string = backendApp.identity.principalId
output frontendAppPrincipalId string = frontendApp.identity.principalId
