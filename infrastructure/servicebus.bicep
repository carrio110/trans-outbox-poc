@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)



resource submitFunctionApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
}

module serviceBusNamespace 'br/public:avm/res/service-bus/namespace:0.14.1' = {
  name: 'servicebus-queue-${environmentShortName}-${locationShortName}'
  params: {
    // Required parameters
    name: 'sbns-queue-${environmentShortName}-${locationShortName}-01'
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
            principalId: submitFunctionApp.identity.principalId
            roleDefinitionIdOrName: 'Azure Service Bus Data Sender'
          }
        ]
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
        authorizationRules: []
          }
        ]
        

      }
    ]
  }
}
