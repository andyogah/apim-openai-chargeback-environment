
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location

@description('Tags for the resource.')
param tags object = {}

type roleAssignmentInfo = {
  roleDefinitionId: string
  principalId: string
}

@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Name of the Azure Cognitive Search resource.')
param cognitiveSearchName string

@description('SKU for the Azure Cognitive Search resource.')
param cognitiveSearchSku string = 'basic'

@description('Number of partitions for the Azure Cognitive Search resource.')
param partitionCount int = 1

@description('Number of replicas for the Azure Cognitive Search resource.')
param replicaCount int = 1

// @description('Name of the search index to create.')
// param searchIndexName string

// @description('Fields for the search index in JSON format.')
// param searchIndexFields string = '''
// [
//   {
//     "name": "id",
//     "type": "Edm.String",
//     "key": true,
//     "searchable": false,
//     "filterable": true,
//     "sortable": true,
//     "facetable": false,
//     "retrievable": true,
//     "analyzer": null,
//     "indexAnalyzer": null,
//     "queryAnalyzer": null,
//     "suggestions": false,
//     "synonyms": false
//   },
//   {
//     "name": "content",
//     "type": "Edm.String",
//     "key": false,
//     "searchable": true,
//     "filterable": false,
//     "sortable": false,
//     "facetable": false,
//     "retrievable": true,
//     "analyzer": "standard",
//     "indexAnalyzer": "standard",
//     "queryAnalyzer": "standard",
//     "suggestions": true,
//     "synonyms": true
//   }
// ]
// '''

resource cognitiveSearch 'Microsoft.Search/searchServices@2023-11-01' = {
  name: cognitiveSearchName
  location: location
  properties: {
    publicNetworkAccess: publicNetworkAccess == 'Enabled' ? 'enabled' : 'disabled'
    partitionCount: partitionCount
    replicaCount: replicaCount
  }
  sku: {
    name: cognitiveSearchSku
  }
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
}

// resource createSearchIndexScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'createSearchIndexScript'
//   location: location
//   kind: 'AzureCLI'
//   dependsOn: [
//     cognitiveSearch
//   ]
//   properties: {
//     azCliVersion: '2.37.0'
//     scriptContent: '''
//       az extension add --name search --yes
//       az search index create \
//         --service-name $SERVICE_NAME \
//         --name $INDEX_NAME \
//         --fields "$INDEX_FIELDS"
//     '''
//     arguments: ''
//     environmentVariables: [
//       {
//         name: 'SERVICE_NAME'
//         value: cognitiveSearchName
//       }
//       {
//         name: 'INDEX_NAME'
//         value: searchIndexName
//       }
//       {
//         value: searchIndexFields
//         name: 'INDEX_FIELDS'
//         //value: json(searchIndexFields) // Convert the array to a JSON string
//       }
//     ]
//     timeout: 'PT15M'
//     cleanupPreference: 'OnSuccess'
//     retentionInterval: 'P1D'
//   }
// }
