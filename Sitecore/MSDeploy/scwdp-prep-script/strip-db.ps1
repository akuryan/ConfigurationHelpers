[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$PackagePath,

  [Parameter(Mandatory=$False)]
  [string]$PackageDestinationPath = $($PackagePath).Replace(".scwdp.zip", "-nodb.scwdp.zip")
)

$msdeploy = "C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe"
$verb = "-verb:sync"
$source = "-source:package=`"$PackagePath`""
$destination = "-dest:package=`"$($PackageDestinationPath)`""
$declareParamFile = "-declareparamfile=`"$($ParamFile)`""
$skipDbFullSQL = "-skip:objectName=dbFullSql"
$skipDbDacFx = "-skip:objectName=dbDacFx"
$paramFileName = "parameters.xml"

$ParamFile = $env:TEMP + "\" + $paramFileName
Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($PackagePath)
$zip.Entries | where {$_.Name -eq $paramFileName} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $ParamFile, $true)}
$zip.Dispose()

if(![System.IO.File]::Exists($ParamFile)){
  # file with path $path doesn't exist
  Write-Host "Could not find parameters file at $ParamFile"
  exit 1
}


# read parameter file
[xml]$paramfile_content = Get-Content -Path $ParamFile
$paramfile_paramnames = $paramfile_content.parameters.parameter.name
$params = ""
foreach($paramname in $paramfile_paramnames){
   $tmpvalue = "tmpvalue"
   if($paramname -eq "License Xml"){ $tmpvalue = "LicenseContent"}
   if($paramname -eq "IP Security Client IP"){ $tmpvalue = "0.0.0.0"}
   if($paramname -eq "IP Security Client IP Mask"){ $tmpvalue = "0.0.0.0"}
   $params = "$params -setParam:`"$paramname`"=`"$tmpvalue`""
}

# create new package
Invoke-Expression "& '$msdeploy' --% $verb $source $destination $declareParamFile $skipDbFullSQL $skipDbDacFx $params"