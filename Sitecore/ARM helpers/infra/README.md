# Content

Template for deploying infrastructure resources to be used with [Sitecore Deployer Azure DevOps extension](https://marketplace.visualstudio.com/items?itemName=anton-kuryan.SitecoreAzureVstsDeployer). It will deploy storage account for storing scwdp packages and keyvault for storing secrets. Also it allows to setup keyvault access and create secrets there as well.

I have not found a way to make it reusable completely, so publishing it as is. You could use https://github.com/Microsoft/azure-pipelines-tasks/blob/master/Tasks/AzureResourceGroupDeploymentV2/README.md to deploy it, while storing personal parameters for template in your own repository.