@description('Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param skuName string = 'B1'

@description('Describes plan\'s instance count')
@minValue(1)
@maxValue(3)
param skuCapacity int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Admin SQL Server username')
param adminSqlUsername string

@description('Admin SQL Server password')
@secure()
param adminSqlPassword string

var appPlanName = 'plan-${uniqueString(resourceGroup().id)}'
var appName = 'app-sonarqube-${uniqueString(resourceGroup().id)}'
var sqlServerName = 'sql-${location}-${uniqueString(resourceGroup().id)}'
var sqlDatabase = 'sqldb-sonarqube'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  location: location
  name: sqlServerName
  tags: {
    displayName: 'Sql Server'
  }
  properties: {
    administratorLogin: adminSqlUsername
    administratorLoginPassword: adminSqlPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
  }
}

resource allowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource sonarQubeDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabase
  location: location
  tags: {
    displayName: 'SonarQube Database'
  }
  sku: {
    name: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
  }
}

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

resource webApplication 'Microsoft.Web/sites@2019-08-01' = {
  name: appName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/appServicePlan': 'Resource'
    displayName: 'SonarQube web app'
  }
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|SONARQUBE'
    }
    serverFarmId: appServicePlan.id
  }
}

resource appsettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  kind: 'string'
  parent: webApplication
  properties: {
    SONARQUBE_JDBC_URL: 'jdbc:sqlserver://${sqlServer.properties.fullyQualifiedDomainName},1433;database=${sqlDatabase};encrypt=true;'
    SONARQUBE_JDBC_USERNAME: adminSqlUsername
    SONARQUBE_JDBC_PASSWORD: adminSqlPassword
    sonar_path_data: '/home/sonarqube/data'
  }
}
