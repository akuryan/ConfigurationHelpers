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
 
 function InstallWebDeploy(){
	# I am still pretty lame, so I will just download WebDeploy and start it. It is up to a guy, who is workign on server to configure it
	$wc = New-Object System.Net.WebClient  
	$dest = "webdeploy.msi"  
	if (Is64Bit){  
	   $url = "http://go.microsoft.com/fwlink/?LinkID=309497"  
	} else{  
	   $url = "http://go.microsoft.com/fwlink/?LinkID=309495"       
	}  
	$wc.DownloadFile($url, $dest)  
	msiexec.exe /i webdeploy.msi
}
 
 if (!(Test-Path "$env:programfiles\Reference Assemblies\Microsoft\IIS\Microsoft.Web.Iis.Rewrite.dll")){  
      InstallIISRewriteModule  
 } else  
 {  
      Write-Host "IIS Rewrite Module - Already Installed..." -ForegroundColor Green  
 }  
 
InstallWebDeploy