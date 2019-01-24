[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$PackagesFolder
)


$msdeploy = "C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe"
$verb = "-verb:sync"
$skipDbFullSQL = "-skip:objectName=dbFullSql"
$skipDbDacFx = "-skip:objectName=dbDacFx"
$paramFileName = "parameters.xml"
$scwdpExtension = ".scwdp.zip"

$dirContent = Get-ChildItem $PackagesFolder
foreach ($PackagePath in $dirContent | where {$_.FullName.EndsWith($scwdpExtension)} | % { $_.FullName }) {
  $PackageDestinationPath = $PackagePath.Replace(".scwdp.zip", "-nodb.scwdp.zip")
  $source = "-source:package=`"$PackagePath`""
  $destination = "-dest:package=`"$($PackageDestinationPath)`""
  
  $ParamFile = $env:TEMP + "\" + $paramFileName
  $declareParamFile = "-declareparamfile=`"$($ParamFile)`""
  Add-Type -Assembly System.IO.Compression.FileSystem
  $zip = [IO.Compression.ZipFile]::OpenRead($PackagePath)
  $zip.Entries | where {$_.Name -eq $paramFileName} | foreach {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $ParamFile, $true)}
  $zip.Dispose()
  
  if(![System.IO.File]::Exists($ParamFile)){
    # file with path $path doesn't exist
    Write-Host "Could not find parameters file at $ParamFile"
    continue
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
}
