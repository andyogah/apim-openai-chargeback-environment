param functionAppName string
param location string
param storageAccountName string
param redisCacheName string
param azureResourceGroup string
param subscriptionId string

@description('App Service Plan ID')
param appServicePlanId string

resource redisCache 'Microsoft.Cache/Redis@2021-06-01' existing = {
  name: redisCacheName
  scope: resourceGroup()
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource functionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux' // Ensure this is set to 'functionapp,linux' for Linux-based environment
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId // Use the shared App Service Plan
    enabled: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11' // Set this to the appropriate runtime version
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python' // Set this to the language runtime you are using (e.g., 'dotnet', 'node', 'python', 'java')
        }
        {
          name: 'AZURE_SUBSCRIPTION_ID'
          value: subscriptionId
        }               
        {
          name: 'AZURE_RESOURCE_GROUP'
          value: azureResourceGroup
        }
        {
          name: 'REDIS_NAME'
          value: redisCacheName
        }
        {
          name: 'Redis__redisHostName'
          value: '${redisCache.name}.redis.cache.windows.net'
        }
        {
          name: 'Redis__hostName'
          value: redisCache.properties.hostName
        }
      ]
    }
  }
}

output name string = functionApp.name

// Output the Function App ID
output functionAppId string = functionApp.id

// Output the Function App Principal ID
output functionAppPrincipalId string = functionApp.identity.principalId

