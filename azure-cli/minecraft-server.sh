#!/bin/bash
#set -e

# Load external input variables
#source vars.sh

if [[ -z $1 || -z $2 || -z $3 ]]; then
  echo -e "\e[31m»»» 💥 Error! Please provide resource group, location and server name as parameters"
  exit 1
fi

echo -e "\n\e[34m╔══════════════════════════════════╗"
echo -e "║\e[33m    Minecraft Server Deployer\e[34m     ║"
echo -e "╚══════════════════════════════════╝"
echo -e "\e[35mBen Coleman, 2020   \e[39mv1.0.0  🚀 🚀 🚀\n"

echo -e "\e[34m»»» 🍳  \e[32mRunning pre-req checks\e[0m..."
az > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[31m»»» ⚠️  Azure CLI is not installed! 😥  Please go to http://aka.ms/cli to set it up"
  exit
fi

az account show > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[31m»»» ⚠️  You are not logged into Azure! 😥  Run 'az login' before running this script"
  exit
fi

echo -e "\e[34m»»» 🔑  \e[32mUsing default Azure subscription \e[33m'$(az account show --query name -o tsv)'\e[39m"

# External vars
RES_GRP=$1
LOC=$2
NAME=$3

# Internal vars
STORAGE_PREFIX="mc"
STORAGE_SUFFIX=$(echo -n $NAME | md5sum | cut -c -5 )
STORAGE_NAME="${STORAGE_PREFIX}${STORAGE_SUFFIX}"
SHARE_NAME="minecraft"

# Container settings
IMAGE="itzg/minecraft-bedrock-server"
MEM=1
CPU=2

# Quit on error
set -e

# # Resource group
echo -e "\n\e[34m»»» 📁  \e[36mCreating resource group...\e[39m"
az group create --name "$RES_GRP" -l $LOC -o table

# Storage account
echo -e "\n\e[34m»»» 📦  \e[36mCreating storage account...\e[39m"
az storage account create --name "$STORAGE_NAME" --resource-group "$RES_GRP" -l $LOC --sku Standard_LRS -o table --query "{name: name, status: provisioningState}"

# Azure File share
STORAGE_KEY=$(az storage account keys list -n "$STORAGE_NAME" --query "[0].value" -o tsv)
echo -e "\n\e[34m»»» 📃  \e[36mCreating file share...\e[39m"
az storage share create --name "$SHARE_NAME" --account-name "$STORAGE_NAME" --account-key "$STORAGE_KEY" -o table 

echo -e "\n\e[34m»»» 🚀  \e[36mDeploying Minecraft server container...\e[39m"
az container create --name "$NAME" --resource-group "$RES_GRP" \
--image $IMAGE --ports 19132 --protocol UDP --ip-address public \
--dns-name-label $NAME -e "EULA=TRUE" \
--azure-file-volume-account-key "$STORAGE_KEY" \
--azure-file-volume-account-name "$STORAGE_NAME" \
--azure-file-volume-mount-path "/data" \
--azure-file-volume-share-name "$SHARE_NAME" \
--memory $MEM --cpu $CPU \
--query "{name:name, state:provisioningState, ip:ipAddress.ip, os:osType}" -o table

STATE="NA"
while true
do
   STATE=`az container show --name "$NAME" --resource-group "$RES_GRP" -o tsv --query "provisioningState"`
   if [ "$STATE" == "Succeeded" ]; then
      echo -e "\n\e[34m»»» 🚀  \e[36mServer is deployed and started!\e[39m"
      IP=`az container show --name "$NAME" --resource-group "$RES_GRP" --query "ipAddress.ip" -o tsv`
      echo -e "\n\e[34m»»» 😄  \e[36mConnect to the server using: $NAME.$LOC.azurecontainer.io or $IP"
      break
   fi
   echo -e "\n\e[34m»»» ⌚  \e[36mServer still starting, please wait...\e[39m"
   sleep 5
done