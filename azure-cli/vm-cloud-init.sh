#!/bin/bash
set -euo pipefail

#
# Deploy a VM with cloud-init
#
# See https://learn.microsoft.com/en-us/azure/virtual-machines/linux/using-cloud-init
# - https://learn.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-automate-vm-deployment
# - https://cloudinit.readthedocs.io/en/latest/topics/format.html


which az > /dev/null 2>&1 || { echo "💥 Azure CLI is not installed! Please go to http://aka.ms/cli to set it up"; exit 1; }

# Change as needed
RES_GRP=${RES_GRP:-"temp-vm"}
REGION=${REGION:-"uksouth"}
VM_NAME=${VM_NAME:-"temp-vm"}
CLOUD_INIT=${CLOUD_INIT:-"cloud-init/webserver.yaml"}

# Create resource group
echo -e "📦 Creating resource group $RES_GRP in $REGION"
az group create --name "$RES_GRP" --location "$REGION" --output none

# Create VM with cloud-init
echo -e "🚀 Creating VM $VM_NAME in $RES_GRP"
echo -e "🔨 Using custom data file $CLOUD_INIT"
az vm create \
    --resource-group "$RES_GRP" \
    --name "$VM_NAME" \
    --image UbuntuLTS \
    --size Standard_B1s \
    --admin-username azureuser \
    --custom-data "$CLOUD_INIT"\
    --public-ip-sku Standard \
    --query properties.provisioningState -o tsv

# Open port 80
echo -e "🔓 Opening port 80"
az vm open-port --resource-group "$RES_GRP" --name "$VM_NAME" --port 443 --output none

# Get public IP
echo -e "🔑 Getting public IP"
PIP=$(az vm list-ip-addresses --resource-group "$RES_GRP" --name "$VM_NAME" --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

echo -e "🎉 Done! VM web site is available at https://$PIP"
echo -e "🏆 Ignore the certificate warning, we are using a self-signed certificate, sorry!"
