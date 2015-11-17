 function Is64Bit  
 {  
      [IntPtr]::Size -eq 8  
 }  
 function InstallIISRewriteModule(){  
      $wc = New-Object System.Net.WebClient  
      $dest = "IISRewrite.msi"  
      $url  
      if (Is64Bit){  
           $url = "http://go.microsoft.com/?linkid=9722532"  
      } else{  
           $url = "http://go.microsoft.com/?linkid=9722533"       
      }  
      $wc.DownloadFile($url, $dest)  
      msiexec.exe /i IISRewrite.msi /passive  
 }  
 
 
 if (!(Test-Path "$env:programfiles\Reference Assemblies\Microsoft\IIS\Microsoft.Web.Iis.Rewrite.dll")){  
      InstallIISRewriteModule  
 } else  
 {  
      Write-Host "IIS Rewrite Module - Already Installed..." -ForegroundColor Green  
 }  
 
