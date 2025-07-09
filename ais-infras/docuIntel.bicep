@description('Name of the resource.')
param name string

@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location

@description('Tags for the resource.')
param tags object = {}

type roleAssignmentInfo = {
  roleDefinitionId: string
  principalId: string
}

@description('Document Intelligence SKU. Defaults to S0.')
param sku object = {
  name: 'S0'
}

@description('List of deployments for Document Intelligence.')
param deployments array = []

@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'



resource documentIntelligenceService 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: toLower(name)
    publicNetworkAccess: publicNetworkAccess
  }
  sku: sku
  identity: {
    type: 'SystemAssigned'
  }
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [for deployment in deployments: {
  parent: documentIntelligenceService
  name: deployment.name
  properties: {
    model: deployment.model ?? null
    raiPolicyName: deployment.raiPolicyName ?? null
  }
  sku: deployment.sku ?? {
    name: 'Standard'
    capacity: 20
  }
}]



@description('ID for the deployed Document Intelligence resource.')
output id string = documentIntelligenceService.id

@description('Name for the deployed Document Intelligence resource.')
output name string = documentIntelligenceService.name

@description('Endpoint for the deployed Document Intelligence resource.')
output endpoint string = documentIntelligenceService.properties.endpoint

@description('Host for the deployed Document Intelligence resource.')
output host string = split(documentIntelligenceService.properties.endpoint, '/')[2]

@description('Principal ID for the deployed Document Intelligence resource.')
output principalId string = documentIntelligenceService.identity.principalId
