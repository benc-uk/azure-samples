param (
    [string]$groupname = "Contoso.Demosite"
 )

#Select-AzureRmProfile -Path “c:\dev\powershell\azureprofile.json”

$resources = Find-AzureRmResource -ResourceGroupName $groupname -ResourceType Microsoft.Web/sites/slots
foreach($res in $resources) {
    $res | Remove-AzureRmResource -Force
}