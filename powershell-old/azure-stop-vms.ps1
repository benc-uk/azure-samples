param(
    [string]$res_grp = "Keep.devops.infra",
    [string]$subname   = "Microsoft Azure Internal Consumption"
)

try {
    Get-AzureRmSubscription -ErrorAction SilentlyContinue | Out-Null
} catch {
    Login-AzureRmAccount -ErrorAction Stop
}
Select-AzureRmSubscription -SubscriptionName $subname -ErrorAction Stop

$vms = Find-AzureRmResource -ResourceType "Microsoft.Compute/virtualMachines" -ResourceGroupNameEquals $res_grp
if($vms.Length -lt 1) {
    echo " ### No VMs found! Bye!"
    exit
}

foreach($vm in $vms) {

    $pwr_state = Get-AzureRmVM -ResourceGroupName $res_grp -Name $vm.Name -Status | Select-Object -ExpandProperty Statuses | Where-Object {$_.Code -like '*PowerState*'} | Select-Object @{l='PowerState';e={$_.Code.Split('/')[1]}}
    
    if($pwr_state -match 'running') {
        echo " ### Stopping VM '$($vm.Name)'..."
        Stop-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force | Out-Null
    } else {
        echo " ### VM '$($vm.Name)' is already powered off"
    }
}
