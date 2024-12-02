targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name which is used to generate a short unique hash for each resource')
param name string

@description('The location where the resources will be created.')
@allowed(['australiaeast', 'eastasia', 'eastus', 'eastus2', 'northeurope', 'southcentralus', 'southeastasia', 'swedencentral', 'uksouth', 'westus2', 'eastus2euap'])
param location string = 'northeurope'

@description('Name of the application')
param application string = 'ipaasworkshop'

@description('The environment deployed')
@allowed(['lab', 'dev', 'stg', 'prd'])
param environment string = 'lab'

var resourceToken = toLower(uniqueString(subscription().id, name, environment, application))
var resourceSuffix = [
  toLower(environment)
  substring(toLower(location), 0, 2)
  substring(toLower(application), 0, 3)
  substring(resourceToken, 0, 8)
]
var resourceSuffixKebabcase = join(resourceSuffix, '-')
var resourceSuffixLowercase = join(resourceSuffix, '')

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {
  'azd-env-name': name
  Deployment: 'bicep'
  Environment: environment
  Location: location
  Application: application
}

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('Whether the deployment is running on GitHub Actions')
param runningOnGh string = ''

@description('Whether the deployment is running on Azure DevOps Pipeline')
param runningOnAdo string = ''

var principalType = empty(runningOnGh) && empty(runningOnAdo) ? 'User' : 'ServicePrincipal'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}-${resourceSuffixKebabcase}'
  location: location
  tags: tags
}

var inputFilesContainerName = 'inputfiles'
var dataProcessingDeploymentPackageContainerName = 'dataprocessingdeploymentpackage'
var dataFetchingDeploymentPackageContainerName = 'datafetchingdeploymentpackage'
var cosmosOrdersToProcessContainerName = 'toprocess'
var cosmosOrdersProcessedContainerName = 'processed'

module storageAccountData './storageaccount.bicep' = {
  name: 'storageAccountData'
  scope: resourceGroup
  params: {
    name: 'stdata${resourceSuffixLowercase}'
    location: location
    tags: tags
    containers: [
      {name: inputFilesContainerName}
    ]
  }
}

module storageAccountFunctions './storageaccount.bicep' = {
  name: 'storageAccountFunctions'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    name: take('stfunc${resourceSuffixLowercase}', 24)
    containers: [
      {name: dataProcessingDeploymentPackageContainerName}
      {name: dataFetchingDeploymentPackageContainerName}
    ]
  }
}

module storageAccountLogicApp './storageaccount.bicep' = {
  name: 'storageAccountLogicApp'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    name: take('stloa${resourceSuffixLowercase}', 24)
    allowSharedKeyAccess: true
  }
}

module dataProcessingFunctionApp './functionapp.bicep' = {
  name: 'data-processing-func'
  scope: resourceGroup
  params: {
    planName: 'asp-proc-${resourceSuffixKebabcase}'
    appName: 'func-proc-${resourceSuffixKebabcase}'
    applicationInsightsName: applicationInsights.outputs.name
    storageAccountName: storageAccountFunctions.outputs.name
    deploymentStorageContainerName: dataProcessingDeploymentPackageContainerName
    azdServiceName: 'dataprocessing'
    tags: tags
    appSettings: [
      {
        name  : 'COSMOS_DB_DATABASE_NAME'
        value : cosmos.outputs.databaseName
      }
      {
        name  : 'COSMOS_DB_TO_PROCESS_CONTAINER_NAME'
        value : cosmosOrdersToProcessContainerName
      }
      {
        name  : 'COSMOS_DB_PROCESSED_CONTAINER_NAME'
        value : cosmosOrdersProcessedContainerName
      }
      {
        name  : 'COSMOS_DB__accountEndpoint'
        value :  cosmos.outputs.endpoint
      }
      {
        name: 'SB_ORDERS__fullyQualifiedNamespace'
        value: servicebus.outputs.fullyQualifiedNamespace
      }
      {
        name: 'SERVICEBUS_QUEUE'
        value: 'orders'
      }
    ]
  }
}

