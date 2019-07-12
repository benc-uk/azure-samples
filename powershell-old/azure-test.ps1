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

Register-AzureRmProviderFeature -FeatureName AllowArchive -ProviderNamespace Microsoft.Storage