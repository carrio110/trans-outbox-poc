@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

module databaseAccount 'br/public:avm/res/document-db/database-account:0.15.0' = {
  name: 'cosmosdb-queue-${environmentShortName}-${locationShortName}'
  params: {
    // Required parameters
    name: 'cosno-queue-${environmentShortName}-${locationShortName}-01'
    // Non-required parameters
    defaultConsistencyLevel: 'Session'
    databaseAccountOfferType: 'Standard'
    enableFreeTier: true
    zoneRedundant: false
    managedIdentities: {
      systemAssigned: false
    }
    sqlDatabases: [
      {
        name: 'cosmos-queue-${environmentShortName}-${locationShortName}-01'
        containers: [
          {
            name: 'cosco-queue-requests-${environmentShortName}-${locationShortName}-01'
            paths: [
              '/customerId'
            ]
            kind: 'Hash'
          }
        ]
      }
    ]
  }
}
