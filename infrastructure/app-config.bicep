@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

/*
resource cosmosaccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
    name: 'cosno-queue-${environmentShortName}-${locationShortName}-01'
}
*/

resource submitFunctionApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
}

module configurationStore 'br/public:avm/res/app-configuration/configuration-store:0.6.3' = {
    name: 'app-configuration-store-queue-${environmentShortName}-${locationShortName}'
    params: {
        name: 'appcs-queue-${environmentShortName}-${locationShortName}-01'
        location: location
        sku: 'Free'
        disableLocalAuth: false
        publicNetworkAccess: 'Enabled'
        keyValues: [
            {
                contentType: 'application/text'
                name: 'Queue-DaprOutboxCreateURI'
                value: 'http://localhost:3601/v1.0/state/statestore/transaction'
            }
        ]
        managedIdentities: {
            systemAssigned: true
        }
        roleAssignments: [
            {
                principalId: submitFunctionApp.identity.principalId
                roleDefinitionIdOrName: 'App Configuration Data Reader'
            }
        ]
        enableTelemetry: false
    }
}

// output appconfigConnectionString string = configurationStore.outputs.endpoint
