REM Checks and installs IIS on server and adds static and dynamic compression modules
@powershell -NoProfile -ExecutionPolicy unrestricted %~dp0\InitialInstallation.ps1
@powershell -NoProfile -ExecutionPolicy unrestricted %~dp0\IISAndCompressionModule.ps1
REM Setting application pools default
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.applicationHost/applicationPools /applicationPoolDefaults.processModel.idleTimeout:0.00:00:00 /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config  -section:system.applicationHost/applicationPools /applicationPoolDefaults.recycling.periodicRestart.time:"00:00:00"  /commit:apphost
:: Setting up periodic restart time NOT needed
REM SET /A hours=%RANDOM% * 5 / 32768 + 1
REM SET /A minutes=%RANDOM% * 60 / 32768 + 1
REM %windir%\System32\Inetsrv\Appcmd.exe set config  -section:system.applicationHost/applicationPools /+"applicationPoolDefaults.recycling.periodicRestart.schedule.[value='%hours%:%minutes%:00']" /commit:apphost
REM Enable IIS compression
%windir%\System32\Inetsrv\Appcmd.exe unlock config /section:system.webserver/httpCompression /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:httpCompression -[name='gzip'].staticCompressionLevel:9 -[name='gzip'].dynamicCompressionLevel:4 /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:httpCompression -dynamicCompressionDisableCpuUsage:70 /commit:apphost
REM Static types
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/msword',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/vnd.ms-powerpoint',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/vnd.ms-excel',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/x-javascript',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/x-javascript;charset=utf-8',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/xml',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/rss+xml',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/json',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/vnd.ms-fontobject',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='application/x-font-ttf',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='text/*',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='text/*;charset=utf-8',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='image/svg+xml',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"staticTypes.[mimeType='font/opentype',enabled='True']" /commit:apphost
REM Dynamic types
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='text/*',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='text/*;charset=utf-8',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='message/*',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/x-javascript',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/x-javascript;charset=utf-8',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/atom+xml',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/atom+xml;charset=utf-8',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/xaml+xml',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/xml',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/json',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/json;charset=utf-8',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='application/rss+xml',enabled='True']" /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:system.webServer/httpCompression /+"dynamicTypes.[mimeType='*/*',enabled='False']" /commit:apphost
REM FrequentHit changing
%windir%\system32\inetsrv\Appcmd.exe set config -section:system.webServer/serverRuntime -frequentHitThreshold:1 /commit:apphost
REM Allowing compression for HTTP 1.0 and Proxies (as, for example, CloudFront using Http 1.0 for requests)
%windir%\System32\Inetsrv\Appcmd.exe set config -section:httpCompression -noCompressionForHttp10:False /commit:apphost
%windir%\System32\Inetsrv\Appcmd.exe set config -section:httpCompression -noCompressionForProxies:False /commit:apphost
REM Add content expiration headers for 14 days
%windir%\System32\Inetsrv\Appcmd.exe set config /section:staticContent /clientCache.cacheControlMode:UseMaxAge /clientCache.cacheControlMaxAge:14.00:00:00
REM Disable content expiration
REM %windir%\System32\Inetsrv\Appcmd.exe set config /section:staticContent /clientCache.cacheControlMode:DisableCache

REM TODO: Add scheduling for CleanupScript

REM Register .NET 2.0 and .NET 4.0
C:\Windows\Microsoft.NET\Framework64\v2.0.50727\aspnet_regiis.exe -iru
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -iru

REM Install choco
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
REM Install notepad++
choco install notepadplusplus webpi webpicmd git -y --allow-empty-checksums
webpicmd /Install /Products:UrlRewrite2,WDeploy36PS /AcceptEULA
REM You can search webpicmd in powershell for required ' webpicmd /List /ListOption:All | select-string -pattern "rewrite" '

REM choco list --source webpi -- can be used to locate required packages in future, as soon as webpi source will be implemented (described at https://github.com/chocolatey/choco/wiki/CommandsList)
REM choco webpi UrlRewrite2 - sources is not yet implemented, so UrlRewrite2 and Web Deploy 3.6 for Hosting servers have to be installed manually
REM Add firewall configuration rules

REM WmSvc should have write access on C:\Windows\System32\inetsrv\config\applicationhost.config.
icacls %windir%\System32\inetsrv\config\applicationhost.config /grant "NT SERVICE\WMSvc":W
REM WDeployConfigWriter and WDeployAdmin windows users should have 'Password never expires' checkboxes checked, as stated here http://blogs.technet.com/b/bernhard_frank/archive/2011/11/03/webmatrix-check-compatibility-shows-exclamation-mark-and-states-asp-net-version-not-available.aspx
wmic path Win32_UserAccount where Name='WDeployAdmin' set PasswordExpires=false
wmic path Win32_UserAccount where Name='WDeployConfigWriter' set PasswordExpires=false

REM Adding compression to logs folder
compact /c /s /a /i /f /q C:\inetpub\logs\

REM Set updates to be only downloaded; should be installed manually
net stop wuauserv
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 3 /f
net start wuauserv

::Set perfect forward secrecy
@powershell -NoProfile -ExecutionPolicy unrestricted %~dp0\PerfectSecrecy.ps1
::Generate password for deployment_user if not defined
echo off
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 ECHO Unable to enable extensions
::If there is some string set as first parameter - it will be set as password
IF [%1]==[] (for /f "usebackq" %%x in (`powershell -NoProfile -ExecutionPolicy unrestricted %~dp0\GeneratePw.ps1`) do set userPwd=%%x) ELSE (set userPwd=%1)
::Create deployment user
NET USER deployment_user "%userPwd%" /fullname:"MsDeploy deployment user" /ADD /Y
wmic path Win32_UserAccount where Name='deployment_user' set PasswordExpires=false
wmic useraccount where "name='deployment_user'" set passwordchangeable=false
echo on
::Show password
echo off
echo Deployment user password:
echo "%userPwd%"
echo on
REM TODO: Configure deployment for unplrivileged user 
REM http://www.iis.net/learn/publish/using-web-deploy/powershell-scripts-for-automating-web-deploy-setup
REM http://www.iis.net/learn/publish/using-web-deploy/web-deploy-powershell-cmdlets
REM Of by script c:\Program Files\IIS\Microsoft Web Deploy V3\Scripts\SetupSiteForPublish.ps1
echo Please, reboot computer after configuration finished
pause
