
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

$vault_name = 'keyvault-bc'

####  KEYS  ####

# Add a new key
$key = Add-AzureKeyVaultKey -VaultName $vault_name -Name 'testkey' -Destination 'Software'

# Fetch and echo the key
$key_fetch = Get-AzureKeyVaultKey -VaultName $vault_name -Name 'testkey'
echo "### Key details " $key_fetch.Key.ToString()


#### SECRETS ####

# Create a secret value (secure-string) then save as secret
$secretvalue = ConvertTo-SecureString 'Secr3t_Pa$$w0rd' -AsPlainText -Force
$secret = Set-AzureKeyVaultSecret -VaultName $vault_name -Name 'myapp-secret-password' -SecretValue $secretvalue

# Fetch and echo the secret
$secret_fetch = Get-AzureKeyVaultSecret -VaultName $vault_name -Name 'myapp-secret-password'
$secret_plain = ConvertFrom-SecureString -SecureString $secret_fetch.SecretValue
echo ""
echo "### Secret in plain! " $secret_fetch.SecretValueText


#### CERTS ####

$securepfxpwd = ConvertTo-SecureString –String 'qwe' –AsPlainText –Force
$cer = Import-AzureKeyVaultCertificate -VaultName $vault_name -Name 'demo-cert' -FilePath 'c:\temp\selfsigned.pfx' -Password $securepfxpwd
echo ""
echo "### New cert details THUMBPRINT: " $cer.Thumbprint