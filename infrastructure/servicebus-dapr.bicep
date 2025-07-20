@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: 'cae-submit-${environmentShortName}-${locationShortName}-01'
}

/*
resource functionContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
}
*/

resource functionApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
}

resource daprServiceBusStateComponent 'Microsoft.App/managedEnvironments/daprComponents@2025-02-02-preview' = {
  parent: containerAppEnvironment
  name: 'dapr-conf-submit-queue-state-pubsub'
  properties: {
    componentType: 'pubsub.azure.servicebus.topics'
    ignoreErrors: false
    initTimeout: '300' //seconds
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'pubsub-queue-state-connection-string'
      }
    ]
    scopes: [
      // functionContainerApp.name
      functionApp.name
    ]
    secretStoreComponent: 'dapr-conf-submit-key-vault'
    // serviceComponentBind: []
    version: '1.0'
  }
}

resource daprCosmosDbComponent 'Microsoft.App/managedEnvironments/daprComponents@2025-02-02-preview' = {
  parent: containerAppEnvironment
  name: 'dapr-conf-submit-queue-transoutbox-pubsub'
  properties: {
    componentType: 'pubsub.azure.servicebus.topics'
    ignoreErrors: false
    initTimeout: '300' //seconds
    metadata: [
      {
        name: 'connectionString'
        secretRef: 'pubsub-queue-state-connection-string'
      }
    ]
    scopes: [
      // functionContainerApp.name
      functionApp.name
    ]
    secretStoreComponent: 'dapr-conf-submit-key-vault'
    // serviceComponentBind: []
    version: '1.0'
  }
}
