@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('The 3-letter mnemonic for the Azure region specified in location.')
var locationShortName = substring(location,0,3)

@description('Extra entropy to make the role assignment name (guids) more unique.')
var guidSeed = guid(location,environmentShortName)

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: 'st${locationShortName}submitapifunc${environmentShortName}01'
}

resource functionContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
}

var storageBlobDataOwnerRoleDefinitionId  = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // --> Storage Blob Data Owner (Required)
var storageQueueDataContributorRoleDefinitionId = '974c5e8b-45b9-4653-ba55-5f855dd0fb88' // --> Storage Queue Data Contributor
var storageTableDataContributorRoleDefinitionId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' //--> Storage Table Data Contributor

resource roleAssigmentBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageBlobDataOwnerRoleDefinitionId,storageAccount.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: functionContainerApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',storageBlobDataOwnerRoleDefinitionId)
  }
}

resource roleAssigmentQueue 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageQueueDataContributorRoleDefinitionId,storageAccount.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: functionContainerApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',storageQueueDataContributorRoleDefinitionId)
  }
}

resource roleAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageTableDataContributorRoleDefinitionId,storageAccount.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: functionContainerApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',storageTableDataContributorRoleDefinitionId)
  }
}
