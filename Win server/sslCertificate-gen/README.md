# Content

Scripts for generating self-signed trusted locally certificates.

```generate-cert.ps1``` is inspired by Sitecore Installation Framework, https://gist.github.com/Jaykul/b6c366c0e580f6350e0aaef55036903c , https://infiniteloop.io/powershell-self-signed-certificate-via-self-signed-root-ca/ , https://gist.github.com/Jaykul/b6c366c0e580f6350e0aaef55036903c , http://dotnetcodetips.com/Tip/90/Create-a-self-signed-certificate-with-PowerShell-New-SelfSignedCertificate-or-Makecertexe , https://vcsjones.com/2013/11/08/making-a-self-signed-ssl-certificate-and-trusting-it-in-powershell/ , http://www.mikeobrien.net/blog/creating-self-signed-wildcard

Feel free to send me Pull Requests to update my work.

## Usage

Execute in Administrator powershell console, as it requires to create a trusted signing certificate at local machine store.

```powershell
.\generate-cert.ps1 -dnsNames "*.dev.local,test.local,user.local,whatever.local"
```

## Explanation

It will create root certificate for signing in ```LocalMachine/My``` with private key, export it and import it without private key to ```LocalMachine/Root```; after it - new certificate will be created and signed by signing certificate. Signing certificate will be stored for further reusage.

## Exporting created certificate for reuse with SOLR

```powershell
$mypwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Get-ChildItem -Path cert:\localMachine\my\ThumbprintOfCertificate | Export-PfxCertificate -FilePath C:\mypfx.pfx -Password $mypwd
```

To convert PFX to JKS (for SOLR) I used [this guide](https://dzone.com/articles/convert-pfx-certificate-to-jks-p12-crt)

```bash
openssl pkcs12 -in C:\mypfx.pfx -nocerts -out c:\mypfx.key
openssl pkcs12 -in C:\mypfx.pfx -clcerts -nokeys -out c:\mypfx.crt  
openssl pkcs12 -export -in c:\mypfx.crt -inkey c:\mypfx.key -certfile c:\mypfx.crt -name "examplecert" -out c:\mypfx.p12
keytool -importkeystore -srckeystore c:\mypfx.p12 -srcstoretype pkcs12 -destkeystore c:\mypfx.jks -deststoretype JKS
```