@description('Name of the API Management instance.')
param apimInstanceName string
param oaiApiName string
param funcApiName string
param apiSpecFileUri string
@description('Name of the Function App.')
param functionAppName string
param keyVaultName string
param redisCacheName string
param logAnalyticsWorkspaceName string
param backendFunctionAppServiceUrl string // Renamed to provide context for Function App service URL


@description('Name of the App Service Plan')
param appServicePlanName string// = 'MyAppServicePlan'

@description('Name of the Backend App Service')
param backendAppName string// = 'my-backend-app'

@description('Name of the Frontend App Service')
param frontendAppName string// = 'my-frontend-app'

@description('Runtime stack for the App Services')
param runtimeStack string = 'PYTHON|3.11'

@minLength(3)
@maxLength(24)
param storageAccountName string

@minLength(1)
@maxLength(64)
@description('Name of the workload which is used to generate a short unique hash used in all resources.')
param workloadName string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Tags for all resources.')
param tags object = {
  WorkloadName: workloadName
  Environment: 'Dev'
}

var abbrs = loadJsonContent('../ais-infras/abbrs.json')
var roles = loadJsonContent('./roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))


module keyVault './keyVault.bicep' = {
  name: 'deployKeyVault'
  params: {
    keyVaultName: keyVaultName
    location: location
  }
}

module logAnalyticsWorkspace './logAnalyticsWorkspace.bicep' = {
  name: 'deployLogAnalyticsWorkspace'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    location: location
  }
}

module apimInstance './apimInstance.bicep' = {
  name: 'deployApimInstance'
  params: {
    apimInstanceName: apimInstanceName
    location: location
  }
}

module redisCache './redisCache.bicep' = {
  name: 'deployRedisCache'
  params: {
    redisCacheName: redisCacheName
    location: location
  }
}

module storageAccount './storageAccount.bicep' = {
  name: 'deployStorageAccount'
  params: {
    storageAccountName: storageAccountName
    location: location
  }
}

module backendFrontendApp './backendFrontendApp.bicep' = {
  name: 'deployBackendFrontendApp'
  dependsOn: [    
    apimInstance
    redisCache
    storageAccount // Ensure the storage account is created first
  ]
  params: {
    appServicePlanName: appServicePlanName
    backendAppName: backendAppName
    frontendAppName: frontendAppName
    location: location    
    runtimeStack: runtimeStack
    subscriptionId: subscription().subscriptionId
    azureResourceGroup: resourceGroup().name
    redisCacheName: redisCacheName
    storageAccountName: storageAccountName
  }
}

module functionApp './functionApp.bicep' = {
  name: 'deployFunctionApp'
  dependsOn: [
    keyVault
    apimInstance
    redisCache
    storageAccount // Ensure the storage account is created first
  ]
  params: {
    functionAppName: functionAppName
    location: location
    storageAccountName: storageAccountName
    redisCacheName: redisCacheName 
    azureResourceGroup: resourceGroup().name
    subscriptionId: subscription().subscriptionId 
    appServicePlanId: backendFrontendApp.outputs.appServicePlanId // Pass the appServicePlanId from backendFrontendApp
  }
}

module functionAppNamedValues './functionAppNamedValues.bicep' = {
  name: 'functionAppNamedValues'  
  params: {
    apimInstanceName: apimInstance.outputs.name
    functionAppName: functionApp.outputs.name
  }
}

module keyVaultAccessPolicy './keyVaultAccessPolicy.bicep' = {
  name: 'assignKeyVaultAccessPolicy'
  params: {
    keyVaultName: keyVaultName
    principalId: functionApp.outputs.functionAppPrincipalId // Function App needs access to Key Vault
  }
}

