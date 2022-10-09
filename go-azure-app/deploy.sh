#!/bin/bash
set -eou pipefail

# Check CLI is installed
which az > /dev/null || { echo -e "💥 Error! Azure CLI is not installed. https://aka.ms/azure-cli"; exit 1; }

# It's OK to call az account show multiple times, it only reads from the local ~/.azure/ files
SUB_NAME=$(az account show --query name -o tsv)
if [ -z "$SUB_NAME" ]; then
  echo -e "💥 \e[31mYou are not logged into Azure!"
  exit 1
fi
TENANT_ID=$(az account show --query tenantId -o tsv)

# echo banner
echo -e "\e[34m╭─────────────────────────────────────╮"
echo -e "│\e[33m  Deploying go-azure-app to Azure 🚀 \e[34m│"
echo -e "\e[34m╰─────────────────────────────────────╯"

echo -e "\e[34mAzure details: \e[0m"
echo -e "  🔑 \e[34mSubscription: \e[33m$SUB_NAME\e[0m"
echo -e "  🌐 \e[34mTenant:       \e[33m$TENANT_ID\e[0m"
echo -e -n "\e[95mIf these details are incorrect, press CTRL+C to exit\nOr any other key to continue...\e[0m"

read -n 1 -s -r -p ""
echo ""

AZ_RES_GROUP=${AZ_RES_GROUP:-"go-azure-app"}
AZ_LOCATION=${AZ_LOCATION:-"westeurope"}
AZ_APP_NAME=${AZ_APP_NAME:-"go-azure-app"}
AZ_STORAGE_ACCOUNT=${AZ_STORAGE_ACCOUNT:-"goappstor$USER"}
AZ_CONTAINER_NAME=${AZ_CONTAINER_NAME:-"example"}

echo -e "📦 \e[34mCreating Resource group: \e[33m$AZ_RES_GROUP\e[0m"
az group create --name "$AZ_RES_GROUP" --location "$AZ_LOCATION" --query properties.provisioningState -o tsv

echo -e "\n💾 \e[34mCreating storage account: \e[33m$AZ_STORAGE_ACCOUNT\e[0m"
az storage account create \
  --name "$AZ_STORAGE_ACCOUNT" \
  --location "$AZ_LOCATION" \
  --resource-group "$AZ_RES_GROUP" \
  --sku Standard_LRS --query provisioningState -o tsv

echo -e "\n📊 \e[34mCreating Log Analytics workspace: \e[33m$AZ_APP_NAME-logs\e[0m"
az monitor log-analytics workspace create \
  --resource-group "$AZ_RES_GROUP" \
  --workspace-name "$AZ_APP_NAME-logs" \
  --location "$AZ_LOCATION" --query provisioningState -o tsv

wsid=$(az monitor log-analytics workspace show \
  --resource-group "$AZ_RES_GROUP" \
  --workspace-name "$AZ_APP_NAME-logs" \
  --query customerId -o tsv)
logsKey=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group "$AZ_RES_GROUP" \
  --workspace-name "$AZ_APP_NAME-logs" \
  --query primarySharedKey -o tsv)

echo -e "\n🌏 \e[34mCreating Container App environment: \e[33m$AZ_APP_NAME-env\e[0m"
az containerapp env create --name "$AZ_APP_NAME-env" --resource-group "$AZ_RES_GROUP" --location "$AZ_LOCATION" \
--logs-workspace-id "$wsid" --logs-workspace-key "$logsKey" --query properties.provisioningState -o tsv

echo -e "\e[34m⏰ Checking environment to be ready...\e[0m"
state=$(az containerapp env show --name "$AZ_APP_NAME-env" --resource-group "$AZ_RES_GROUP" --query "properties.provisioningState" -o tsv)
# loop until the env is ready
while [ "$state" != "Succeeded" ]; do  
  echo "⌚ Environment is $state, waiting 5 seconds..."
  sleep 5
  state=$(az containerapp env show --name "$AZ_APP_NAME-env" --resource-group "$AZ_RES_GROUP" --query "properties.provisioningState" -o tsv)
done
echo -e "\e[34m🚦 \e[34mEnvironment is ready!\e[0m"

echo -e "\n\e[34m🚀 Deploying container app: \e[33m$AZ_APP_NAME\e[0m"
az containerapp create --name "$AZ_APP_NAME" --resource-group "$AZ_RES_GROUP"  \
--environment "$AZ_APP_NAME-env" --system-assigned \
--image "ghcr.io/benc-uk/go-azure-app:latest" \
--env-vars "AZURE_STORAGE_ACCOUNT=$AZ_STORAGE_ACCOUNT" \
--cpu "0.25" --memory "0.5" --ingress external --target-port 8000 \
--query properties.provisioningState -o tsv

# Get assigned identity
identity=$(az containerapp show --name "$AZ_APP_NAME" --resource-group "$AZ_RES_GROUP" --query identity.principalId -o tsv)
subId=$(az account show --query id -o tsv)

# Get appId as a means to check we're ready for role assignment
appId=$(az ad sp show --id "$identity" --query appId -o tsv)
while [ -z "$appId" ]; do
  echo "⌚ Identity is not ready yet, waiting 5 seconds..."
  sleep 5
  appId=$(az ad sp show --id "$identity" --query appId -o tsv)
done

echo -e "\n\e[34m🔑 Assigning Storage Blob Data Contributor role to the app identity\e[0m"
az role assignment create --role "Storage Blob Data Contributor" --assignee "$identity" \
--scope "/subscriptions/$subId/resourceGroups/$AZ_RES_GROUP/providers/Microsoft.Storage/storageAccounts/$AZ_STORAGE_ACCOUNT" \
--query type -o tsv

# create a storage container
echo -e "\n\e[34m📂 Creating storage container: \e[33m$AZ_CONTAINER_NAME\e[0m"
az storage container create --name "$AZ_CONTAINER_NAME" --account-name "$AZ_STORAGE_ACCOUNT" > /dev/null 2>&1

host=$(az containerapp show --name "$AZ_APP_NAME" --resource-group "$AZ_RES_GROUP" --query properties.configuration.ingress.fqdn -o tsv)

echo -e "\n\e[34m🧪 Test the app with CURL commands:\e[0m"
echo "   curl https://$host/list/example"
echo "   curl -d 'hello world' https://$host/create/example/hello.txt"
