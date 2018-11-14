# This script will work only with Server 2016 and Windows 10 (and onwards)
# Script could ask for confirmation for NuGet provider installation - it is required to install modules

param (
    #comma-separated list of DNS names for certificate (shall be specified in "")
    #You must issue a wildcard for at least two segments of domain for it to be trusted. For example *.dev is bad, but *.local.dev is good.
    [string]$dnsNames,
    #by default, locally signed certificate will be computer name + "-trusted"
    [string]$localSigningCertificateName = $env:COMPUTERNAME + "-trusted",
    #by default all certificates will be issued for 10 yesrs, which guarantees to overcome average workstation life
    [int]$signingCertValidityDays = 3650,
    [int]$certificateValidityDays = 3650
)

function CheckAndInstallModule {
    param (
        [string]$moduleName
    )
    if (Get-Module -ListAvailable -Name $moduleName) {
        Write-Host "$moduleName Already Installed"
    } 
    else {
        try {
            Install-Module -Name $moduleName -AllowClobber -Confirm:$False -Force  
        }
        catch [Exception] {
            $_.message 
            exit
        }
    }
}

$nugetPackageProviderMinVersion = 2.8.5.201;
#this script will make use of module for generating Root self-signed certificate; module could be removed by `Remove-Module PSPKI`
if ((Get-PackageProvider -Name NuGet).version -lt $nugetPackageProviderMinVersion ) {
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion $nugetPackageProviderMinVersion -Confirm:$False -Force 
    }
    catch [Exception]{
        $_.message 
        exit
    }
}
else {
    Write-Host "Version of NuGet installed = " (Get-PackageProvider -Name NuGet).version
}
CheckAndInstallModule -moduleName "PowerShellGet";
CheckAndInstallModule -moduleName "PSPKI";

$certStore = "LocalMachine";
#signing certificate shall be placed at Root
$signingCertStore = "Cert:\$certStore\Root\";
#regular certificate shall be placed at My
$regularCertStore = "Cert:\$certStore\My\";
$signingCertSubject = "CN=DONOTTRUST-LocalSigningCertificate, O=DO_NOT_TRUST, OU=Created by script";
# check, if we already have signing certificate
$rootCertExists = [bool](Get-ChildItem $regularCertStore | Where-Object Subject -eq $signingCertSubject);

if (!$rootCertExists) {
    # if we do not have it - generate it
    $certParameters = @{
        Subject = $signingCertSubject
        NotAfter = [DateTime]::Now.AddDays($signingCertValidityDays)
        IsCA = $true
        ProviderName = "Microsoft Software Key Storage Provider"
        Exportable = $true
        StoreLocation = $certStore
        FriendlyName = "DONOTTRUST-" + $localSigningCertificateName
        KeyUsage = "CrlSign, KeyCertSign"
    };
    Import-Module PSPKI;
    New-SelfSignedCertificateEx @certParameters;
    #New-SelfSignedCertificateEx generates certificates at My store - and we need to keep it there with a key
    #to trust it - we need public part added in LocalMachine/Root
    $tmpCrtFile = New-TemporaryFile;
    $generatedThumb = (Get-ChildItem $regularCertStore | Where-Object Subject -eq $signingCertSubject).Thumbprint;
    $generatedCert = Get-ChildItem $regularCertStore$generatedThumb;
    #export public part of certificate
    Export-Certificate -Cert $generatedCert -FilePath $tmpCrtFile.FullName;
    #import it to root storage to trust certificate
    Import-Certificate -CertStoreLocation $signingCertStore -FilePath $tmpCrtFile.FullName;
    Remove-Item $tmpCrtFile.FullName -Force;
} else {
    Write-Host "Signing certificate already exists";
}
#get signing certificate thmbprint
$signingThumb = (Get-ChildItem $regularCertStore | Where-Object Subject -eq $signingCertSubject).Thumbprint;
$signingCert = Get-ChildItem $regularCertStore$signingThumb;
$FriendlyName = $dnsNames.Split(',')[0];
Write-Host "FriendlyName is $FriendlyName";

# generate local certificate, which is trusted by usign signing certificate
$params = @{
    CertStoreLocation = $regularCertStore
    DnsName = $dnsNames.Split(',')
    Signer = $signingCert
    FriendlyName = $FriendlyName
    KeyExportPolicy = 'Exportable'
    KeyProtection = 'None'
    Provider = 'Microsoft Enhanced RSA and AES Cryptographic Provider'
	NotAfter = [DateTime]::Now.AddDays($certificateValidityDays)
};
$signedCertificate = New-SelfSignedCertificate @params;
Write-Host "Generated $signedCertificate"
