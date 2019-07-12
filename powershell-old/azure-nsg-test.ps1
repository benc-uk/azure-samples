$nsg_name = "Example-NSG"
$grp_name = "Temp"

$rules = @()

for($i=1; $i -le 124; $i++) {
    $rule = New-AzureRmNetworkSecurityRuleConfig -Name ("rule_"+$i) -Direction Inbound -Priority (100+$i) -Access Deny -SourceAddressPrefix '*'  -SourcePortRange $i -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'
    $rules += $rule
}

New-AzureRmNetworkSecurityGroup -Location northeurope -Name $nsg_name -ResourceGroupName $grp_name -SecurityRules $rules