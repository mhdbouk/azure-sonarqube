@description('Location for all resources.')
param location string = resourceGroup().location

@description('Admin SQL Server username')
param adminSqlUsername string

@description('Admin SQL Server password')
@secure()
param adminSqlPassword string

param sqlServerName string = 'sql-${uniqueString(resourceGroup().id)}'
param sqlDatabaseName string = 'sqldb-sonarqube'

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

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: {
    displayName: 'SonarQube Database'
  }
  sku: {
    name: 'Basic'
  }

  properties: {
    collation: 'SQL_Latin1_General_CP1_CS_AS'
    maxSizeBytes: 1073741824
  }
}

output fullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
