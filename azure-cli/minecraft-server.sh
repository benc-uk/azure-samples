#!/bin/bash

# Minecraft container settings, change as you feel
MEM=1 # Gigabytes
CPU=1 # Cores

# Need at least three params
if [[ -z $1 || -z $2 || -z $3 ]]; then
  echo -e "\e[31m»»» 💥 Error! Please provide resource group, location and server name as parameters"
  exit 1
fi

# Rename our parameters into something readable
RES_GRP=$1
LOC=$2
NAME=$3

# Storage variables, you might to change this, but maybe not
# Note. Use a MD5 hash of the server name to name the storage account
NAME_HASH=$(echo -n $NAME | md5sum )
STORAGE_NAME="mc${NAME_HASH:0:5}"
SHARE_NAME="minecraft"

# Image name can be overridden with 4th parameter
IMAGE="itzg/minecraft-bedrock-server"
if [[ $4 ]]; then
  IMAGE=$4
fi 

# Preamble
echo -e "\n\e[34m╔══════════════════════════════════╗"
echo -e "║\e[33m    Minecraft Server Deployer\e[34m     ║"
echo -e "╚══════════════════════════════════╝"
echo -e "\e[35mBen Coleman, 2020   \e[39mv1.0.0  ⛏  🐑  💎\n"

# Check Azure CLI
echo -e "\e[34m»»» 🍳  \e[32mRunning pre-req checks\e[0m..."
az > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[31m»»» ⚠️  Azure CLI is not installed! 😥  Please go to http://aka.ms/cli to set it up"
  exit
fi

# Check Azure CLI is logged in!
az account show > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[31m»»» ⚠️  You are not logged into Azure! 😥  Run 'az login' before running this script"
  exit
fi

# Ok we can carry on

echo -e "\e[34m»»» 🧮  \e[32mWill deploy \e[33m'$IMAGE'\e[39m"
echo -e "\e[34m»»» 🔑  \e[32mUsing default Azure subscription \e[33m'$(az account show --query name -o tsv)'\e[39m"

# Quit on error from here
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

# Main Minecraft server container
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

# Check container is deployed & running
STATE="NA"
while true
do
   STATE=`az container show --name "$NAME" --resource-group "$RES_GRP" -o tsv --query "provisioningState"`
   if [ "$STATE" == "Succeeded" ]; then
      echo -e "\n\e[34m»»» 🚀  \e[36mServer is deployed, container started!\e[39m"
      echo -e "\e[34m»»» 😮  \e[36mIt might take up to 5 minutes before the server is fully ready..."
      break
   fi
   echo -e "\n\e[34m»»» ⌚  \e[36mContainer still starting, please wait...\e[39m"
   sleep 5
done

# Now check the server is started, it will download data & populate the file share on first start
# Once we reach a number of files, it's a good indication the server is ready
FILECOUNT=0
READY_COUNT=21
while true
do
   FILECOUNT=`az storage file list --account-key "$STORAGE_KEY" --account-name "$STORAGE_NAME" --share-name "$SHARE_NAME" -o tsv|wc -l`
   if (( FILECOUNT >= READY_COUNT )); then
      echo -e "\e[34m»»» 🎮  \e[36mMinecraft server is ready for players!\e[39m"
      IP=`az container show --name "$NAME" --resource-group "$RES_GRP" --query "ipAddress.ip" -o tsv`
      echo -e "\e[34m»»» 😄  \e[36mConnect to the server using: \e[33m$NAME.$LOC.azurecontainer.io \e[36mor \e[33m$IP\n"      
      break
   fi
   PERC=`echo "scale=1; $FILECOUNT/$READY_COUNT*100" | bc`
   echo -e "\e[34m»»» ⌚  \e[36mMinecraft server is $PERC% ready, please wait...\e[39m"
   sleep 20
done