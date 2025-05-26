@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

resource cosmosaccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
    name: 'cosno-queue-${environmentShortName}-${locationShortName}-01'
}

resource submitFunctionApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
}

module vault 'br/public:avm/res/key-vault/vault:0.9.0' = {
  name: 'key-vault-queue-${environmentShortName}-${locationShortName}'
  params: {
    // Required parameters
    name: 'kv-queue-${environmentShortName}-${locationShortName}-01'
    // Non-required parameters
    sku: 'standard'
    diagnosticSettings: []
    enablePurgeProtection: false
    enableRbacAuthorization: true
    keys: []
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    secrets: [
      {
        name: 'app-config-store-host-URI'
        value: ''
      }
      {
        name: 'cosmos-endpoint'
        value: cosmosaccount.listConnectionStrings().connectionStrings[0].connectionString
        roleAssignments: [
        ]
      }
      {
        name: 'cosmos-readwrite-key'
        value: cosmosaccount.listKeys().primaryMasterKey
      }
    ]
    softDeleteRetentionInDays: 7
    tags: {}
  }
}