module dataFetchingFunctionApp './functionapp.bicep' = {
  name: 'data-fetching-func'
  scope: resourceGroup
  params: {
    planName: 'asp-ftch-${resourceSuffixKebabcase}'
    appName: 'func-ftch-${resourceSuffixKebabcase}'
    applicationInsightsName: applicationInsights.outputs.name
    storageAccountName: storageAccountFunctions.outputs.name
    deploymentStorageContainerName: dataFetchingDeploymentPackageContainerName
    azdServiceName: 'datafetching'
    tags: tags
    appSettings: [
      {
        name  : 'COSMOS_DB_DATABASE_NAME'
        value : cosmos.outputs.databaseName
      }
      {
        name  : 'COSMOS_DB_CONTAINER_NAME'
        value : cosmosOrdersProcessedContainerName
      }
      {
        name  : 'COSMOS_DB__accountEndpoint'
        value :  cosmos.outputs.endpoint
      }
    ]
  }
}

module dataProcessingLogicApp './logicapp.bicep' = {
  name: 'data-process-loa'
  scope: resourceGroup
  params: {
    planName: 'asp-loa-proc-${resourceSuffixKebabcase}'
    appName: 'loa-proc-${resourceSuffixKebabcase}'
    applicationInsightsName: applicationInsights.outputs.name
    storageAccountName: storageAccountLogicApp.outputs.name
    storageAccountConnectionString: storageAccountLogicApp.outputs.storageConnectionString
    tags: tags
  }
}

module applicationInsights './appinsights.bicep' = {
  scope: resourceGroup
  name: 'appinsights'
  params: {
    name: 'aai-${resourceSuffixKebabcase}'
    location: location
    tags: tags
  }
}

module cosmos './cosmos.bicep' = {
  scope: resourceGroup
  name: 'cosmos'
  params: {
    accountName: 'cos-${resourceSuffixKebabcase}'
    databaseName: 'orders'
    location: location
    tags: tags
    containers: [
      {
        name: cosmosOrdersToProcessContainerName
        id: cosmosOrdersToProcessContainerName
        partitionKey: '/id'
      }
      {
        name: cosmosOrdersProcessedContainerName
        id: cosmosOrdersProcessedContainerName
        partitionKey: '/id'
      }
    ]
  }
}

module servicebus './servicebus.bicep' = {
  scope: resourceGroup
  name: 'servicebus'
  params: {
    serviceBusNamespaceName: 'sb-${resourceSuffixKebabcase}'
    serviceBusQueueName: 'orders'
    serviceBusTopicName: 'topic-flighbooking'
    serviceBusSubscriptionName: 'sub-flighbooking-cdb'
    location: location
    tags: tags
  }
}

module apim './apim.bicep' = {
  name: 'apim'
  scope: resourceGroup
  params: {
    name: 'apim-${resourceSuffixKebabcase}'
    tags: tags
  }
}

module keyVault './keyvault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup
  params: {
    name: take('kv-${resourceSuffixKebabcase}', 24)
    tags: tags
  }
}

module eventGrid './eventgrid.bicep' = {
  name: 'eventGrid'
  scope: resourceGroup
  params: {
    name: 'evgt-${resourceSuffixKebabcase}'
    tags: tags
    storageAccountId: storageAccountData.outputs.storageId
  }
}

module cosmosContributorDataProcessorAssignment './core/database/cosmos/sql/cosmos-sql-role-assign.bicep' = {
  scope: resourceGroup
  name: 'cosmosContributorDataProcessorAssignment'
  params: {
    accountName: cosmos.outputs.accountName
    roleDefinitionId: cosmos.outputs.roleDefinitionId
    principalId: dataProcessingFunctionApp.outputs.principalId
  }
}

module cosmosContributorDataFetcherAssignment './core/database/cosmos/sql/cosmos-sql-role-assign.bicep' = {
  scope: resourceGroup
  name: 'cosmosContributorDataFetcherAssignment'
  params: {
    accountName: cosmos.outputs.accountName
    roleDefinitionId: cosmos.outputs.roleDefinitionId
    principalId: dataFetchingFunctionApp.outputs.principalId
  }
}

