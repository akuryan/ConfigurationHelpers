$rgName = "youResourceGroupNameHere";
$xcName = $rgName + "-xconnect"
#create self-signed certificate
$thumbprint = (New-SelfSignedCertificate -CertStoreLocation cert:\LocalMachine\My -Subject $xcName -FriendlyName $xcName -KeyExportPolicy Exportable -KeyProtection None -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter (Get-Date).AddYears(10)).Thumbprint
#generate password
$Assembly = Add-Type -AssemblyName System.Web
$Password = "pfxPwd" + [system.web.security.membership]::GeneratePassword(10,1)
$mypwd = ConvertTo-SecureString -String $Password -Force -AsPlainText
#generate temp file path
$tmpPfxFile = New-TemporaryFile
#export certificate
Export-PfxCertificate -cert cert:\LocalMachine\My\$thumbprint -FilePath $tmpPfxFile.FullName -Password $mypwd
#remove certificate from store (you could keep it for future reuse, but could be that you do not want to do this)
Get-ChildItem Cert:\LocalMachine\My\$thumbprint | Remove-Item
#get base64 string from pfx
$fileContentBytes = get-content $tmpPfxFile.FullName -Encoding Byte
[System.Convert]::ToBase64String($fileContentBytes) | Write-Host
#echo password for future use
Write-Host "PFX password: $Password"
#remove pfx file
Remove-Item $tmpPfxFile.FullName -Force