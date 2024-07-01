// ========== main.bicep ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(6)
@description('Prefix Name')
param solutionPrefix string

// @description('Fabric Workspace Id if you have one, else leave it empty. ')
// param fabricWorkspaceId string

var resourceGroupLocation = resourceGroup().location
var resourceGroupName = resourceGroup().name
var subscriptionId  = subscription().subscriptionId

var solutionLocation = resourceGroupLocation
// var baseUrl = 'https://raw.githubusercontent.com/microsoft/Build-your-own-AI-Assistant-Solution-Accelerator/main/'
var baseUrl = 'https://raw.githubusercontent.com/nchandhi/ncwadeployment/main/WealthAdvisor/'

// ========== Managed Identity ========== //
module managedIdentityModule 'deploy_managed_identity.bicep' = {
  name: 'deploy_managed_identity'
  params: {
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
  }
  scope: resourceGroup(resourceGroup().name)
}

// ========== Storage Account Module ========== //
module storageAccountModule 'deploy_storage_account.bicep' = {
  name: 'deploy_storage_account'
  params: {
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
    managedIdentityObjectId:managedIdentityModule.outputs.managedIdentityOutput.objectId
  }
  scope: resourceGroup(resourceGroup().name)
}

// ========== SQL DB Module ========== //
module sqlDBModule 'deploy_sql_db.bicep' = {
  name: 'deploy_sql_db'
  params: {
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
    managedIdentityObjectId:managedIdentityModule.outputs.managedIdentityOutput.objectId
  }
  scope: resourceGroup(resourceGroup().name)
}

// ========== Key Vault ========== //

// module createFabricItems 'deploy_fabric_scripts.bicep' = if (fabricWorkspaceId != '') {
//   name : 'deploy_fabric_scripts'
//   params:{
//     solutionLocation: solutionLocation
//     identity:managedIdentityModule.outputs.managedIdentityOutput.id
//     baseUrl:baseUrl
//     keyVaultName:'test_kv_value'
//     fabricWorkspaceId:fabricWorkspaceId
//   }
// }

// ========== Azure AI services multi-service account ========== //
module azAIMultiServiceAccount 'deploy_azure_ai_service.bicep' = {
  name: 'deploy_azure_ai_service'
  params: {
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
  }
} 

// ========== Search service ========== //
module azSearchService 'deploy_ai_search_service.bicep' = {
  name: 'deploy_ai_search_service'
  params: {
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
  }
} 

// ========== Azure OpenAI ========== //
module azOpenAI 'deploy_azure_open_ai.bicep' = {
  name: 'deploy_azure_open_ai'
  params: {
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
  }
}

module uploadFiles 'deploy_upload_files_script.bicep' = {
  name : 'deploy_upload_files_script'
  params:{
    storageAccountName:storageAccountModule.outputs.storageAccountOutput.name
    solutionLocation: solutionLocation
    containerName:storageAccountModule.outputs.storageAccountOutput.dataContainer
    identity:managedIdentityModule.outputs.managedIdentityOutput.id
    storageAccountKey:storageAccountModule.outputs.storageAccountOutput.key
    baseUrl:baseUrl
  }
  dependsOn:[storageAccountModule]
}

module azureFunctions 'deploy_azure_function_script.bicep' = {
  name : 'deploy_azure_function_script'
  params:{
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
    resourceGroupName:resourceGroupName
    azureOpenAIApiKey:azOpenAI.outputs.openAIOutput.openAPIKey
    azureOpenAIApiVersion:'2023-07-01-preview'
    azureOpenAIEndpoint:azOpenAI.outputs.openAIOutput.openAPIEndpoint
    azureSearchAdminKey:azSearchService.outputs.searchServiceOutput.searchServiceAdminKey
    azureSearchServiceEndpoint:azSearchService.outputs.searchServiceOutput.searchServiceEndpoint
    azureSearchIndex:'transcripts_index'
    sqlServerName:sqlDBModule.outputs.sqlDbOutput.sqlServerName
    sqlDbName:sqlDBModule.outputs.sqlDbOutput.sqlDbName
    sqlDbUser:sqlDBModule.outputs.sqlDbOutput.sqlDbUser
    sqlDbPwd:sqlDBModule.outputs.sqlDbOutput.sqlDbPwd
    identity:managedIdentityModule.outputs.managedIdentityOutput.id
    baseUrl:baseUrl
  }
  dependsOn:[storageAccountModule]
}
// ========== Key Vault ========== //

module keyvaultModule 'deploy_keyvault.bicep' = {
  name: 'deploy_keyvault'
  params: {
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
    objectId: managedIdentityModule.outputs.managedIdentityOutput.objectId
    tenantId: subscription().tenantId
    managedIdentityObjectId:managedIdentityModule.outputs.managedIdentityOutput.objectId
    adlsAccountName:storageAccountModule.outputs.storageAccountOutput.storageAccountName
    adlsAccountKey:storageAccountModule.outputs.storageAccountOutput.key
    azureOpenAIApiKey:azOpenAI.outputs.openAIOutput.openAPIKey
    azureOpenAIApiVersion:'2023-07-01-preview'
    azureOpenAIEndpoint:azOpenAI.outputs.openAIOutput.openAPIEndpoint
    azureSearchAdminKey:azSearchService.outputs.searchServiceOutput.searchServiceAdminKey
    azureSearchServiceEndpoint:azSearchService.outputs.searchServiceOutput.searchServiceEndpoint
    azureSearchServiceName:azSearchService.outputs.searchServiceOutput.searchServiceName
    azureSearchIndex:'transcripts_index'
    cogServiceEndpoint:azAIMultiServiceAccount.outputs.cogSearchOutput.cogServiceEndpoint
    cogServiceName:azAIMultiServiceAccount.outputs.cogSearchOutput.cogServiceName
    cogServiceKey:azAIMultiServiceAccount.outputs.cogSearchOutput.cogServiceKey
    sqlServerName:sqlDBModule.outputs.sqlDbOutput.sqlServerName
    sqlDbName:sqlDBModule.outputs.sqlDbOutput.sqlDbName
    sqlDbUser:sqlDBModule.outputs.sqlDbOutput.sqlDbUser
    sqlDbPwd:sqlDBModule.outputs.sqlDbOutput.sqlDbPwd
    enableSoftDelete:false
  }
  scope: resourceGroup(resourceGroup().name)
  dependsOn:[storageAccountModule,azOpenAI,azSearchService,sqlDBModule]
}

