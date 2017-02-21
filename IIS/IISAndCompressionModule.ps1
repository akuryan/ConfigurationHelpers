Import-Module ServerManager
$IIS = Get-Service W3SVC
if (!$IIS) { 
		Install-WindowsFeature Web-Server
		Install-WindowsFeature -Name Web-Mgmt-Tools
	}
Install-WindowsFeature Web-Dyn-Compression, Web-Stat-Compression