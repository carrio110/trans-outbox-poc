@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

resource functionContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
}

module serviceBusNamespace 'br/public:avm/res/service-bus/namespace:0.14.1' = {
  name: 'servicebus-queue-${environmentShortName}-${locationShortName}'
  params: {
    // Required parameters
    name: 'sbns-queue-${environmentShortName}-${locationShortName}-02'
    // Non-required parameters
    authorizationRules: []
    diagnosticSettings: []
    networkRuleSets: {
      defaultAction: 'Allow'
      ipRules: []
      trustedServiceAccessEnabled: true
      virtualNetworkRules: []
    }
    privateEndpoints: []
    publicNetworkAccess: 'Enabled'
    queues: []
    tags: {}
    topics: [
      {
        name: 'sbt-request-submission-${environmentShortName}-${locationShortName}-01'
        roleAssignments: [
          {
            principalId: functionContainerApp.identity.principalId
            roleDefinitionIdOrName: 'Azure Service Bus Data Sender'
          }
          {
            principalId: functionApp.identity.principalId
            roleDefinitionIdOrName: 'Azure Service Bus Data Sender'
          }
        ]
        /*
        subscriptions: [
          {
            name: 'sbts-request-fulfilment-${environmentShortName}-${locationShortName}-01'
            rules: [
              {
                name: 'rule-due-to-schedule'
                filterType: 'SqlFilter'
                sqlFilter: {
                  sqlExpression: ''
                  requiresPreprocessing: false
                }

              }
            ]
          }
        ]
        */
        authorizationRules: []
      }
      {
        name: 'sbt-request-submission-outbox-${environmentShortName}-${locationShortName}-01'
        // roleAssignments: []
        authorizationRules: []
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: 'kv-queue-${environmentShortName}-${locationShortName}-01'
}

resource serviceBusStateConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'pubsub-queue-state-connection-string'
  parent: keyVault
  properties: {
    value: serviceBusNamespace.outputs.serviceBusEndpoint
    contentType: 'application/text'
  }
}
// secretref: 'pubsub-queue-state-connection-string'
