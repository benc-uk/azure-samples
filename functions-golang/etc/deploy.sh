#!/bin/bash

# Quick and dirty deployment script, use all or some parts as needed

# You're going to want to change pretty much all of these
rg=temp.golang-func
loc=northeurope
image=bencuk/golang-func:v1 
saname=golangfunc1
appname=golang-func

# Build container image
docker build . -t $image
docker push $image

# Deploy to Azure (first run)
az group create --resource-group $rg --location $loc -o table
az storage account create --name $saname --location $loc --resource-group $rg --sku Standard_LRS -o table
az functionapp plan create --resource-group $rg --name $appname-plan --location $loc --number-of-workers 1 --sku EP1 --is-linux -o table
az functionapp create --name $appname --storage-account $saname --resource-group $rg --plan $appname-plan --deployment-container-image-name $image --functions-version 3 -o table

# Update existing deployment in Azure with new image
#az functionapp config container set --name $appname --resource-group $rg -i $image