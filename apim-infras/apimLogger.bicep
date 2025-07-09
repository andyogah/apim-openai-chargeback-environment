//I need to refactor this to handle diagnostic logs for the function app and the APIM instance

param apimInstanceName string
param apimLoggerName string

resource apiManagement 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apimInstanceName
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2021-08-01' = {
  parent: apiManagement
  name: apimLoggerName
  properties: {
    loggerType: 'applicationInsights' // note: replace with your actual logger type if different
    description: 'Logger for APIM'
    credentials: {
      instrumentationKey: 'your-instrumentation-key' 
    }
    isBuffered: true
  }
}
