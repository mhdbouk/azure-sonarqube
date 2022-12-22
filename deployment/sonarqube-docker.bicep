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

@description('Default is latest, change it to use a specific version https://hub.docker.com/_/sonarqube')
param sonarQubeVersion string = 'latest'

var appPlanName = 'plan-${uniqueString(resourceGroup().id)}'
var appName = 'app-sonarqube-${uniqueString(resourceGroup().id)}'
var sqlServerName = 'sql-${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'sqldb-sonarqube'

module sqlserver 'core/sqlserver.bicep' = {
  name: 'sqlserver-module'
  params: {
    adminSqlPassword:  adminSqlPassword
    adminSqlUsername: adminSqlUsername
    location: location
    sqlDatabaseName: sqlDatabaseName
    sqlServerName: sqlServerName
  }
}

module appServicePlan 'core/linux-plan.bicep' = {
  name: 'app-service-plan'
  params: {
    appPlanName: appPlanName
    location: location
    skuCapacity: skuCapacity
    skuName: skuName
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
    serverFarmId: appServicePlan.outputs.Id
    siteConfig: {
      linuxFxVersion: 'DOCKER|sonarqube:${sonarQubeVersion}'
      appSettings: [
        {
          name: 'SONARQUBE_JDBC_URL'
          value: 'jdbc:sqlserver://${sqlserver.outputs.fullyQualifiedDomainName}:1433;database=${sqlDatabaseName};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;'
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
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: ''
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: ''
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io'
        }
        {
          name: 'SONAR_SEARCH_JAVAADDITIONALOPTS'
          value: '-Dnode.store.allow_mmap=false'
        }
        {
          name: 'WEBSITES_CONTAINER_START_TIME_LIMIT'
          value: '400'
        }
        {
          name: 'WEBSITES_PORT'
          value: '9000'
        }
      ]
    }
  }
}
