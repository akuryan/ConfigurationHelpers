# Log on to my Azure account
Add-AzureAccount

# Set active subscription
Get-AzureSubscription -SubscriptionName "mysubscriptionname" | Select-AzureSubscription
$acl1 = New-AzureAclConfig
$ip1 = '1.1.1.1/32'
$subnet1 = '10.0.0.0/24'
Set-AzureAclConfig -AddRule -ACL $acl1 -Order 100 -Action permit -RemoteSubnet $ip1 -Description "Some IP"
Set-AzureAclConfig -AddRule -ACL $acl1 -Order 200 -Action permit -RemoteSubnet $subnet1 -Description "Some subnet"
Set-AzureAclConfig -AddRule -ACL $acl1 -Order 300 -Action Deny -RemoteSubnet "0.0.0.0/0" -Description "Everything else"

$serviceName = "MyServiceName"
$vm = "MyVMName"

Get-AzureVM -ServiceName $serviceName -Name $vm | Add-AzureEndpoint -Name "someName" -Protocol "tcp" -PublicPort 80 -LocalPort 8080 -ACL $acl1 | Update-AzureVM