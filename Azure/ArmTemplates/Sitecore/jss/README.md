# Purpose

This templates could be included as extension templates in your Sitecore installation, when you intend to install JSS on web app and install headless JSS application on separate Azure Web app driven by Windows. It expects that your web apps are using staging slots and will deploy host for a headless jss web application on Azure web app with staging slots as well.

## Usage

### XP0

Append to your template modules followind JSON:

```json
    "modules": {
      "type": "secureObject",
      "defaultValue": {
        "items": [
          {
            "name" : "jss-single",
            "templateLink": "[parameters('jssAddonTemplatePath')]",
            "parameters" : {
              "msDeployPackageUrl": "[parameters('jssMsDeployPackageUrl')]",
              "webAppSlotName": "single-staging",
              "webAppName": "[parameters('singleWebAppName')]"
            }
          },
          {
            "name" : "jss-headless-web-app",
            "templateLink": "[parameters('jssWebApp')]",
            "parameters" : {
              "hostingPlanSkuName": "[parameters('headlessHostingPlanSkuName')]",
              "hostingPlanSkuCapacity": "[parameters('headlessHostingPlanCapacity')]",
              "http20State": "[parameters('http20State')]",
              "minimalTlsVersion": "[parameters('minimalTlsVersion')]",
              "nodeJsVersion": "[parameters('nodeJsVersion')]",
              "cdWebAppName": "[parameters('singleWebAppName')]",
              "cdWebAppSlotName": "single-staging"
            }
          }
        ]
      }
    }
```

### XP

```json
    "modules": {
      "type": "secureObject",
      "defaultValue": {
        "items": [
          {
            "name" : "jss-cm",
            "templateLink": "[parameters('jssAddonTemplatePath')]",
            "parameters" : {
              "msDeployPackageUrl": "[parameters('jssMsDeployPackageUrl')]",
              "webAppSlotName": "cm-staging",
              "webAppName": "[parameters('cmWebAppName')]"
            }
          },
          {
            "name" : "jss-cd",
            "templateLink": "[parameters('jssCdAddonTemplatePath')]",
            "parameters" : {
              "msDeployPackageUrl": "[parameters('jssNoDbMsDeployPackageUrl')]",
              "webAppSlotName": "cd-staging",
              "webAppName": "[parameters('cdWebAppName')]"
            }
          },
          {
            "name" : "jss-headless-web-app",
            "templateLink": "[parameters('jssWebApp')]",
            "parameters" : {
              "hostingPlanSkuName": "[parameters('headlessHostingPlanSkuName')]",
              "hostingPlanSkuCapacity": "[parameters('headlessHostingPlanCapacity')]",
              "http20State": "[parameters('http20State')]",
              "minimalTlsVersion": "[parameters('minimalTlsVersion')]",
              "nodeJsVersion": "[parameters('cdNodeJsVersion')]",
              "cdWebAppName": "[parameters('cdWebAppName')]",
              "cdWebAppSlotName": "cd-staging"
            }
          }
        ]
      }
    }
```

### Parameters explanation

and you'll need some parameters as well

```jssAddonTemplatePath``` - string var, shall be different, depending on whether you are deploying for a first time (e.g. you'll need database changes to be introduced) or this is subsequent deployment (so you need to deploy CD JSS package)

```jssCdAddonTemplatePath``` - string var, URL to no-db template (used for CD deployment)

```jssCdAddonTemplatePath``` - 

```jssMsDeployPackageUrl``` - string var, URL to SCWDP; first-time deployments use regular JSS package, subsequent one's - use CD JSS package

```headlessHostingPlanSkuName``` - string var, which SKU should be used for headless JSS web app; P1v2 is safest bet, which gives plenty of resources and do not cost too much. Default value is P1v2

```hostingPlanSkuCapacity``` - int var, how much workers shall be for JSS headless web app. 1 is OK starting point and is default

```http20State``` - boolean var, defines if HTTP/2 shall be enabled; defaults to true

```minimalTlsVersion```- string var, defines which minimal TLS version shall be used; default value is 1.2

```nodeJsVersion``` - string var, defines which Node.JS version shall be used by web app; defaults to Sitecore defaults