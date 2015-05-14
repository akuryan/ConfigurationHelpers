Import-Module ServerManager
$IIS = Get-Service W3SVC
if (!$IIS) { Add-WindowsFeature Web-Server }
Add-WindowsFeature Web-Dyn-Compression, Web-Stat-Compression