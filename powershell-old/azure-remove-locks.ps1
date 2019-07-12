param (
    [string]$groupname = "Demo.DevTest-Lab",
    [string]$subname   = "Microsoft Azure Internal Consumption"
 )

try {
    Select-AzureRmProfile -Path "$env:userprofile\.azureprof.json" -ErrorAction Stop
    Get-AzureRmSubscription -ErrorAction SilentlyContinue | Out-Null
} catch {
    Login-AzureRmAccount -ErrorAction Stop
    Save-AzureRmProfile -Path "$env:userprofile\.azureprof.json"
}
Select-AzureRmSubscription -SubscriptionName $subname -ErrorAction Stop

foreach($res in Find-AzureRmResource -ResourceGroupName $groupname) {
    $lock = Get-AzureRmResourceLock -ResourceName $res.name -ResourceGroupName $groupname -ResourceType $res.ResourceType
    if($lock) {
        echo " ### Removing lock '$($lock.Name)' from '$($lock.ResourceName)'"
        Remove-AzureRmResourceLock -LockId $lock.LockId -Force
    }
}