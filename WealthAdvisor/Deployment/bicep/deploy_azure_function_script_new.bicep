@description('Specifies the location for resources.')
param solutionName string 
param solutionLocation string
param resourceGroupName string
param identity string
param baseUrl string
@secure()
param azureOpenAIApiKey string
param azureOpenAIApiVersion string
param azureOpenAIEndpoint string
@secure()
param azureSearchAdminKey string
param azureSearchServiceEndpoint string
param azureSearchIndex string
param sqlServerName string
param sqlDbName string
param sqlDbUser string
@secure()
param sqlDbPwd string

var functionAppName = '${solutionName}fn'
var functionName = 'askai'
var storageAccountName = '${solutionName}fnstorage'
var appServicePlanName = '${solutionName}fnasp'
var containerRegistryName = 'nctestcontainerreg2'
var containerImage = 'ncazfunctionsimage:v1.0.0'
var registryResourceGroup = 'byoaia-official'
var valueone = 1

var WebAppImageName = 'DOCKER|nctestcontainerreg2.azurecr.io/ncazfunctionsimage:v1.0.0'

// param location string = resourceGroup().location
// param storageAccountName string = 'storage${uniqueString(resourceGroup().id)}'
// param appServicePlanName string = 'asp-${uniqueString(resourceGroup().id)}'
// param containerRegistryName string
// param containerImage string = 'wafunctionimage:v1.0.0'
// param registryResourceGroup string

// Create a Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: solutionLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Create an App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: solutionLocation
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}



// // Reference the existing Azure Container Registry
// resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
//   name: containerRegistryName
//   scope: resourceGroup(registryResourceGroup)
// }

// // Retrieve the admin credentials for the container registry
// resource containerRegistryCredentials 'Microsoft.ContainerRegistry/registries/listCredentials@2023-01-01-preview' = {
//   name: 'listCredentials'
//   scope: containerRegistry
// }

// Create a Function App with a custom container
resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName
  location: solutionLocation
  kind: 'functionapp,linux,container'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.properties.primaryEndpoints.blob
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
        }
        {
          name: 'AZURE_AI_SEARCH_API_KEY'
          value: azureSearchAdminKey
        }
        {
          name: 'AZURE_AI_SEARCH_ENDPOINT'
          value: azureSearchServiceEndpoint
        }
        {
          name: 'AZURE_OPEN_AI_API_KEY'
          value: azureOpenAIApiKey
        }
        {
          name: 'AZURE_OPEN_AI_DEPLOYMENT_MODEL'
          value: 'gpt-4o'
        }
        {
          name: 'AZURE_OPEN_AI_ENDPOINT'
          value: azureOpenAIEndpoint
        }
        {
          name: 'AZURE_OPENAI_EMBEDDING_DEPLOYMENT'
          value: 'text-embedding-ada-002'
        }
        {
          name: 'AZURE_SEARCH_INDEX'
          value: 'transcripts_index'
        }
        {
          name: 'OPENAI_API_VERSION'
          value: '2024-02-15-preview'
        }
        {
          name: 'PYTHON_ENABLE_INIT_INDEXING'
          value: '1'
        }
        {
          name: 'PYTHON_ISOLATE_WORKER_DEPENDENCIES'
          value: '1'
        }
        {
          name: 'SQLDB_DATABASE'
          value: sqlDbName
        }
        {
          name: 'SQLDB_PASSWORD'
          value: sqlDbPwd
        }
        {
          name: 'SQLDB_SERVER'
          value: sqlServerName
        }
        {
          name: 'SQLDB_USERNAME'
          value: sqlDbUser
        }
      ]
      linuxFxVersion: WebAppImageName
    }
  }
}

// linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${containerImage}'
output functionAppUrl string = 'https://${functionAppName}.azurewebsites.net/api/${functionName}?'

// resource deploy_azure_function 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   kind:'AzureCLI'
//   name: 'deploy_azure_function'
//   location: solutionLocation // Replace with your desired location
//   identity:{
//     type:'UserAssigned'
//     userAssignedIdentities: {
//       '${identity}' : {}
//     }
//   }
//   properties: {
//     azCliVersion: '2.50.0'
//     primaryScriptUri: '${baseUrl}Deployment/scripts/create_azure_functions.sh' // deploy-azure-synapse-pipelines.sh
//     arguments: '${solutionName} ${solutionLocation} ${resourceGroupName} ${baseUrl} ${azureOpenAIApiKey} ${azureOpenAIApiVersion} ${azureOpenAIEndpoint} ${azureSearchAdminKey} ${azureSearchServiceEndpoint} ${azureSearchIndex} ${sqlServerName} ${sqlDbName} ${sqlDbUser} ${sqlDbPwd}' // Specify any arguments for the script
//     timeout: 'PT1H' // Specify the desired timeout duration
//     retentionInterval: 'PT1H' // Specify the desired retention interval
//     cleanupPreference:'OnSuccess'
//   }
// }
