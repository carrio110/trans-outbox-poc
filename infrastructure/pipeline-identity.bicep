@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('The name of the github org/account that hosts the repo the action')
param githubOrgName string = 'carrio110/trans-outbox-poc'

@description('The name of the github repostitory that hosts the action')
param githubRepoName string = 'trans-outbox-poc'

@description('The name of the repo environment')
param githubEnvironmentName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

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
        subject: 'repo:${githubOrgName}/${githubRepoName}:${githubEnvironmentName}'
      }
    ]
  }
}
