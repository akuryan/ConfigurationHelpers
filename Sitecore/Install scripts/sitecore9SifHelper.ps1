Param(
    [bool]$SitecoreInstall = $false,
    [bool]$XconnectInstall = $false,
    [bool]$solrConfigure = $false,
    [bool]$createCertificate = $false
)

#define parameters 
$prefix = "DEFINE YOU PREFIX HERE" 
$PSScriptRoot = "PATH WHERE CONFIG FILES"
$XConnectCollectionService = "XCONNNECT WEB APP" 
$sitecoreSiteName = "DEFINE SITECORE SITE HERE" 
$SolrUrl = "https://SOLR-HOSTNAME-HERE:8983/solr" 
$SolrRoot = "SOLR LOCAL PATH" 
$SolrService = "solr" 
$SqlServer = "SQL SERVER NAME" 
$SqlAdminUser = "SQL SERVER ADMIN USER" 
$SqlAdminPassword="SQL SERVER ADMIN PASSWORD"
$certThumbprint = "CERT THUMBPRINT"
#passwords
$SitecoreAdminPassword = "GeneratePASSWORD"
$SqlCorePassword = "GeneratePASSWORD" 
$SqlMasterPassword = "GeneratePASSWORD" 
$SqlWebPassword = "GeneratePASSWORD" 
$SqlReportingPassword = "GeneratePASSWORD" 
$SqlProcessingPoolsPassword = "GeneratePASSWORD" 
$SqlProcessingTasksPassword = "GeneratePASSWORD" 
$SqlReferenceDataPassword = "GeneratePASSWORD" 
$SqlMarketingAutomationPassword = "GeneratePASSWORD" 
$SqlFormsPassword = "GeneratePASSWORD" 
$SqlExmMasterPassword = "GeneratePASSWORD" 
$SqlMessagingPassword = "GeneratePASSWORD" 
$EXMCryptographicKey = "GENERATE-KEY"
$EXMAuthenticationKey = "GENERATE-KEY"
$TelerikEncryptionKey = "GENERATE-KEY"
 
if ($createCertificate) {
    #install client certificate for xconnect 
    $certParams = @{     
        Path = "$PSScriptRoot\xconnect-createcert.json"     
        CertificateName = "$prefix.xconnect_client" 
        } 
        
    Install-SitecoreConfiguration @certParams -Verbose 
}

if ($solrConfigure) {
    $solrParams = @{     
        Path = "$PSScriptRoot\sitecore-solr.json"     
        SolrUrl = $SolrUrl     
        SolrRoot = $SolrRoot     
        SolrService = $SolrService     
        CorePrefix = $prefix 
    } 
    
    Install-SitecoreConfiguration @solrParams

    #install solr cores for xdb 
    $solrParams = 
    @{     
        Path = "$PSScriptRoot\xconnect-solr.json"     
        SolrUrl = $SolrUrl     
        SolrRoot = $SolrRoot     
        SolrService = $SolrService     
        CorePrefix = $prefix 
    } 
    Install-SitecoreConfiguration @solrParams -Verbose
}

if ($XconnectInstall) {
	choco install ssdt15 sqlserver-cmdlineutils -y
	# TODO: IIS Client Certificate Mapping Authentication
   #deploy xconnect instance 
    $xconnectParams = @{     
        Path = "$PSScriptRoot\xconnect-xp0.json"     
        Package = "$PSScriptRoot\Sitecore 9.0.2 rev. 180604 (OnPrem)_xp0xconnect.scwdp.zip"     
        LicenseFile = "$PSScriptRoot\license.xml"     
        Sitename = $XConnectCollectionService     
        XConnectCert = $certThumbprint   
        SqlDbPrefix = $prefix  
        SqlServer = $SqlServer  
        SqlAdminUser = $SqlAdminUser     
        SqlAdminPassword = $SqlAdminPassword     
        SolrCorePrefix = $prefix     
        SolrURL = $SolrUrl
        SSLCert = $certThumbprint
        SqlCollectionPassword = $SqlCollectionPassword
        SqlProcessingPoolsPassword = $SqlProcessingPoolsPassword
        SqlReferenceDataPassword = $SqlReferenceDataPassword
        SqlMarketingAutomationPassword = $SqlMarketingAutomationPassword
        SqlMessagingPassword = $SqlMessagingPassword
        XConnectEnvironment = "Production"
        } 

    Install-SitecoreConfiguration @xconnectParams -Verbose  
}

if ($SitecoreInstall) {
	choco install ssdt15 sqlserver-cmdlineutils -y
	# TODO: IIS Client Certificate Mapping Authentication
    #install sitecore instance 
    $sitecoreParams = 
    @{     
        Path = "$PSScriptRoot\sitecore-XP0.json"     
        Package = "$PSScriptRoot\Sitecore 9.0.2 rev. 180604 (OnPrem)_single.scwdp.zip"  
        LicenseFile = "$PSScriptRoot\license.xml"     
        SqlDbPrefix = $prefix  
        SqlServer = $SqlServer  
        SqlAdminUser = $SqlAdminUser     
        SqlAdminPassword = $SqlAdminPassword     
        SolrCorePrefix = $prefix  
        SolrUrl = $SolrUrl     
        XConnectCert = $certThumbprint     
        Sitename = $sitecoreSiteName         
        XConnectCollectionService = "https://$XConnectCollectionService"  
        SitecoreAdminPassword = $SitecoreAdminPassword
        SqlCorePassword = $SqlCorePassword
        SqlMasterPassword = $SqlMasterPassword
        SqlWebPassword = $SqlWebPassword
        SqlReportingPassword = $SqlReportingPassword
        SqlProcessingPoolsPassword = $SqlProcessingPoolsPassword 
        SqlProcessingTasksPassword = $SqlProcessingTasksPassword
        SqlReferenceDataPassword = $SqlReferenceDataPassword
        SqlMarketingAutomationPassword = $SqlMarketingAutomationPassword
        SqlFormsPassword = $SqlFormsPassword
        SqlExmMasterPassword = $SqlExmMasterPassword 
        SqlMessagingPassword = $SqlMessagingPassword
        EXMCryptographicKey = $EXMCryptographicKey
        EXMAuthenticationKey = $EXMAuthenticationKey
        TelerikEncryptionKey = $TelerikEncryptionKey
    } 
    Install-SitecoreConfiguration @sitecoreParams 
}

