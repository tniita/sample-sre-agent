@description('Deployment region.')
param location string = resourceGroup().location

@description('Prefix used when explicit resource names are omitted.')
param appNamePrefix string = 'cc-vscode-demo'

@description('Existing plan name for adoption, or a new name for a separate environment.')
param planName string = '${appNamePrefix}-plan-${uniqueString(resourceGroup().id)}'

@description('Globally unique web app name.')
param webAppName string = '${appNamePrefix}-web-${uniqueString(resourceGroup().id)}'

@allowed([
  'F1'
  'B1'
  'B2'
  'B3'
])
param skuName string = 'B1'

@description('Enable public HTTPS access only with the required organizational approval.')
param publicNetworkAccessEnabled bool = false

@description('Resource tags. SecurityControl=Ignore is a policy exception, not a general requirement.')
param resourceTags object = {}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: resourceTags
  kind: 'linux'
  sku: {
    name: skuName
    capacity: 1
  }
  properties: {
    reserved: true
    perSiteScaling: false
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  tags: resourceTags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    publicNetworkAccess: publicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
    clientAffinityEnabled: true
    siteConfig: {
      linuxFxVersion: 'NODE|24-lts'
      appCommandLine: 'node index.js'
      alwaysOn: skuName != 'F1'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      http20Enabled: true
      use32BitWorkerProcess: true
      webSocketsEnabled: false
      scmIpSecurityRestrictionsUseMain: false
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~24'
        }
      ]
    }
  }
}

resource ftpPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: webApp
  name: 'ftp'
  properties: {
    allow: false
  }
}

resource scmPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: webApp
  name: 'scm'
  properties: {
    allow: false
  }
}

output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output planResourceId string = plan.id
output webAppResourceId string = webApp.id
output principalId string = webApp.identity.principalId
