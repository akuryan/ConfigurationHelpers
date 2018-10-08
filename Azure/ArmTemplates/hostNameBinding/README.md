## Deploy hostname binding

Designed to work as nested template for Sitecore, but could be used for any web app.
Will deploy hostname binding and associate it with certificate, if it is passed in deployment.

### Example

Following example are used to include as nested template in standard Sitecore deployment template (see [this](https://github.com/Sitecore/Sitecore-Azure-Quickstart-Templates/blob/master/Sitecore%209.0.2/XP/azuredeploy.json) as example):

#### Sitecore

Following snippet adds hostname binding with SSL SNI

```json
    "modules": {
      "type": "secureObject",
      "defaultValue": {
        "items": [
          {
            "name": "moduleName",
            "templateLink": "https://raw.githubusercontent.com/akuryan/ConfigurationHelpers/master/Azure/ArmTemplates/hostNameBinding/hostnameBinding.json",
            "parameters": {
              "webAppName" : "[parameters('singleWebAppName')]",
              "hostnameBinding": "hostnameBindingHere",
              "sslThumbprint": "SSL-THUMBPRINT-HERE"
            }
          }
        ]
      }
    }
```

Following snippet adds hostname binding without SSL (pass ```none``` as value for parameter ```sslThumbprint```)

```json
    "modules": {
      "type": "secureObject",
      "defaultValue": {
        "items": [
          {
            "name": "moduleName",
            "templateLink": "https://raw.githubusercontent.com/akuryan/ConfigurationHelpers/master/Azure/ArmTemplates/hostNameBinding/hostnameBinding.json",
            "parameters": {
              "webAppName" : "[parameters('singleWebAppName')]",
              "hostnameBinding": "hostnameBindingHere",
              "sslThumbprint": "none"
            }
          }
        ]
      }
    }
```

#### Adding as nested template

For SSL binding deployment - pass correct certificate thumbprint in parameter ```sslThumbprint```, else - pass ```none``` as a value of parameter ```sslThumbprint``` (see Sitecore example, if you are not sure about what I mean)

```json
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "variables": {
  },
  "parameters": {
	"location": {
		"type": "string",
		"defaultValue": "[resourceGroup().location]"
      },
  },
  "resources": [
    {
      "apiVersion": "2016-02-01",
      "name": "HostnameBinding",
      "type": "Microsoft.Resources/deployments",
      "properties": {
        "mode": "Incremental",
        "templateLink": {
          "uri": "https://raw.githubusercontent.com/akuryan/ConfigurationHelpers/master/Azure/ArmTemplates/hostNameBinding/hostnameBinding.json",
          "contentVersion": "1.0.0.0"
        },
        "parameters": {
			    "extension": { 
				    "value": {
              "webAppName" : "webAppNameHere",
              "hostnameBinding": "hostnameBindingHere",
              "sslThumbprint": "SSL-THUMBPRINT-HERE"
            }
			    }
        }
      }
    }
  ]
}
```