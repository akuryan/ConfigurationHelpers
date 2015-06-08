# PowerShell command to set a reserved IP address for Cloud Service in Azure
# Reference:
# Reserved IP addresses: http://msdn.microsoft.com/en-us/library/azure/dn690120.aspx
# Courtesy and explanation - https://systemcenterpoint.wordpress.com/2014/10/17/assigning-a-public-reserved-ip-to-existing-azure-cloud-service/

# Log on to my Azure account
Add-AzureAccount

# Set active subscription
Get-AzureSubscription -SubscriptionName "mysubscriptionname" | Select-AzureSubscription

# Create a Public Reserved IP for SQL AlwaysOn Listener IP
$ReservedIP = New-AzureReservedIP -ReservedIPName "SCSQLAlwaysOnListenerIP" -Label "SCSQLAlwaysOnListenerIP" -Location "West Europe"
#Create a Public Reserved IP for standalone machine
$ReservedIP2 = New-AzureReservedIP -ReservedIPName "SCSQLAlwaysOnListenerIP2" -Label "SCSQLAlwaysOnListenerIP2" -Location "West Europe"

$workingDir = (Get-Location).Path

# Define VMs and Cloud Service
$vmNames = 'az-scsql02', 'az-scsql01', 'az-scsqlquorum'
$serviceName = "mycloudsvc-az-scsql"

# Export VM Config and Stop VM
ForEach ($vmName in $vmNames) {

    $Vm = Get-AzureVM –ServiceName $serviceName –Name $vmName
    $vmConfigurationPath = $workingDir + "\exportedVM_" + $vmName +".xml"
    $Vm | Export-AzureVM -Path $vmConfigurationPath

    Stop-AzureVM –ServiceName $serviceName –Name $vmName -Force

}

# Remove VMs while keeping disks
ForEach ($vmName in $vmNames) {

    $Vm = Get-AzureVM –ServiceName $serviceName –Name $vmName
    $vm | Remove-AzureVM -Verbose

}

# Specify VNet for the VMs
$vnetname = "myvnet-prod"

# Re-create VMs in specified order
$vmNames = 'az-scsqlquorum', 'az-scsql01', 'az-scsql02'
Set-AzureSubscription -SubscriptionName "mysubscriptionname" -CurrentStorageAccountname "mystorageaccountname"
ForEach ($vmName in $vmNames) {

    $vmConfigurationPath = $workingDir + "\exportedVM_" + $vmName +".xml"
    $vmConfig = Import-AzureVM -Path $vmConfigurationPath

    New-AzureVM -ServiceName $serviceName -VMs $vmConfig -VNetName $vnetname -ReservedIPName $ReservedIP.ReservedIPName -WaitForBoot:$false

}

#Assign static IP to Standalone machine
Get-AzureVM -ServiceName $serviceName -Name az-scsqlquorum | Set-AzurePublicIP -PublicIPName SCSQLAlwaysOnListenerIP2 | Update-AzureVM