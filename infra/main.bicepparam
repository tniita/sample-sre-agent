using './main.bicep'

param location = 'japanwest'
param planName = 'cc-vscode-demo-plan-hf4i4u2mifhpi'
param webAppName = 'cc-vscode-demo-web-hf4i4u2mifhpi'
param skuName = 'B1'
param publicNetworkAccessEnabled = true
param resourceTags = {
  SecurityControl: 'Ignore'
}