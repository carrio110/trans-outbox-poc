@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
  name: 'cosno-queue-${environmentShortName}-${locationShortName}-01'
}

resource cosmosDBQueueDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-11-15' existing = {
  parent: cosmosDBAccount
  name: 'cosmos-queue-${environmentShortName}-${locationShortName}-01'
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: 'cae-submit-${environmentShortName}-${locationShortName}-01'
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
}

resource daprCosmosDbComponent 'Microsoft.App/managedEnvironments/daprComponents@2025-02-02-preview' = {
  parent: containerAppEnvironment
  name: 'dapr-conf-submit-queue-state'
  properties: {
    componentType: 'state.azure.cosmosdb'
    ignoreErrors: false
    initTimeout: '300' //seconds
    metadata: [
      {
        name: 'url'
        secretRef: 'cosmos-db-account-uri'
      }
      {
        name: 'database'
        value: cosmosDBQueueDatabase.name
      }
      {
        name: 'collection'
        value: 'cosmos-queue-state-${environmentShortName}-${locationShortName}-01'
      }
      {
        name: 'outboxPublishPubsub'
        value: 'dapr-conf-submit-queue-transoutbox-pubsub'
      }
      {
        name: 'outboxPublishTopic'
        value: 'sbt-request-submission-${environmentShortName}-${locationShortName}-01'
      }
      {
        name: 'outboxPubsub'
        value: 'cosmos-queue-state-${environmentShortName}-${locationShortName}-01'
      }
      {
        name: 'outboxDiscardWhenMissingState'
        value: 'false'
      }
    ]
    scopes: [
      functionApp.name
    ]
    secretStoreComponent: 'dapr-conf-submit-key-vault'
    // serviceComponentBind: []
    version: '1.0'
  }
}

/*
  - name: outboxPublishPubsub # Required
    value: "mypubsub"
  - name: outboxPublishTopic # Required
    value: "newOrder"
  - name: outboxPubsub # Optional
    value: "myOutboxPubsub"
  - name: outboxDiscardWhenMissingState #Optional. Defaults to false
    value: false
*/
