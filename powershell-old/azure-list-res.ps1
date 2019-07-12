try {
    Select-AzureRmProfile -Path "$env:userprofile\.azureprof.json" -ErrorAction Stop
    Get-AzureRmSubscription -ErrorAction SilentlyContinue | Out-Null
} catch {
    Login-AzureRmAccount -ErrorAction Stop
    Save-AzureRmProfile -Path "$env:userprofile\.azureprof.json"
}

$resources = Find-AzureRmResource 
foreach($res in $resources) {
    $res | Format-Table -Property Name,ResourceGroupName,ResourceType
}