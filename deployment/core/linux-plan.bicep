param appPlanName string
param location string
param skuName string
param skuCapacity int

resource appServicePlan 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appPlanName
  location: location
  kind: 'linux'
  tags: {
    displayName: 'App Service Plan'
  }
  properties: {
    reserved: true
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

output Id string = appServicePlan.id
