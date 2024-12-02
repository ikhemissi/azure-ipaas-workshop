param appName string
param planName string
param location string = resourceGroup().location
param storageAccountName string
param storageAccountConnectionString string
param applicationInsightsName string
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: planName
  location: location
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
    capacity: 1 // Number of instances
  }
  properties: {
    targetWorkerCount: 1
    targetWorkerSizeId: 0 // Corresponds to WS1
  }
  tags: tags
}

resource logicApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  kind: 'workflowapp,functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        { 
          name: 'APP_KIND'
          value: 'workflowApp' 
        }
        { 
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows' 
        }
        { 
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)' 
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountConnectionString
        }
        { 
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING' 
          value: storageAccountConnectionString
        }
        { 
          name: 'WEBSITE_CONTENTSHARE' 
          value: toLower(appName) 
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value : 'InstrumentationKey=${appInsights.properties.InstrumentationKey};IngestionEndpoint=https://${location}.in.applicationinsights.azure.com/;LiveEndpoint=https://${location}.livediagnostics.monitor.azure.com/'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
  }
  tags: tags
  dependsOn: [
    appServicePlan
    storage
  ]
}

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-owner
var storageBlobDataOwnerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')

// Allow access from function app to storage account using a managed identity
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storage.id, logicApp.id, storageBlobDataOwnerRoleId)
  scope: storage
  properties: {
    roleDefinitionId: storageBlobDataOwnerRoleId
    principalId: logicApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output principalId string = logicApp.identity.principalId
