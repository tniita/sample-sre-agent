targetScope = 'subscription'

param resourceGroupName string = 'rg-cc-vscode-comparison'
param location string = 'japanwest'
param planName string
param webAppName string
param skuName string = 'B1'
param publicNetworkAccessEnabled bool = false
param resourceTags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceGroupName
  location: location
}

module app './main.bicep' = {
  name: 'appsvc-resources'
  scope: resourceGroup
  params: {
    location: location
    planName: planName
    webAppName: webAppName
    skuName: skuName
    publicNetworkAccessEnabled: publicNetworkAccessEnabled
    resourceTags: resourceTags
  }
}

output resourceGroupName string = resourceGroup.name
output webAppName string = app.outputs.webAppName
output webAppUrl string = app.outputs.webAppUrl
output planResourceId string = app.outputs.planResourceId
output webAppResourceId string = app.outputs.webAppResourceId
output principalId string = app.outputs.principalId