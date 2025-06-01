@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

@description('Extra entropy to make the role assignment name (guids) more unique.')
var guidSeed = guid(location,environmentShortName)

module registry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: 'registryDeployment'
  params: {
    // Required parameters
    name: 'cr-function-images-${environmentShortName}-${locationShortName}-01'
    // Non-required parameters
    acrAdminUserEnabled: false
    acrSku: 'Basic'
    azureADAuthenticationAsArmPolicyStatus: 'enabled'
    diagnosticSettings: []
    exportPolicyStatus: 'enabled'
    location: location
    privateEndpoints: []
    quarantinePolicyStatus: 'enabled'
    replications: []
        roleAssignments: [
      {
        name: guid(keyVaultAppSecretManagementRoleDefinitionId,functionContainerApp.name,guidSeed)
        principalId: '<principalId>'
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Owner'
      }
      {
        name: '<name>'
        principalId: '<principalId>'
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
      }
      {
        principalId: '<principalId>'
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: '<roleDefinitionIdOrName>'
      }
    ]
    softDeletePolicyDays: 7
    softDeletePolicyStatus: 'disabled'
    tags: {}
    trustPolicyStatus: 'enabled'
  }
}
