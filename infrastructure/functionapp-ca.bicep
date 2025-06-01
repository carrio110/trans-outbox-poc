// Taken from here:
// https://github.com/Azure/azure-functions-on-container-apps/blob/main/samples/ACAKindfunctionapp/main.bicep

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

@description('Specifies the Functions runtime')
param functionsRuntime string = 'powershell'

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.11.2' = {
  name: 'workspaceDeployment'
  params: {
    // Required parameters
    name: 'law-core-${environmentShortName}-${locationShortName}-01'
    // Non-required parameters
    location: location
    skuName: 'PerGB2018'
  }
}

@description('Create a container app environment.')
module containerAppEnv 'br/public:avm/res/app/managed-environment:0.11.2' = {
  name: 'managedEnvironmentDeployment'
  params: {
    // Required parameters
    name: 'cae-submit-${environmentShortName}-${locationShortName}-01'
    // Non-required parameters
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.outputs.logAnalyticsWorkspaceId
        sharedKey: logAnalytics.outputs.primarySharedKey
      }
      
    }
    internal: false
    managedIdentities: {
      systemAssigned: true
    }
    zoneRedundant: false
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

@description('Create an application insights resource for the function app.')
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-submit-${environmentShortName}-${locationShortName}-01'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.outputs.resourceId
  }
}

@description('Create a storage account for the function app.')
module storageAccount 'br/public:avm/res/storage/storage-account:0.9.1' = {
  name: 'storage-account-submit-functionapp-${environmentShortName}-${locationShortName}-01'
  params: {
    // Required parameters
    name: 'st${locationShortName}submitapifunc${environmentShortName}01'
    // Non-required parameters
    kind: 'StorageV2'
    location: location
    allowBlobPublicAccess: false
    diagnosticSettings: []
    enableHierarchicalNamespace: false
    enableNfsV3: false
    enableSftp: false
    largeFileSharesState: 'Disabled'
    localUsers: []
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: []
    }
    managementPolicyRules: []
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    privateEndpoints: []
    requireInfrastructureEncryption: false
    sasExpirationPeriod: '180.00:00:00'
    skuName: 'Standard_LRS'
    supportsHttpsTrafficOnly: true
    tags: {}
  }
}

@description('Create a native functions container app.')
resource functionsContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.outputs.resourceId
    configuration: {
      dapr: {
        enabled: true
        logLevel: 'debug'
        enableApiLogging: true
        // dapr appId is used by the scope element of the dapr component definition.
        appId: 'ca-submit-${environmentShortName}-${locationShortName}-01'
      }
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
    }
    template: {
      containers: [
        {
          name: 'ct-submit-${environmentShortName}-${locationShortName}-01'
          image: containerImage
          env: [
            {
              name: 'AzureWebJobsStorage__accountName'
              value: storageAccount.outputs.name
            }
            {
              name: 'APPLICATIONINSIGHTS_AUTHENTICATION_STRING'
              value: 'Authorization=AAD'
            }
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
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
}

/*
AVM container app module does not yet support the kind: functionapp configuration.

module containerApp 'br/public:avm/res/app/container-app:0.16.0' = {
  name: 'containerAppDeployment'
  params: {
    // Required parameters
    environmentResourceId: containerAppEnv.outputs.resourceId
    name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
    kind: 'functionapp'
    dapr: {
      enabled: true
      logLevel: 'debug'
      enableApiLogging: true
    }
    managedIdentities: {
      systemAssigned: true
    }
    scaleSettings: {
      maxReplicas: 2
      minReplicas: 1
    }
    containers: [
      {
        image: containerImage
        name: 'ca-submit-${environmentShortName}-${locationShortName}-01'
        resources: {
          cpu: '0.5'
          memory: '1Gi'
        }
        env: [
            {
              name: 'AzureWebJobsStorage__accountName'
              value: storageAccount.outputs.name
            }
            {
              name: 'APPLICATIONINSIGHTS_AUTHENTICATION_STRING'
              value: 'Authorization=AAD'
            }
            {
              name: 'FUNCTIONS_WORKER_RUNTIME'
              value: functionsRuntime
            }
          ]
      }
    ]

  }
}
*/
output functionsContainerAppId string = functionsContainerApp.id
output functionsContainerAppFQDN string = functionsContainerApp.properties.configuration.ingress.fqdn
