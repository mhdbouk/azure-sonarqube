# SonarQube Azure Docker Deployment

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmhdbouk%2Fazure-sonarqube%2Fmain%2Fdeployment%2Fsonarqube-docker.json)


This repository contains a [Bicep](https://github.com/Azure/bicep) file for deploying a fully configured instance of [SonarQube](https://www.sonarqube.org/) on Azure using Docker.

## Prerequisites

Before deploying this solution, you will need the following:

- An Azure subscription
- The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) installed and configured on your local machine
- The [Bicep CLI](https://github.com/Azure/bicep#installing) installed on your local machine

## Deployment

To deploy this solution, you can use the "Deploy to Azure" button or follow these manual steps

1. Clone this repository to your local machine
2. Navigate to the directory containing the `sonarqube-docker.bicep` file
3. Run the following command to create a new resource group and deploy the resources:

```bash
bicep build sonarqube-docker.bicep
az deployment create --template-file sonarqube-docker.json --parameters @sonarqube-docker.parameters.json --resource-group <resource_group_name>
```

Replace `<resource_group_name>` with the desired name for your resource group. The `sonarqube-docker.parameters.json` file contains the required parameters for the deployment.

## Configuration

The web app is configured to run the latest image of SonarQube from Docker Hub, with all necessary configuration options. An additional app setting `SONAR_SEARCH_JAVAADDITIONALOPTS` with the value `-Dnode.store.allow_mmap=false` has been added to allow the web app to run the latest version of SonarQube on Azure. This is necessary because recent versions of SonarQube (7.8 and above) include ElasticSearch, which requires `vm.max_map_count = 262144` to be set on the host in order to start. However, this is not something that can be set on Azure App Service for Linux Containers, so adding this app setting allows the web app to run the latest version of SonarQube without breaking.

The SQL server and database are also configured and linked to the web app. Additionally, the app setting `WEBSITES_CONTAINER_START_TIME_LIMIT=400` has been added to allow the container sufficient time to create all necessary database tables and objects.

## Modules

This solution uses Bicep modules to create the necessary resources for deploying SonarQube. The following modules are included:

- `linux-plan.bicep`: This module creates an Azure App Service Plan with a Linux operating system. It includes the necessary output for the web app resource.
- `sqlserver.bicep`: This module creates an Azure SQL Server and an Azure SQL database. It includes the necessary output for the web app resource, including the full qualified domain name of the SQL server.

## Usage

Once the deployment has completed, you can access your instance of SonarQube at the URL of the web app. You can find the URL in the Azure portal under the "Overview" section of the web app resource.

## Contributing

We welcome contributions to this repository. If you have any suggestions or improvements, please feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.