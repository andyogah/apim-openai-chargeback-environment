param apimInstanceName string
param functionAppName string



// Define the API Management instance
resource apimInstance 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimInstanceName
  scope: resourceGroup()
}

// Define the Function App resource to retrieve its managed identity
resource functionApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: functionAppName
  scope: resourceGroup()
}

// Define a named value for the Function App name
resource functionAppNameNamedValue 'Microsoft.ApiManagement/service/namedValues@2021-08-01' = {
  parent: apimInstance
  name: 'FunctionAppName'
  properties: {
    displayName: 'FunctionAppName'
    value: functionApp.name // Store the Function App name as the value
    secret: false
  }
}



