Select-AzureRmProfile -Path “c:\dev\powershell\azureprofile.json”

$rg = "Demo.ResGroup.3"
$sa = "psdemostore6430"
$vm = "vmtest01win"
#$dsc_script = "dsc-iis-enable.ps1"
$dsc_script = "dsc-add-user.ps1"
$dsc_path = "C:\Dev\Powershell\DSC"

$cfg_name = "AddUser"
$cfg_archive = $dsc_script + ".zip"
$cfg_args = @{ Credential = Get-Credential -Message 'Enter details of local account to be created'}

# Upload DSC script
Publish-AzureRmVMDscConfiguration -ResourceGroupName $rg -ConfigurationPath ($dsc_path+"\"+$dsc_script) `
                                  -StorageAccountName $sa -Force

$vm = Set-AzureRmVMDscExtension -VMName $vm -ConfigurationName $cfg_name -ResourceGroupName $rg `
                                -ArchiveStorageAccountName $sa -ArchiveBlobName $cfg_archive `
                                -Version "2.21" -Verbose `
                                -ConfigurationArgument $cfg_args