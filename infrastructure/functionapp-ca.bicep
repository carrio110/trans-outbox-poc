@description('The Azure region to which the resource will be deployed.')
param location string = 'uksouth'

@description('The software development environment to which the resource will be deployed.')
param environmentShortName string = 'dev'

@description('')
var locationShortName = substring(location,0,3)

@description('Specifies the docker container image to deploy.')
param containerImage string = 'mcr.microsoft.com/azure-functions/powershell:4-powershell7.4'

@description('Specifies the container port.')
param targetPort int = 80

@description('Number of CPU cores the container can use. Can be with a maximum of two decimals.')
param cpuCore string = '0.5'

@description('Amount of memory (in gibibytes, GiB) allocated to the container up to 4GiB. Can be with a maximum of two decimals. Ratio with CPU cores must be equal to 2.')
param memorySize string = '1'

@description('Minimum number of replicas that will be deployed')
param minReplicas int = 1

@description('Maximum number of replicas that will be deployed')
param maxReplicas int = 3

@description('Specifies the Functions runtime')
param functionsRuntime string = 'powershell'

/*
@description('Create a container app environment.')
resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: containerAppEnvName
  location: location
  properties: {
    publicNetworkAccess: 'Enabled'
    workloadProfiles: [
        {
            name: 'Consumption'
            workloadProfileType: 'Consumption'
        }
    ]
  }
}
*/

/*
@description('Create a storage account for the function app.')
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}
*/

resource containerAppEnv 'Microsoft.App/managedEnvironments@2025-01-01' existing = {
  name: 'managedEnvironment-rguksapiprod01'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: 'stukssubmitapifuncdev01'
}

/*
@description('Create an application insights resource for the function app.')
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}
*/

@description('Create a native functions container app.')
resource functionsContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
  location: location
  kind: 'functionapp'
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      dapr: {}
      ingress: {
        external: true
        targetPort: targetPort
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      secrets: [
        {
          name: 'azurewebjobsstorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        /*{
          name: 'appinsightsconnectionstring'
          value: appInsights.properties.ConnectionString
        }*/
      ]
    }
    template: {
      containers: [
        {
          name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
          image: containerImage
          env: [
            {
              name: 'AzureWebJobsStorage'
              secretRef: 'azurewebjobsstorage'
            }
            /* {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              secretRef: 'appinsightsconnectionstring'
            } */
            {
              name: 'FUNCTIONS_WORKER_RUNTIME'
              value: functionsRuntime
            }
          ]
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output functionsContainerAppId string = functionsContainerApp.id
output functionsContainerAppFQDN string = functionsContainerApp.properties.configuration.ingress.fqdn
