@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: 'cae-submit-${environmentShortName}-${locationShortName}-01'
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'func-submit-${environmentShortName}-${locationShortName}-01'
  location: location
  kind: 'functionapp,linux,container,azurecontainerapps'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    daprConfig: {
      enabled: true
      logLevel: 'debug'
      enableApiLogging: true
      // dapr appId is used by the scope element of the dapr component definition.
      appId: 'func-submit-${environmentShortName}-${locationShortName}-01'
    }
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/azure-functions/powershell:4-powershell7.4'
      functionAppScaleLimit: 10
      minimumElasticInstanceCount: 0
    }
    managedEnvironmentId: containerAppEnvironment.id
    workloadProfileName: 'Consumption'
    resourceConfig: {
      cpu: json('0.5')
      memory: '1Gi'
    }
    httpsOnly: true
    storageAccountRequired: false
  }
}

resource functionAppConfig 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: functionApp
  name: 'web'
  location: 'UK South'
  properties: {
    linuxFxVersion: 'DOCKER|mcr.microsoft.com/azure-functions/powershell:4-powershell7.4'
    functionAppScaleLimit: 10
    minimumElasticInstanceCount: 0
  }
}
