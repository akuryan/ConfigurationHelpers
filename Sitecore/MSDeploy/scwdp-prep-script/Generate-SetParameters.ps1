<#
.SYNOPSIS
    Generates setParameters.xml from parameters.xml inside an MSDeploy package
.DESCRIPTION
    This script extracts parameters.xml from an MSDeploy package (.zip) and creates
    a setParameters.xml file with default values for deployment configuration.
.PARAMETER PackagePath
    Path to the MSDeploy package (.zip file)
.PARAMETER OutputPath
    Path where setParameters.xml will be created (optional, defaults to same directory as package)
.PARAMETER IncludeComments
    Include parameter descriptions as comments in the output file
.PARAMETER KeepExtraFiles
    Will keep files Default.aspx, default.css and default.js in package if they exist
.EXAMPLE
    .\Generate-SetParameters.ps1 -PackagePath "C:\Deploy\MyApp.zip"
.EXAMPLE
    .\Generate-SetParameters.ps1 -PackagePath "C:\Deploy\MyApp.zip" -OutputPath "C:\Config\" -IncludeComments
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PackagePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeComments,

    [Parameter(Mandatory = $false)]
    [switch]$KeepExtraFiles
)

# Function to extract and read parameters.xml from the package
function Get-ParametersFromPackage {
    param([string]$PackagePath)
    
    try {
        # Load System.IO.Compression assembly
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        
        # Open the zip file
        $zip = [System.IO.Compression.ZipFile]::OpenRead($PackagePath)
        
        # Find parameters.xml entry

        $parametersEntry = $zip.Entries | Where-Object { $_.Name -eq "parameters.xml" }
        
        if (-not $parametersEntry) {
            throw "parameters.xml not found in the package"
        }
        
        # Read the parameters.xml content
        $stream = $parametersEntry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        $content = $reader.ReadToEnd()
        $reader.Close()
        $stream.Close()
        $zip.Dispose()
        
        return $content
    }
    catch {
        if ($zip) { $zip.Dispose() }
        throw "Error reading package: $($_.Exception.Message)"
    }
}

# Function to generate setParameters.xml content
function Generate-SetParametersXml {
    param(
        [string]$ParametersXmlContent,
        [bool]$IncludeComments
    )
    
    try {
        # Parse the parameters.xml
        [xml]$parametersXml = $ParametersXmlContent
        
        # Create new XML document for setParameters
        $setParamsXml = New-Object System.Xml.XmlDocument
        
        # Create XML declaration
        $declaration = $setParamsXml.CreateXmlDeclaration("1.0", "utf-8", $null)
        $setParamsXml.AppendChild($declaration) | Out-Null
        
        # Create root element
        $root = $setParamsXml.CreateElement("parameters")
        $setParamsXml.AppendChild($root) | Out-Null
        
        # Process each parameter
        foreach ($param in $parametersXml.parameters.parameter) {
            if ($IncludeComments -and $param.description) {
                $comment = $setParamsXml.CreateComment(" $($param.description) ")
                $root.AppendChild($comment) | Out-Null
            }
            # do not append Application Path parameter
            if ($param.name -eq "Application Path") {
                continue
            }
            
            # Create setParameter element
            $setParam = $setParamsXml.CreateElement("setParameter")
            $setParam.SetAttribute("name", $param.name)
            
            # Set default value based on parameter type and current value
            $defaultValue = Get-DefaultValue -Parameter $param
            $setParam.SetAttribute("value", $defaultValue)
            
            $root.AppendChild($setParam) | Out-Null
        }
        
        return $setParamsXml
    }
    catch {
        throw "Error parsing parameters.xml: $($_.Exception.Message)"
    }
}

# Function to determine appropriate default value
function Get-DefaultValue {
    param($Parameter)
    
    $name = $Parameter.name.ToLower()
    $defaultValue = $Parameter.defaultValue
    
    # If there's already a default value, use it
    if ($defaultValue) {
        return $defaultValue
    }
    
    # Provide intelligent defaults based on parameter name patterns
    switch -Regex ($name) {
        "IP Security Client IP" {
            return "0.0.0.0"
        }
        "IP Security Client IP Mask" {
            return "0.0.0.0"
        }
        "License Xml" {
            return "licenseContent"
        }
        default { 
            $parameterValue = $name.Trim().Replace(" ", "")
            return "#{$parameterValue}#" 
        }
    }
}

# Main execution
try {
    Write-Host "Processing MSDeploy package: $PackagePath" -ForegroundColor Green
    
    # Validate package exists
    if (-not (Test-Path $PackagePath)) {
        throw "Package file not found: $PackagePath"
    }
    
    # Set output path if not provided
    if (-not $OutputPath) {
        $OutputPath = Split-Path $PackagePath -Parent
    }
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Extract parameters.xml content
    Write-Host "Extracting parameters.xml from package..." -ForegroundColor Yellow
    $parametersContent = Get-ParametersFromPackage -PackagePath $PackagePath

    # Optionally remove extra files from package
    if (-not $KeepExtraFiles) {
        #let us do some clean up
        $filesToRemove = 'Content/Website/Default.aspx', 'Content/Website/default.css', 'Content/Website/default.js';
        $stream = New-Object IO.FileStream($PackagePath, [IO.FileMode]::Open);
        $mode = [IO.Compression.ZipArchiveMode]::Update;
        $zip = New-Object IO.Compression.ZipArchive($stream, $mode);
        #-contains is case-insensitive
        ($zip.Entries | Where-Object { $filesToRemove -contains $_.FullName }) | ForEach-Object { $_.Delete(); $fullPath = $_.FullName; Write-Host "Deleting $fullPath"; };
        $zip.Dispose();
        $stream.Close();
        $stream.Dispose();
    }
    
    # Generate setParameters.xml
    Write-Host "Generating setParameters.xml..." -ForegroundColor Yellow
    $setParamsXml = Generate-SetParametersXml -ParametersXmlContent $parametersContent -IncludeComments $IncludeComments
    
    # Save the file
    $outputFile = Join-Path $OutputPath "setParameters.xml"
    
    # Create XmlWriterSettings for proper formatting
    $writerSettings = New-Object System.Xml.XmlWriterSettings
    $writerSettings.Indent = $true
    $writerSettings.IndentChars = "  "
    $writerSettings.NewLineChars = "`r`n"
    $writerSettings.Encoding = [System.Text.Encoding]::UTF8
    
    # Write the XML file
    $writer = [System.Xml.XmlWriter]::Create($outputFile, $writerSettings)
    $setParamsXml.Save($writer)
    $writer.Close()
    
    Write-Host "Successfully generated setParameters.xml at: $outputFile" -ForegroundColor Green
    
    # Display summary
    $paramCount = $setParamsXml.parameters.setParameter.Count
    Write-Host "Generated $paramCount parameter(s) for configuration" -ForegroundColor Cyan
    
    # Show first few parameters as preview
    Write-Host "`nPreview of generated parameters:" -ForegroundColor Cyan
    $setParamsXml.parameters.setParameter | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.name): $($_.value)" -ForegroundColor Gray
    }
    
    if ($paramCount -gt 5) {
        Write-Host "  ... and $($paramCount - 5) more parameter(s)" -ForegroundColor Gray
    }
    
    Write-Host "`nPlease review and update the parameter values in $outputFile before deployment." -ForegroundColor Yellow
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