// Azure OpenAI Service deployment
var aiServiceName = '${abbrs.ai.aiServices}${resourceToken}'
module aiServices '../ais-infras/aiService.bicep' = {
  name: aiServiceName
  params: {
    name: aiServiceName
    location: location
    tags: union(tags, {})
    deployments: [
      {
        name: 'gpt-4o'
        model: {
          format: 'OpenAI'
          name: 'gpt-4o'
          version: '2024-11-20'                   
        }
        raiPolicyName: 'Microsoft.Default'
        versionUpgradeOption: 'OnceCurrentVersionExpired'
        sku: {
          name: 'GlobalStandard'
          capacity: 10
        }        
      }
      {
        name: 'gpt-4o-mini'
        model: {
          format: 'OpenAI'
          name: 'gpt-4o-mini' 
          version: '2024-07-18'
        }
        raiPolicyName: 'Microsoft.Default'
        versionUpgradeOption: 'OnceCurrentVersionExpired'
        sku: {
          name: 'GlobalStandard'
          capacity: 5
        }
      }      
      {
        name: 'text-embedding'
        model: {
          format: 'OpenAI'
          name: 'text-embedding-3-large' 
          version: '1'
        }
        raiPolicyName: 'Microsoft.Default'
        versionUpgradeOption: 'OnceCurrentVersionExpired'
        sku: {
          name: 'GlobalStandard'
          capacity: 5
        }
      }      
      // {
      //   name: 'dall-e-3'
      //   model: {
      //     format: 'OpenAI'
      //     name: 'dall-e-3'
      //     version: '3.0'                   
      //   }
      //   scaleSettings: {
      //     scaleType: 'Standard'
      //     capacity: 1
      //   }
      
      // }      
    ]
  }
}



