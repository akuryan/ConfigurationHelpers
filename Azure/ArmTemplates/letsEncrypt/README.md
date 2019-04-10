#WIP

Working on Let's Encrypt extension installation as a module for Sitecore. 

## Issues:

1. appSettings are overwritten after module deployment - seems to be an ARM issue

## Usage

Add to ```modules``` section of your template following json:

```json
          {
            "name": "letsEncrypt",
            "templateLink": "_LINK-TO-TEMPLATE-HERE_",
            "parameters": {
              "webAppName": "[parameters('singleWebAppName')]",
              "stagingSlotName": "single-staging",
              "letsEncryptHostnames": "comma-separated-hostnames",
              "letsEncryptEmails": "comma-separated-emails",
              "letsEncryptClientId": "[parameters('service-principle-client-id')]",
              "letsEncryptClientSecret": "[parameters('service-principle-client-secret')]",
              "storageRgName": "storage-account-resourcegroup-name",
              "storageName": "storage-account-name",
              "singleDeployment": "yes-or-no",
              "deployStorageConnectionString": true,
              "nodeJsVersion": "[parameters('nodeJsVersion')]"
            }  
          }
```