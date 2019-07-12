param (
    [string]$groupname = "Demo.DevTest-Lab",
    [string]$subname   = "Microsoft Azure Internal Consumption"
)

### Standard Azure login and subscription selection
try {
    Select-AzureRmProfile -Path "$env:userprofile\.azureprof.json" -ErrorAction Stop
    Get-AzureRmSubscription -ErrorAction SilentlyContinue | Out-Null
} catch {
    Login-AzureRmAccount -ErrorAction Stop
    Save-AzureRmProfile -Path "$env:userprofile\.azureprof.json"
}
Select-AzureRmSubscription -SubscriptionName $subname -ErrorAction Stop

### Basic Azure resource settings
$rg = $groupname
$loc = "westeurope"

### VM config settings
$vm_name = "vmtest01"
$vm_size = "Standard_A1_v2"
$vm_ubuntu_ver = "16.04.0-LTS"
$vm_username = "adminuser"
$vm_ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA1iR5NeXJd/+zpVHtgj//PY1znXgnMOhWYQOkxQj+4WsR18ptqT2gkS0wZOPVg0UEycz0DIssznzSK4QyJZtAVbMZasu21G+XdAnfdFqzAqr4QFEyGqZViLIE+yUHvfOcwrEtEenCCWHFSbmuUSsORyyol81P4rms9MdXoBNj4DaDOKa10fPziWCjC3Cprs7VaHcETIOgf//FN5t5qMrzwmW4cCpql3vzyr0FugdSOwv3yaQiylw1ayi6czJyRoIhPgpohSG5WigvEC5gFjhO43MFtD6tMu3EGzqzs7YyiFhRQI44dvHDCLHP/fJRN/w4IgQHH3jMlYwfHafed4JIVQ== rsa-key-20160706"

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
$sec_rule = New-AzureRmNetworkSecurityRuleConfig -Name "allow_ssh" -Direction Inbound -Priority 100 -Access Allow -SourceAddressPrefix '*'  -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '22' -Protocol 'TCP'
$nsg = New-AzureRmNetworkSecurityGroup -SecurityRules $sec_rule -Name $nsg_name -ResourceGroupName $rg -Location $loc

# NETWORK - Create VNET and subnet
$subnet_cfg = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet_name -AddressPrefix "10.0.100.0/24" -NetworkSecurityGroup $nsg
$vnet = New-AzureRmVirtualNetwork -Name $vnet_name -ResourceGroupName $rg -Location $loc -AddressPrefix $vnet_prefix -Subnet $subnet_cfg

# NETWORK - Create VM NIC
$public_ip = New-AzureRmPublicIpAddress -Name $public_ip_name -AllocationMethod Dynamic -Location $loc -ResourceGroupName $rg
$nic = New-AzureRmNetworkInterface -Name $nic_name -ResourceGroupName $rg -Location $loc -Subnet $vnet.Subnets[0] -PublicIpAddress $public_ip


# COMPUTE - Create VM base config
$vm = New-AzureRmVMConfig -VMName $vm_name -VMSize $vm_size

# COMPUTE - Create VM OS config and logon credentials. SSH key auth only, so password is ignored and disabled
$secret_pwd = ConvertTo-SecureString “password_is_not_enabled” -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential ($vm_username, $secret_pwd)
Set-AzureRmVMOperatingSystem -Linux -Credential $creds -VM $vm -ComputerName $vm_name -DisablePasswordAuthentication

# COMPUTE - Add the SSH key to the VM
Add-AzureRmVMSshPublicKey -VM $vm -KeyData $vm_ssh_key -Path "/home/$vm_username/.ssh/authorized_keys"

# COMPUTE - Create VM storage config, add OS disk and source image
Set-AzureRmVMSourceImage -VM $vm -PublisherName "Canonical" -Offer "UbuntuServer" -Skus $vm_ubuntu_ver -Version "latest"
$vhd_uri = $sa.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vm_vhdfile
Set-AzureRmVMOSDisk -VM $vm -VhdUri $vhd_uri -Name $os_diskname -CreateOption FromImage

# COMPUTE - Add NIC to VM
Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# PHEW! Finally create the VM in Azure
New-AzureRmVM -VM $vm -ResourceGroupName $rg -Location $loc