@description('SKU for the Cognitive Search service.')
@allowed([
  'basic'
  'free'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param cognitiveSearchSku string = 'basic'

@description('Number of partitions for the Cognitive Search service.')
@minValue(1)
@maxValue(12)
param partitionCount int = 1

@description('Number of replicas for the Cognitive Search service.')
@minValue(1)
@maxValue(12)
param replicaCount int = 1

@description('Specifies whether public network access is enabled or disabled for the Cognitive Search service.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

module aiSearch '../ais-infras/aiSearch.bicep' = {
  name: '${abbrs.ai.aiSearch}${resourceToken}'
  scope: resourceGroup()
  params: {
    cognitiveSearchName: '${abbrs.ai.aiSearch}${resourceToken}'
    location: location
    tags: union(tags, {})    
    cognitiveSearchSku: cognitiveSearchSku
    partitionCount: partitionCount
    replicaCount: replicaCount
    publicNetworkAccess: publicNetworkAccess
  }
}

module documentIntelligence '../ais-infras/docuIntel.bicep' = {
  name: '${abbrs.ai.documentIntelligence}${resourceToken}'
  scope: resourceGroup()
  params: {
    name: '${abbrs.ai.documentIntelligence}${resourceToken}'
    location: location
    tags: union(tags, {})
  }
}


module roleAssignmentAppInsights './roleAssignment.bicep' = {
  name: 'assignAppInsightsRoleToFunctionApp'
  scope: resourceGroup()
  params: {
    principalId: functionApp.outputs.functionAppPrincipalId // Function App needs access to Application Insights
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05') // Monitoring Reader role
  }
}


// Storage Blob Data Contributor:
// This role allows full access to Azure Storage blob containers and data, including read, write, and delete operations.
// Role Definition ID: ba92f5b4-2d11-453d-a403-e96b0029c9fe

// Storage Blob Data Reader (if only read access is required):
// This role allows read-only access to Azure Storage blob containers and data.
// Role Definition ID: 2a2b9908-6ea1-4ae2-8e65-a410df84e7d1
module roleAssignmentFunctionAppStorage './roleAssignment.bicep' = {
  name: 'assignStorageRoleToFunctionApp'
  scope: resourceGroup()
  dependsOn: [
    storageAccount
  ]  
  params: {
    principalId: functionApp.outputs.functionAppPrincipalId // Function App needs access to Storage Account
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader role
  }
}

module roleAssignmentBackendAppStorage './roleAssignment.bicep' = {
  name: 'assignStorageRoleToBackendApp'
  dependsOn: [
    storageAccount
  ]  
  params: {
    principalId: backendFrontendApp.outputs.backendAppPrincipalId // Ensure this output exists in backendFrontendApp.bicep
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader role
  }
}

module roleAssignmentFrontendStorage './roleAssignment.bicep' = {
  name: 'assignStorageRoleToFrontendApp'
  dependsOn: [
    storageAccount
  ]  
  params: {
    principalId: backendFrontendApp.outputs.frontendAppPrincipalId // Ensure this output exists in backendFrontendApp.bicep
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader role
  }
}

module roleAssignmentBackendAppRedis './roleAssignment.bicep' = {
  name: 'assignRedisRoleToBackendApp'
  dependsOn: [
    redisCache
  ]  
  params: {
    principalId: backendFrontendApp.outputs.backendAppPrincipalId // Ensure this output exists in backendFrontendApp.bicep
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role
  }
}

module roleAssignmentFrontendRedis './roleAssignment.bicep' = {
  name: 'assignRedisRoleToFrontendApp'
  dependsOn: [
    redisCache
  ]  
  params: {
    principalId: backendFrontendApp.outputs.frontendAppPrincipalId // Ensure this output exists in backendFrontendApp.bicep
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role
  }
}



module roleAssignmentApim './roleAssignment.bicep' = {
  name: 'assignKeyVaultRoleToApim'
  scope: resourceGroup()
  params: {
    principalId: apimInstance.outputs.clientId // APIM needs access to Key Vault
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // Key Vault Secrets User role
  }
}

module roleAssignmentOpenAi './roleAssignment.bicep' = {
  name: 'assignOpenAiRoleToApim'
  scope: resourceGroup()
  params: {
    principalId: apimInstance.outputs.clientId    
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roles.ai.cognitiveServicesUser}'  // Role definition for accessing OpenAI
  }
}


module roleAssignmentSearchService './roleAssignment.bicep' = {
  name: 'assignSearchServiceRoleToApim'
  params: {
    principalId: apimInstance.outputs.clientId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0') // Search Service Contributor role
  }
}

module roleAssignmentDocuIntel './roleAssignment.bicep' = {
  name: 'assignOpenAiRoleToDocuIntel'
  scope: resourceGroup()
  params: {
    principalId: documentIntelligence.outputs.principalId
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roles.ai.cognitiveServicesContributor}'  // Role definition for accessing OpenAI
  }
}

module roleAssignmentFunctionApp './roleAssignment.bicep' = {
  name: 'assignFunctionAppRoleToApim'
  scope: resourceGroup()
  params: {
    principalId: apimInstance.outputs.clientId // APIM needs access to Function App
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor role    
  }
}

module roleAssignmentRedis './roleAssignment.bicep' = {
  name: 'assignFunctionAppRoleToRedis'
  scope: resourceGroup()
  params: {
    principalId: functionApp.outputs.functionAppPrincipalId // Function App needs access to Redis
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e0f68234-74aa-48ed-b826-c38b57376e17') // Redis Cache Contributor role
  }
}


// Construct the OpenAI Service URL
var openAiServiceUrl = 'https://${aiServices.outputs.host}/openai'
module apimOaiApi './apimOaiApi.bicep' = {
  name: 'deployApimOaiApi'
  dependsOn: [
    apimInstance
    roleAssignmentOpenAi
  ]
  params: {
    apimInstanceName: apimInstanceName
    apiSpecFileUri: apiSpecFileUri
    oaiApiName: oaiApiName
    openAiServiceUrl: openAiServiceUrl
  }
}

module diagnosticSettings './diagnosticSettings.bicep' = {
  name: 'deployDiagnosticSettings'
  dependsOn: [
    logAnalyticsWorkspace
    functionApp
  ]
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    functionAppName: functionAppName
  }
}

module apimFuncApi './apimFuncApi.bicep' = {
  name: 'deployApimFuncApi'
  // dependsOn: [
  //   apimInstance       
  // ]
  params: {
    apimInstanceName: apimInstanceName
    funcApiName: funcApiName
    backendFunctionAppServiceUrl: backendFunctionAppServiceUrl //'https://your-service-url' // Replace with the actual service URL
    managedIdentityClientId: apimInstance.outputs.clientId //Managed Identity Client ID
  }
}

output backendAppUrlInfo string = backendFrontendApp.outputs.backendAppUrl
output frontendAppUrlInfo string = backendFrontendApp.outputs.frontendAppUrl

output resourceGroupInfo string = resourceGroup().name
output redisInfo object = {
  name: redisCache.outputs.redisCacheName
  hostName: redisCache.outputs.redisHostName
  principalId: redisCache.outputs.redisPrincipalId
}
