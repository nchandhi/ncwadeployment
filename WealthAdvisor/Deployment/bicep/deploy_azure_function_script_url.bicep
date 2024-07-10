@description('Specifies the location for resources.')
param solutionName string 
param identity string

var functionAppName = '${solutionName}fn'
var functionName = 'askai'

resource existingFunctionApp 'Microsoft.Web/sites@2021-02-01' existing = {
  name: functionAppName
}

output functionAppUrl string = 'https://${existingFunctionApp.properties.defaultHostName}/api/${functionName}?'


