@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('The name of the github org/account that hosts the repo the action')
param githubOrgName string = 'carrio-org'

@description('The name of the github repostitory that hosts the action')
param githubRepoName string = 'trans-outbox-poc'

@description('')
var locationShortName = substring(location,0,3)

@description('Extra entropy to make the role assignment name (guids) more unique.')
var guidSeed = guid(location,environmentShortName)

resource functionContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-03-01-preview' existing = {
  name: 'crcore${environmentShortName}${locationShortName}01'
}

var contributorRoleDefinitionId  = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // --> Contributor
var acrPullRoleDefinitionId  = '7f951dda-4ed3-4680-a7ca-43fe172d538d' // --> AcrPull
var acrPushRoleDefinitionId  = '8311e382-0749-4cb8-b61a-304f252e45ec' // --> AcrPush

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  name: 'userAssignedIdentityDeployment'
  params: {
    // Required parameters
    name: 'id-submit-pipeline-${environmentShortName}-${locationShortName}-01'
    // Non-required parameters
    location: location
    federatedIdentityCredentials: [
      {
        name: 'forUseInGitHubActions'
        issuer: 'https://token.actions.githubusercontent.com'
        audiences: [
          'api://AzureADTokenExchange'
        ]
        subject: 'repo:${githubOrgName}/${githubRepoName}:environment:${environmentShortName}'
      }
    ]
  }
}

// Assign the managed identity the contributor role to the container app
resource containerAppRoleAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: functionContainerApp
  name: guid(contributorRoleDefinitionId,functionContainerApp.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: userAssignedIdentity.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',contributorRoleDefinitionId)
  }
}

// Assign the managed identity to pull from the container registry
resource acrPullRoleAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(acrPullRoleDefinitionId,containerRegistry.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: userAssignedIdentity.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',acrPullRoleDefinitionId)
  }
}

// Assign the managed identity to pull from the container registry
resource acrPushRoleAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(contributorRoleDefinitionId,containerRegistry.name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: userAssignedIdentity.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',acrPushRoleDefinitionId)
  }
}


// Looks like we have to grant the managed identity the contributor role to the whole resource group 
resource resourceGroupContributorAssigment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(contributorRoleDefinitionId,resourceGroup().name,guidSeed)
  properties: {
    principalType: 'ServicePrincipal'
    principalId: userAssignedIdentity.outputs.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',contributorRoleDefinitionId)
  }
}