module cosmosContributorUserAssignment './core/database/cosmos/sql/cosmos-sql-role-assign.bicep' = {
  scope: resourceGroup
  name: 'cosmosContributorUserAssignment'
  params: {
    accountName: cosmos.outputs.accountName
    roleDefinitionId: cosmos.outputs.roleDefinitionId
    principalId: principalId
  }
}

module servicebusDataSenderAssignment './servicebus-role-assign.bicep' = {
  scope: resourceGroup
  name: 'servicebusDataSenderAssignment'
  params: {
    namespace: servicebus.outputs.namespaceName
    roleDefinitionId: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39' // Azure Service Bus Data Sender
    principalId: dataProcessingFunctionApp.outputs.principalId
  }
}

module servicebusDataReceiverAssignment './servicebus-role-assign.bicep' = {
  scope: resourceGroup
  name: 'servicebusDataReceiverAssignment'
  params: {
    namespace: servicebus.outputs.namespaceName
    roleDefinitionId: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0' // Azure Service Bus Data Receiver
    principalId: dataProcessingFunctionApp.outputs.principalId
  }
}

module servicebusDataSenderAssignmentLogicApp './servicebus-role-assign.bicep' = {
  scope: resourceGroup
  name: 'servicebusDataSenderAssignmentLogicApp'
  params: {
    namespace: servicebus.outputs.namespaceName
    roleDefinitionId: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39' // Azure Service Bus Data Sender
    principalId: dataProcessingLogicApp.outputs.principalId
  }
}

module servicebusDataReceiverAssignmentLogicApp './servicebus-role-assign.bicep' = {
  scope: resourceGroup
  name: 'servicebusDataReceiverAssignmentLogicApp'
  params: {
    namespace: servicebus.outputs.namespaceName
    roleDefinitionId: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0' // Azure Service Bus Data Receiver
    principalId: dataProcessingLogicApp.outputs.principalId
  }
}

module eventGridContributorAssignmentLogicApp './storageaccount-role-assign.bicep' = {
  scope: resourceGroup
  name: 'eventGridContributorAssignmentLogicApp'
  params: {
    name: storageAccountData.outputs.name
    roleDefinitionId: '1e241071-0855-49ea-94dc-649edcd759de' // Event grid contributor role
    principalId: dataProcessingLogicApp.outputs.principalId
  }
}

module blobStorageContributorAssignmentLogicApp './storageaccount-role-assign.bicep' = {
  scope: resourceGroup
  name: 'blobStorageContributorAssignmentLogicApp'
  params: {
    name: storageAccountData.outputs.name
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor

    principalId: dataProcessingLogicApp.outputs.principalId
  }
}


module monitoringMetricsPublisherOrderProcessingAssignment './appinsights-role-assign.bicep' = {
  scope: resourceGroup
  name: 'monitoringMetricsPublisherOrderProcessingAssignment'
  params: {
    name: applicationInsights.outputs.name
    roleDefinitionId: '3913510d-42f4-4e42-8a64-420c390055eb' // Monitoring Metrics Publisher
    principalId: dataProcessingFunctionApp.outputs.principalId
  }
}

module monitoringMetricsPublisherOrderFetchingAssignment './appinsights-role-assign.bicep' = {
  scope: resourceGroup
  name: 'monitoringMetricsPublisherOrderFetchingAssignment'
  params: {
    name: applicationInsights.outputs.name
    roleDefinitionId: '3913510d-42f4-4e42-8a64-420c390055eb' // Monitoring Metrics Publisher
    principalId: dataProcessingFunctionApp.outputs.principalId
  }
}

module dataStorageAccountUserAssignment './storageaccount-role-assign.bicep' = {
  scope: resourceGroup
  name: 'dataStorageAccountUserAssignment'
  params: {
    name: storageAccountData.outputs.name
    roleDefinitionId: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
    principalId: principalId
    principalType: principalType
  }
}

module keyVaultUserAssignment './keyvault-role-assign.bicep' = {
  scope: resourceGroup
  name: 'keyVaultUserAssignment'
  params: {
    name: keyVault.outputs.name
    roleDefinitionId: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7' // Key Vault Secrets Officer
    principalId: principalId
    principalType: principalType
  }
}
