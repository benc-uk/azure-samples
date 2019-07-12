#Select-AzureRmProfile -Path “c:\dev\powershell\azureprofile.json”

### Basic Azure resource settings
$rg = "Demo.ResGroup.3"
$loc = "westeurope"

### VM config settings
$vm_name = "vmtest01win"
$vm_size = "Standard_A2_v2"
$vm_windows_ver = "2012-R2-Datacenter"
$vm_username = "adminuser"
$vm_password = "Password123!"

### Storage settings
$sa_name = "psdemostore" + (Get-Random -Maximum 10000)
$sa_type = "Standard_LRS"
$os_diskname = $vm_name + "_osdisk"
$vm_vhdfile = $vm_name + "_osdisk.vhd"

### Network settings
$vnet_name = "demo-vnet"
$vnet_prefix = "10.0.0.0/16"
$subnet_name = "subnet100"
$subnet_prefix = "10.0.100.0/24"
$nsg_name = $subnet_name + "_nsg"
$nic_name = $vm_name + "_nic"
$public_ip_name = $vm_name + "_ip"



# Create res group
New-AzureRmResourceGroup -Name $rg -Location $loc -Force

# STORAGE - Create storage
$sa = New-AzureRmStorageAccount -Name $sa_name -ResourceGroupName $rg  -Location $loc -Type $sa_type

# NETWORK - Create NSG
$sec_rule = New-AzureRmNetworkSecurityRuleConfig -Name "allow_rdp" -Direction Inbound -Priority 100 -Access Allow -SourceAddressPrefix '*'  -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '3389' -Protocol 'TCP'
$nsg = New-AzureRmNetworkSecurityGroup -SecurityRules $sec_rule -Name $nsg_name -ResourceGroupName $rg -Location $loc

# NETWORK - Create VNET and subnet
$subnet_cfg = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet_name -AddressPrefix "10.0.100.0/24" -NetworkSecurityGroup $nsg
$vnet = New-AzureRmVirtualNetwork -Name $vnet_name -ResourceGroupName $rg -Location $loc -AddressPrefix $vnet_prefix -Subnet $subnet_cfg

# NETWORK - Create VM NIC
$public_ip = New-AzureRmPublicIpAddress -Name $public_ip_name -AllocationMethod Dynamic -Location $loc -ResourceGroupName $rg
$nic = New-AzureRmNetworkInterface -Name $nic_name -ResourceGroupName $rg -Location $loc -Subnet $vnet.Subnets[0] -PublicIpAddress $public_ip


# COMPUTE - Create VM base config
$vm = New-AzureRmVMConfig -VMName $vm_name -VMSize $vm_size

# COMPUTE - Create VM OS config and logon credentials for Windows
$secret_pwd = ConvertTo-SecureString $vm_password -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($vm_username, $secret_pwd)
Set-AzureRmVMOperatingSystem -VM $vm -ComputerName $vm_name -Credential $creds -Windows -ProvisionVMAgent -EnableAutoUpdate 

# COMPUTE - Create VM storage config, add OS disk and source image
Set-AzureRmVMSourceImage -VM $vm -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus $vm_windows_ver -Version "latest"
$vhd_uri = $sa.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vm_vhdfile
Set-AzureRmVMOSDisk -VM $vm -VhdUri $vhd_uri -Name $os_diskname -CreateOption FromImage -Windows

# COMPUTE - Add NIC to VM
Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# PHEW! Finally create the VM in Azure
New-AzureRmVM -VM $vm -ResourceGroupName $rg -Location $loc