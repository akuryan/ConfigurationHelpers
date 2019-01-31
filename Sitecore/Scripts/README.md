# Helper scripts for Sitecore

## Client certificate generation

I used following ```Generate-Signing-Cert.ps1``` to generate and export certificates for XConnect. While Sitecore recommends to use fully trusted certificates, I do agree with [this blog post](https://getfishtank.ca/blog/sitecore-9-xconnect-client-and-ssl-certificates-explained) that we can easily use self-signed certificates for XConnect, as XConnect services only match certificate with it's thumbprint.

To restore client certificate from base64 string - I use following ```Restore-Cert.ps1```