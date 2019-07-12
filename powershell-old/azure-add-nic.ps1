Select-AzureRmProfile -Path “c:\dev\powershell\azureprofile.json”

# Add a NIC to an existing Azure VM and join it to a VNET + subnet
# Note, it must already have 2+ NICs due to Azure platform limtations 
#  - Ben Coleman, Jan 2017

# Existing resources, change names and RG as needed
$vnet_name = "armdemo-vnet"
$subnet_name = "subnet-100"
$vm_name = "vm01"
$rg = "Demo.Deployment.1"

# New resource names, change as blah blah
$nic_name = $vm_name + "_newnic"
#$public_ip_name = $vm_name + "_newip"

# Grab some objects we'll need, by default we'll deploy the NIC into the same location as the VM
$loc = (Get-AzureRmResource -Name $vm_name -ResourceGroupName $rg).Location
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork (Get-AzureRmVirtualNetwork -Name $vnet_name -ResourceGroupName $rg) -Name $subnet_name
$vm = Get-AzureRmVM -Name $vm_name -ResourceGroupName $rg

# Create the new NIC and public IP (dynamic assignment)
#$public_ip = New-AzureRmPublicIpAddress -Name $public_ip_name -AllocationMethod Dynamic -Location $loc -ResourceGroupName $rg
$nic = New-AzureRmNetworkInterface -Name $nic_name -ResourceGroupName $rg -Location $loc -Subnet $subnet

# Add to VM and update it, which unfortunately needs us to stop it 
Stop-AzureRmVM -Name $vm_name -ResourceGroupName $rg -Force
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
Update-AzureRmVM -VM $vm -ResourceGroupName $rg
Start-AzureRmVM -Name $vm_name -ResourceGroupName $rg