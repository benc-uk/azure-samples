param(
    [string]
    $vmname = "dockerhost"
)

try {
    Get-AzureRmSubscription -ErrorAction SilentlyContinue
} catch {
    Login-AzureRmAccount -ErrorAction Stop
}

Select-AzureRmSubscription -SubscriptionName "Microsoft Azure Internal Consumption" -ErrorAction Stop

$vm = Find-AzureRmResource -ResourceNameContains $vmname -ResourceType "Microsoft.Compute/virtualMachines" -Top 1
$vm
Restart-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName