::Since <section name="anonymousAuthentication" overrideModeDefault="Allow" /> in C:\Windows\System32\inetsrv\config\applicationHost.config of default IIS installation could not be overriden by default - I will do this by separate cmd file.
set appcmdpath=%windir%\System32\inetsrv
set siteName=%1

%appcmdpath%\appcmd.exe set config "%siteName%/App_Config" -section:system.webServer/security/authentication/anonymousAuthentication /enabled:"False" /commit:apphost
%appcmdpath%\appcmd.exe set config "%siteName%/sitecore/admin" -section:system.webServer/security/authentication/anonymousAuthentication /enabled:"False" /commit:apphost
%appcmdpath%\appcmd.exe set config "%siteName%/sitecore/debug" -section:system.webServer/security/authentication/anonymousAuthentication /enabled:"False" /commit:apphost
%appcmdpath%\appcmd.exe set config "%siteName%/sitecore/shell/WebService" -section:system.webServer/security/authentication/anonymousAuthentication /enabled:"False" /commit:apphost