module createIndex 'deploy_index_scripts.bicep' = {
  name : 'deploy_index_scripts'
  params:{
    solutionLocation: solutionLocation
    identity:managedIdentityModule.outputs.managedIdentityOutput.id
    baseUrl:baseUrl
    keyVaultName:keyvaultModule.outputs.keyvaultOutput.name
  }
  dependsOn:[keyvaultModule]
}

// module createFabricItems 'deploy_fabric_scripts.bicep' = if (fabricWorkspaceId != '') {
//   name : 'deploy_fabric_scripts'
//   params:{
//     solutionLocation: solutionLocation
//     identity:managedIdentityModule.outputs.managedIdentityOutput.id
//     baseUrl:baseUrl
//     keyVaultName:keyvaultModule.outputs.keyvaultOutput.name
//     fabricWorkspaceId:fabricWorkspaceId
//   }
//   dependsOn:[keyvaultModule]
// }

// module createIndex1 'deploy_aihub_scripts.bicep' = {
//   name : 'deploy_aihub_scripts'
//   params:{
//     solutionLocation: solutionLocation
//     identity:managedIdentityModule.outputs.managedIdentityOutput.id
//     baseUrl:baseUrl
//     keyVaultName:keyvaultModule.outputs.keyvaultOutput.name
//     solutionName: solutionPrefix
//     resourceGroupName:resourceGroupName
//     subscriptionId:subscriptionId
//   }
//   dependsOn:[keyvaultModule]
// }

module appserviceModule 'deploy_app_service.bicep' = {
  name: 'deploy_app_service'
  params: {
    identity:managedIdentityModule.outputs.managedIdentityOutput.id
    solutionName: solutionPrefix
    solutionLocation: solutionLocation
    AzureSearchService:azSearchService.outputs.searchServiceOutput.searchServiceName
    AzureSearchIndex:'articlesindex'
    AzureSearchArticlesIndex:'articlesindex'
    AzureSearchGrantsIndex:'grantsindex'
    AzureSearchDraftsIndex:'draftsindex'
    AzureSearchKey:azSearchService.outputs.searchServiceOutput.searchServiceAdminKey
    AzureSearchUseSemanticSearch:'True'
    AzureSearchSemanticSearchConfig:'my-semantic-config'
    AzureSearchIndexIsPrechunked:'False'
    AzureSearchTopK:'5'
    AzureSearchContentColumns:'content'
    AzureSearchFilenameColumn:'chunk_id'
    AzureSearchTitleColumn:'title'
    AzureSearchUrlColumn:'publicurl'
    AzureOpenAIResource:azOpenAI.outputs.openAIOutput.openAPIEndpoint
    AzureOpenAIEndpoint:azOpenAI.outputs.openAIOutput.openAPIEndpoint
    AzureOpenAIModel:'gpt-35-turbo-16k'
    AzureOpenAIKey:azOpenAI.outputs.openAIOutput.openAPIKey
    AzureOpenAIModelName:'gpt-35-turbo-16k'
    AzureOpenAITemperature:'0'
    AzureOpenAITopP:'1'
    AzureOpenAIMaxTokens:'1000'
    AzureOpenAIStopSequence:''
    AzureOpenAISystemMessage:'''You are a helpful Wealth Advisor assistant''' 
    AzureOpenAIApiVersion:'2023-12-01-preview'
    AzureOpenAIStream:'True'
    AzureSearchQueryType:'vectorSimpleHybrid'
    AzureSearchVectorFields:'contentVector'
    AzureSearchPermittedGroupsField:''
    AzureSearchStrictness:'3'
    AzureOpenAIEmbeddingName:'text-embedding-ada-002'
    AzureOpenAIEmbeddingkey:azOpenAI.outputs.openAIOutput.openAPIKey
    AzureOpenAIEmbeddingEndpoint:azOpenAI.outputs.openAIOutput.openAPIEndpoint
    USE_AZUREFUNCTION:'True'
    STREAMING_AZUREFUNCTION_ENDPOINT:'TBD'
    SQLDB_CONNECTION_STRING:'TBD'
    SQLDB_SERVER:sqlDBModule.outputs.sqlDbOutput.sqlServerName
    SQLDB_DATABASE:sqlDBModule.outputs.sqlDbOutput.sqlDbName
    SQLDB_USERNAME:sqlDBModule.outputs.sqlDbOutput.sqlDbUser
    SQLDB_PASSWORD:sqlDBModule.outputs.sqlDbOutput.sqlDbPwd
  }
  scope: resourceGroup(resourceGroup().name)
  dependsOn:[storageAccountModule,azOpenAI,azAIMultiServiceAccount,azSearchService]
}
