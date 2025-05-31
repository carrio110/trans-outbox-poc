@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'app-service-plan-submit-functionapp-${environmentShortName}-${locationShortName}-01'
  params: {
    // Required parameters
    name: 'asp-submit-${environmentShortName}-${locationShortName}-01'
    // reserved: true is required when deploying a Linux app service plan.
    reserved: true
    // Non-required parameters
    diagnosticSettings: []
    kind: 'linux'
    skuCapacity: 0
    skuName: 'Y1'
    tags: {}
    
    zoneRedundant: false
  }
}

// Azure Function Apps require a general-purpose v2 storage account that supports Blob, Queue, and Table storage. 
// This storage account is used for managing triggers, logging, and other operations related to the function app's execution. 

module storageAccount 'br/public:avm/res/storage/storage-account:0.9.1' = {
  name: 'storage-account-submit-functionapp-${environmentShortName}-${locationShortName}-01'
  params: {
    // Required parameters
    name: 'st${locationShortName}submitapifunc${environmentShortName}01'
    // Non-required parameters
    kind: 'StorageV2'
    location: location
    allowBlobPublicAccess: false
    diagnosticSettings: []
    enableHierarchicalNamespace: false
    enableNfsV3: false
    enableSftp: false
    largeFileSharesState: 'Disabled'
    localUsers: []
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: []
    }
    managementPolicyRules: []
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    privateEndpoints: []
    requireInfrastructureEncryption: false
    sasExpirationPeriod: '180.00:00:00'
    skuName: 'Standard_LRS'
    tags: {}
  }
}

/*
module functionApp 'br/public:avm/res/web/site:0.16.0' = {
  name: 'functionapp-submit-${environmentShortName}-${locationShortName}'
  params: {
    // Required parameters
    kind: 'functionapp,linux'
    name: 'func-submit-${environmentShortName}-${locationShortName}-01'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    // Non-required parameters
    basicPublishingCredentialsPolicies: []
    configs: [
      {
        // applicationInsightResourceId: '<applicationInsightResourceId>'
        name: 'appsettings'
        properties: {
          AzureFunctionsJobHost__logging__logLevel__default: 'Debug'
          // EASYAUTH_SECRET: '<EASYAUTH_SECRET>'
          FUNCTIONS_EXTENSION_VERSION: '~4'
          FUNCTIONS_WORKER_RUNTIME: 'powershell'
          WEBSITE_RUN_FROM_PACKAGE: '1'
          AzureWebJobsStorage__accountName: storageAccount.outputs.name
          AzureWebJobsStorage__blobServiceUri: 'https://${storageAccount.outputs.name}.blob.core.windows.net'
          AzureWebJobsStorage__queueServiceUri: 'https://${storageAccount.outputs.name}.queue.core.windows.net'
          AzureWebJobsStorage__tableServiceUri: 'https://${storageAccount.outputs.name}.table.core.windows.net'
        }
        storageAccountResourceId: storageAccount.outputs.resourceId
        storageAccountUseIdentityAuthentication: true
      }
    ]
    location: location
    managedIdentities: {
      systemAssigned: true
    }

    siteConfig: {
      numberOfWorkers: 1
      alwaysOn: false
      minTlsVersion: '1.2'
      linuxFxVersion: 'PowerShell|7.4'
    }
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}
*/

@description('Create a log analytics workspace for the container app environment.')
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: containerAppLogAnalyticsName
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}




resource functionAppWithDapr 'Microsoft.Web/sites@2024-04-01' = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-03'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appServicePlan.outputs.resourceId
    siteConfig: {
      numberOfWorkers: 1
      alwaysOn: false
      minTlsVersion: '1.2'
      linuxFxVersion: 'PowerShell|7.4'
    }
    daprConfig: {
      enabled: true
      logLevel: 'debug'
    }
   }

}

resource functionAppConfig 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: functionAppWithDapr
  kind: 'string'
  name: 'appsettings'
  properties: {
    AzureFunctionsJobHost__logging__logLevel__default: 'Debug'
    // EASYAUTH_SECRET: '<EASYAUTH_SECRET>'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'powershell'
    WEBSITE_RUN_FROM_PACKAGE: '1'
    AzureWebJobsStorage__accountName: storageAccount.outputs.name
    AzureWebJobsStorage__blobServiceUri: 'https://${storageAccount.outputs.name}.blob.core.windows.net'
    AzureWebJobsStorage__queueServiceUri: 'https://${storageAccount.outputs.name}.queue.core.windows.net'
    AzureWebJobsStorage__tableServiceUri: 'https://${storageAccount.outputs.name}.table.core.windows.net'
    
  }
}
