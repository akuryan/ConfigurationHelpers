Import-Module ServerManager -Force;
#.NET 3.5
Add-WindowsFeature NET-Framework-Core 
#Credits of next going code is http://www.tugberkugurlu.com/archive/script-out-everything-initialize-your-windows-azure-vm-for-your-web-server-with-iis-web-deploy-and-other-stuff

#add additional windows features
$additionalFeatures = @('Web-Mgmt-Service', 'Web-Asp-Net45', 'Web-Dyn-Compression', 'Web-Scripting-Tools', 'Web-Http-Errors', 'Web-Static-Content', 'Web-Http-Redirect', 'Web-Http-Logging', 'Web-Basic-Auth', 'Web-AppInit', 'Web-Mgmt-Console')
foreach($feature in $additionalFeatures) { 
    
    if(!(Get-WindowsFeature | where { $_.Name -eq $feature }).Installed) { 

        Add-WindowsFeature -Name $feature -LogPath "$env:TEMP\init-webservervm_feature_$($feature)_install_log_$((get-date).ToString("yyyyMMddHHmmss")).txt"   
    }
}
#Set WMSvc to Automatic Startup
Set-Service -Name WMSvc -StartupType Automatic

#Check if WMSvc (Web Management Service) is running
if((Get-Service WMSvc).Status -ne 'Running') { 
    Start-Service WMSvc
}