$pfxBytes = [System.Convert]::FromBase64String($base64string)
[io.file]::WriteAllBytes("c:\CertFromSecret.pfx", $pfxBytes)