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
    // ACR names may contain alpha numeric characters only and must be between 5 and 50 characters.
    name: 'crcore${environmentShortName}${locationShortName}01'
    // Non-required parameters
    acrAdminUserEnabled: false
    acrSku: 'Basic'
    azureADAuthenticationAsArmPolicyStatus: 'enabled'
    diagnosticSettings: []
    exportPolicyStatus: 'enabled'
    location: location
    privateEndpoints: []
    quarantinePolicyStatus: 'disabled'
    replications: []
    roleAssignments: []
    softDeletePolicyDays: 7
    softDeletePolicyStatus: 'disabled'
    tags: {}
    trustPolicyStatus: 'enabled'
  }
}
