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

param githubRepo string = 'https://github.com/mhdbouk/azure-sonarqube.git'

@allowed([
  'Community'
  'Developer'
  'Enterprise'
  'Data Center'
])
param sonarQubeEdition string = 'Community'

@description('Default is latest, change it to use a specific version')
param sonarQubeVersion string = 'Latest'

var appPlanName = 'plan-${uniqueString(resourceGroup().id)}'
var appName = 'app-sonarqube-${uniqueString(resourceGroup().id)}'
var sqlServerName = 'sql-${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'sqldb-sonarqube'

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

resource appServicePlan 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appPlanName
  location: location
  tags: {
    displayName: 'App Service Plan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

resource webApplication 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/appServicePlan': 'Resource'
    displayName: 'SonarQube web app'
  }
  properties: {
    clientAffinityEnabled: false
    serverFarmId: appServicePlan.id
    siteConfig: {
      javaVersion: '11'
      javaContainer: 'TOMCAT'
      javaContainerVersion: '9.0'
      appSettings: [
        {
          name: 'SONARQUBE_JDBC_URL'
          value: 'jdbc:sqlserver://${sqlServer.properties.fullyQualifiedDomainName}:1433;database=${sqlDatabase.name};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;'
        }
        {
          name: 'SONARQUBE_JDBC_USERNAME'
          value: adminSqlUsername
        }
        {
          name: 'SONARQUBE_JDBC_PASSWORD'
          value: adminSqlPassword
        }
        {
          name: 'SonarQubeEdition'
          value: sonarQubeEdition
        }
        {
          name: 'SonarQubeVersion'
          value: sonarQubeVersion
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'Deployment_Telemetry_Instrumentation_Key'
          value: appInsights.properties.InstrumentationKey
        }
      ]
    }
  }
  resource sourceControl 'sourcecontrols@2022-03-01' = {
    name: 'web'
    properties: {
      repoUrl: githubRepo
      branch: 'main'
      isManualIntegration: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'insights-${appName}'
  location: location
  tags: {
    displayName: 'AppInsightsComponent'
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
