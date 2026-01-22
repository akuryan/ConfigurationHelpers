# Usage prepare-scwpd.ps1

Based on [script](https://github.com/robhabraken/Sitecore-Azure-Scripts/blob/master/Scripts/99%20Utility%20Scripts/strip-db.ps1), but do not requires passing separate parameters.xml file, as it could be extracted from scwdp by script

It expects that all ```.scwdp.zip``` files would be grouped in one folder and it will loop over them to create no-databases equivalent packages.

Also, by default, it will remove ```Default.aspx```, ```default.css``` and ```default.js``` that are a OWASP A3 vulnerability (sensitive data exposure). It tells things like “Visual Studio”, “C#” and “sitecore.net”.

# Usage of Generate-SetParameters.ps1

```.\Generate-SetParameters.ps1 -PackagePath "C:\Deploy\Sitecore 10.4.0 rev. 010422 (Cloud)_cm.scwdp.zip"``` - to create setParameters.xml alongside with scwdp file

Check synopsis for additional usage parameters. Same as `prepare-scwpd.ps1` will remove ```Default.aspx```, ```default.css``` and ```default.js``` that are a OWASP A3 vulnerability (sensitive data exposure).

## Requirements 

Your machine have to have .NET 4.5 installed.
