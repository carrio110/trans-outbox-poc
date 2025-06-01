@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: 'cae-submit-${environmentShortName}-${locationShortName}-01'
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: 'kv-queue-${environmentShortName}-${locationShortName}-01'
}
resource functionContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
}

resource daprKeyVaultComponent 'Microsoft.App/managedEnvironments/daprComponents@2025-02-02-preview' = {
  parent: containerAppEnvironment
  name: 'dapr-conf-submit-key-vault'
  properties: {
    componentType: 'secretstores.azure.keyvault'
    ignoreErrors: false
    initTimeout: '300' //seconds
    metadata: [
      {
        name: 'vaultName'
        value: keyVault.name
      }
      {
        name: 'azureEnvironment '
        value: 'AZUREPUBLICCLOUD'
      }
    ]
    scopes: [
      functionContainerApp.name
      functionApp.name
    ]
    secrets: []
    // secretStoreComponent: 'string'
    // serviceComponentBind: []
    version: '1.0'
  }
}
