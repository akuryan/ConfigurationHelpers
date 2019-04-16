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