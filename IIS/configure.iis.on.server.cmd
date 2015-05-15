REM Checks and installs IIS on server and adds static and dynamic compression modules
@powershell -NoProfile -ExecutionPolicy unrestricted %~dp0\IISAndCompressionModule.ps1
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

REM Install IIS UrlRewrite 2 module
@powershell -NoProfile -ExecutionPolicy unrestricted %~dp0\UrlRewrite.ps1