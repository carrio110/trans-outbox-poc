metadata description = 'Assign RBAC role for data plane access to Azure Cosmos DB for NoSQL.'

@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('The 3-letter mnemonic for the Azure region specified in location.')
var locationShortName = substring(location,0,3)

@description('Extra entropy to make the role assignment name (guids) more unique.')
var guidSeed = guid(location,environmentShortName)

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
  name: 'cosno-queue-${environmentShortName}-${locationShortName}-01'
}

resource functionContainerApp 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
}

var cosmosDbDataPlaneOwnerRoleRoleDefinitionId = '0a9ee32a-d5fa-4959-b07c-85dc90b5d1e2' // --> Azure Cosmos DB for NoSQL Data Plane Owner
resource assignment1 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  name: guid(cosmosDbDataPlaneOwnerRoleRoleDefinitionId, functionContainerApp.name, cosmosAccount.id)
  parent: cosmosAccount
  properties: {
    principalId: functionContainerApp.identity.principalId
    roleDefinitionId: '/subscriptions/aec6ec2e-c1fb-464e-b2cc-f09dc94c7280/resourceGroups/rg-uks-api-prod-01/providers/Microsoft.DocumentDB/databaseAccounts/cosno-queue-dev-uks-01/	sqlRoleDefinitions/0a9ee32a-d5fa-4959-b07c-85dc90b5d1e2'
    scope: cosmosAccount.id
  }
}



var cosmosDbDataContributorRoleRoleDefinitionId = '00000000-0000-0000-0000-000000000002' // --> Cosmos DB Built-in Data Contributor
resource assignment2 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  name: guid(cosmosDbDataContributorRoleRoleDefinitionId, functionContainerApp.name, cosmosAccount.id)
  parent: cosmosAccount
  properties: {
    principalId: functionContainerApp.identity.principalId
    roleDefinitionId: '/subscriptions/aec6ec2e-c1fb-464e-b2cc-f09dc94c7280/resourceGroups/rg-uks-api-prod-01/providers/Microsoft.DocumentDB/databaseAccounts/cosno-queue-dev-uks-01/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    scope: cosmosAccount.id
  }
}

//output assignmentId string = assignment.id
