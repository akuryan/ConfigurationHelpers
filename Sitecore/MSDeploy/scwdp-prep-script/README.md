# Usage

Based on [script](https://github.com/robhabraken/Sitecore-Azure-Scripts/blob/master/Scripts/99%20Utility%20Scripts/strip-db.ps1), but do not requires passing separate parameters.xml file, as it could be extracted from scwdp by script

It expects that all ```.scwdp.zip``` files would be grouped in one folder and it will loop over them to create no-databases equivalent packages.