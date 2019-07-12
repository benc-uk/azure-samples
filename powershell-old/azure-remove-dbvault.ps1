Select-AzureRmProfile -Path “c:\dev\powershell\azureprofile.json”

# Change as needed!
$VaultName = "DBVAULT"
 
Get-AzureRmRecoveryServicesVault -Name $VaultName | Set-AzureRmRecoveryServicesVaultContext
 
 
##### AzureSQL
$GBVAVMCon3 = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureSQL
echo "#### VAULT CONTAINER INFO ####"
$GBVAVMCon3

echo "#### BACKUP ITEM PROTECTION ####"
$GBVAVMCon3 | % {
  $PI = Get-AzureRmRecoveryServicesBackupItem -Container $_ -WorkloadType AzureSQLDatabase
  $PI

  ### !ADDED! - BenC. There were multiple backitems so I had to loop through them
  ### !ADDED! - BenC. Also required is -RemoveRecoveryPoints option
  $PI | % {
    Disable-AzureRmRecoveryServicesBackupProtection -Item $_ -Force -RemoveRecoveryPoints
  }

}  

### !ADDED! - BenC. I had to add this before I could delete the vault
Unregister-AzureRmRecoveryServicesBackupContainer $GBVAVMCon3
