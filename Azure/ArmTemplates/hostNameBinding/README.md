## Deploy hostname binding

Designed to work as nested template for Sitecore, but could be used for any web app.
Will deploy hostname binding and associate it with certificate, if it is passed in deployment.

### Example

Following example are used to include as nested template in standard Sitecore deployment template (see [this](https://github.com/Sitecore/Sitecore-Azure-Quickstart-Templates/blob/master/Sitecore%209.0.2/XP/azuredeploy.json) as example):


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

Following snippet adds hostname binding without SSL

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
              "hostnameBinding": "hostnameBindingHere"
            }
          }
        ]
      }
    }
```

Eventually, when I will add this one as nested template to other web app (non-Sitecore) ARM template - I will add example for it as well.