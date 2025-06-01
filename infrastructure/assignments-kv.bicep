@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('The 3-letter mnemonic for the Azure region specified in location.')
var locationShortName = substring(location,0,3)

@description('Extra entropy to make the role assignment name (guids) more unique.')
var guidSeed = guid(location,environmentShortName)

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: 'kv-queue-${environmentShortName}-${locationShortName}-01'
}

// The container app environment needs access to the key vault so that its dapr components are allows to access it.
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: 'cae-submit-${environmentShortName}-${locationShortName}-01'
}

resource functionContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
}

resource appConfigStore 'Microsoft.AppConfiguration/configurationStores@2024-05-01' existing = {
  name: 'appcs-queue-${environmentShortName}-${locationShortName}-01'
}

var keyVaultAppSecretManagementRoleDefinitionId  = '2536729d-d1f4-4afb-bc84-dcdb90a4b760' // --> Key Vault App Secret Management

resource roleAssigmentContainerAppEnv 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVaultAppSecretManagementRoleDefinitionId,containerAppEnvironment.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: containerAppEnvironment.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',keyVaultAppSecretManagementRoleDefinitionId)
  }
}

resource roleAssigmentContainerApp 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVaultAppSecretManagementRoleDefinitionId,functionContainerApp.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: functionContainerApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',keyVaultAppSecretManagementRoleDefinitionId)
  }
}

resource roleAssigmentAppConfigStore'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVaultAppSecretManagementRoleDefinitionId,appConfigStore.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: appConfigStore.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',keyVaultAppSecretManagementRoleDefinitionId)
  }
}
