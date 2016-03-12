This template can be used to provision limited access to your resources via NSG.
Idea is as following - pass 2 arrays with IPs and Names, and port to allow - and template will allow you at to grant access to this port and IPs

Based on suggestion in this issue: https://github.com/Azure/azure-powershell/issues/1817

To use this template - you can add to yours following snippet, which will allow you to provision acceess to ports 22, 80 and 443 for IPs defined in allowedAllCIDRs with desription from allowedAllCIDRsNames, and provision access to ports 80 and 443 to IPs in allowedLimitedCIDRs with desription from allowedLimitedCIDRsNames

```json
{
    "$schema": "http://schema.management.azure.com/schemas/2014-04-01-preview/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
		"allowedAllCIDRs": {
			"type": "array",
					"defaultValue":[ 
					"1.1.1.1/32", 
					"2.2.2.2/32",
					"3.3.3.3/24",
					"4.4.4.4/29",
					"5.5.5.5/32",
					]
			},
		"allowedAllCIDRsNames": {
			"type": "array",
					"defaultValue":[ 
					"Test1", 
					"Test2",
					"Test3",
					"Test4",
					"Test5",
					]
			},
		"allowedLimitedCIDRs": {
			"type": "array",
					"defaultValue":[ 
					"1.1.1.1/32", 
					"2.2.2.2/32",
					"3.3.3.3/24",
					"4.4.4.4/29",
					"5.5.5.5/32",
					]
			},
		"allowedLimitedCIDRsNames": {
			"type": "array",
					"defaultValue":[ 
					"LimitedTest1", 
					"LimitedTest2",
					"LimitedTest3",
					"LimitedTest4",
					"LimitedTest5",
					]
			},		
    },
    "variables": {
        "location": "[resourceGroup().location]",
		"apiVersionString": "2015-06-15",	
    },	
  "resources": [
	{
		"apiVersion": "[variables('apiVersionString')]",
		"type": "Microsoft.Network/networkSecurityGroups",
		"name": "[parameters('networkSecurityGroupName')]",
		"location": "[resourceGroup().location]",
		"properties": {
			"securityRules": [
				{
					"name": "Static rule 1",
					"properties": {
						"description": "Allow everything from somewhere",
						"protocol": "*",
						"sourcePortRange": "*",
						"destinationPortRange": "*",
						"sourceAddressPrefix": "10.0.0.0/24",
						"destinationAddressPrefix": "*",
						"access": "Allow",
						"priority": 4095,
						"direction": "Inbound"
					}
				}
			],
		}
	},
	{ 
	 "apiVersion": "2016-02-01",
	 "name": "provisionAccessToPort22", 
	 "type": "Microsoft.Resources/deployments", 
	"dependsOn": [
		"[concat('Microsoft.Network/networkSecurityGroups/', parameters('networkSecurityGroupName'))]"
	],	 
	 "properties": { 
	   "mode": "incremental", 
	   "templateLink": {
		  "uri": "https://raw.githubusercontent.com/akuryan/ConfigurationHelpers/master/Azure/ArmTemplates/nsg-provisioning.json",
		  "contentVersion": "1.0.0.0"
	   }, 
	   "parameters": { 
		  "networkSecurityGroupName":{"value": "[parameters('networkSecurityGroupName')]"},
		  "allowedCIDRs":{"value": "[parameters('allowedAllCIDRs')]"},
		  "allowedCIDRsNames":{"value": "[parameters('allowedAllCIDRsNames')]"},
		  "startingPriorityIndexMinusOne":{"value": "100"},
		  "startingPriorityIndex":{"value": "101"},
		  "portToAllow":{"value": "22"},
	   } 
	 } 
	},
	{ 
	 "apiVersion": "2016-02-01",
	 "name": "provisionAccessToPort80", 
	 "type": "Microsoft.Resources/deployments", 
	"dependsOn": [
		"[concat('Microsoft.Network/networkSecurityGroups/', parameters('networkSecurityGroupName'))]",
		"Microsoft.Resources/deployments/provisionAccessToPort22"
	],	 
	 "properties": { 
	   "mode": "incremental", 
	   "templateLink": {
		  "uri": "https://raw.githubusercontent.com/akuryan/ConfigurationHelpers/master/Azure/ArmTemplates/nsg-provisioning.json",
		  "contentVersion": "1.0.0.0"
	   }, 
	   "parameters": { 
		  "networkSecurityGroupName":{"value": "[parameters('networkSecurityGroupName')]"},
		  "allowedCIDRs":{"value": "[parameters('allowedAllCIDRs')]"},
		  "allowedCIDRsNames":{"value": "[parameters('allowedAllCIDRsNames')]"},
		  "startingPriorityIndexMinusOne":{"value": "200"},
		  "startingPriorityIndex":{"value": "201"},
		  "portToAllow":{"value": "80"},	  
	   } 
	 } 
	},
	{ 
	 "apiVersion": "2016-02-01",
	 "name": "provisionAccessToPort443", 
	 "type": "Microsoft.Resources/deployments", 
	"dependsOn": [
		"[concat('Microsoft.Network/networkSecurityGroups/', parameters('networkSecurityGroupName'))]",
		"Microsoft.Resources/deployments/provisionAccessToPort80"
	],
	 "properties": { 
	   "mode": "incremental", 
	   "templateLink": {
		  "uri": "https://raw.githubusercontent.com/akuryan/ConfigurationHelpers/master/Azure/ArmTemplates/nsg-provisioning.json",
		  "contentVersion": "1.0.0.0"
	   }, 
	   "parameters": { 
		  "networkSecurityGroupName":{"value": "[parameters('networkSecurityGroupName')]"},
		  "allowedCIDRs":{"value": "[parameters('allowedAllCIDRs')]"},
		  "allowedCIDRsNames":{"value": "[parameters('allowedAllCIDRsNames')]"},
		  "startingPriorityIndexMinusOne":{"value": "300"},
		  "startingPriorityIndex":{"value": "301"},
		  "portToAllow":{"value": "443"},
	   } 
	 } 
	},
	{ 
	 "apiVersion": "2016-02-01",
	 "name": "provisionLimitedAccessToPort80", 
	 "type": "Microsoft.Resources/deployments", 
	"dependsOn": [
		"[concat('Microsoft.Network/networkSecurityGroups/', parameters('networkSecurityGroupName'))]",
		"Microsoft.Resources/deployments/provisionAccessToPort3389"
	],
	 "properties": { 
	   "mode": "incremental", 
	   "templateLink": {
		  "uri": "https://raw.githubusercontent.com/akuryan/ConfigurationHelpers/master/Azure/ArmTemplates/nsg-provisioning.json",
		  "contentVersion": "1.0.0.0"
	   }, 
	   "parameters": { 
		  "networkSecurityGroupName":{"value": "[parameters('networkSecurityGroupName')]"},
		  "allowedCIDRs":{"value": "[parameters('allowedLimitedCIDRs')]"},
		  "allowedCIDRsNames":{"value": "[parameters('allowedLimitedCIDRsNames')]"},
		  "startingPriorityIndexMinusOne":{"value": "400"},
		  "startingPriorityIndex":{"value": "401"},
		  "portToAllow":{"value": "80"},
	   } 
	 } 
	},
	{ 
	 "apiVersion": "2016-02-01",
	 "name": "provisionLimitedAccessToPort443", 
	 "type": "Microsoft.Resources/deployments", 
	"dependsOn": [
		"[concat('Microsoft.Network/networkSecurityGroups/', parameters('networkSecurityGroupName'))]",
		"Microsoft.Resources/deployments/provisionLimitedAccessToPort80"
	],
	 "properties": { 
	   "mode": "incremental", 
	   "templateLink": {
		  "uri": "https://raw.githubusercontent.com/akuryan/ConfigurationHelpers/master/Azure/ArmTemplates/nsg-provisioning.json",
		  "contentVersion": "1.0.0.0"
	   }, 
	   "parameters": { 
		  "networkSecurityGroupName":{"value": "[parameters('networkSecurityGroupName')]"},
		  "allowedCIDRs":{"value": "[parameters('allowedLimitedCIDRs')]"},
		  "allowedCIDRsNames":{"value": "[parameters('allowedLimitedCIDRsNames')]"},
		  "startingPriorityIndexMinusOne":{"value": "500"},
		  "startingPriorityIndex":{"value": "501"},
		  "portToAllow":{"value": "443"},
	   } 
	 } 
	},	
 ]
}
```

