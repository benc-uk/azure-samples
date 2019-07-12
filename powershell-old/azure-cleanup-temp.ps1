<#
.SYNOPSIS
    Cleans up Azure resources
.DESCRIPTION
    Removes all resource group starting with "Temp."
.NOTES
    Author:   Ben Coleman
    Date/Ver: Feb 2017, v2
 .PARAMETER subName
    Optional, your subscription name
#>

param(
    [string]
    $subName = "Microsoft Azure Internal Consumption"
)

try {
    Select-AzureRmProfile -Path "$env:userprofile\.azureprof.json" -ErrorAction Stop
    Get-AzureRmSubscription -ErrorAction SilentlyContinue | Out-Null
} catch {
    Login-AzureRmAccount -ErrorAction Stop
    Save-AzureRmProfile -Path "$env:userprofile\.azureprof.json"
}

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$caption = "Warning!"
$message = "This will remove all 'Temp' resource groups subscription. Do you want to proceed?"
$result = $Host.UI.PromptForChoice($caption, $message, $choices, 1)

if($result -eq 0) {
    try {
        Select-AzureRmSubscription -SubscriptionName $subName -ErrorAction Stop
    } catch {
        echo "Subscription '$subName' not found, exiting..."
        exit
    }

    $groups = Find-AzureRmResourceGroup
    foreach($g in $groups) {
        if($g.name.StartsWith("Temp.")) {
            echo "Deleting group: '$($g.name)' & contained resources, please wait..."
            Remove-AzureRmResourceGroup -Name $g.name -Force | Out-Null
        }
    }
} else {
    echo "Exiting with no changes"
}