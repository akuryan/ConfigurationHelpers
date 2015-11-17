Import-Module WebAdministration
$Websites = Get-ChildItem IIS:\Sites
foreach ($Site in $Websites) {

    $Binding = $Site.bindings
    [string]$BindingInfo = $Binding.Collection
    [string]$IP = $BindingInfo.SubString($BindingInfo.IndexOf(" "),$BindingInfo.IndexOf(":")-$BindingInfo.IndexOf(" "))         
    [string]$Port = $BindingInfo.SubString($BindingInfo.IndexOf(":")+1,$BindingInfo.LastIndexOf(":")-$BindingInfo.IndexOf(":")-1) 

    #Write-Host "Binding info for" $Site.name " - IP:"$IP", Port:"$Port
	Write-Host "Binding info for" $Site.name " --- " $Binding.Collection
}