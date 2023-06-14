#!/bin/bash

# Definitely need to change this
SUBJECT="repo:benc-uk/azure-samples:ref:refs/heads/master"

# Probably need to change these
RES_GROUP="github-oidc"
IDENTITY_NAME="github-oidc"
REGION="westeurope"

echo "❱❱❱ 📂 Creating new resource group: ${RES_GROUP}"
az group create --name "${RES_GROUP}" --location "${REGION}" -o tsv --query 'id'

echo "❱❱❱ 🔐 Creating new user managed identity: ${IDENTITY_NAME}"
az identity create --resource-group "${RES_GROUP}" --name "${IDENTITY_NAME}" --location "${REGION}" -o tsv --query 'id'

MI_PRINCIPAL_ID="$(az identity show --resource-group "${RES_GROUP}" --name "${IDENTITY_NAME}" --query 'principalId' -o tsv)"
MI_CLIENT_ID="$(az identity show --resource-group "${RES_GROUP}" --name "${IDENTITY_NAME}" --query 'clientId' -o tsv)"
MI_TENANT="$(az identity show --resource-group "${RES_GROUP}" --name "${IDENTITY_NAME}" --query 'tenantId' -o tsv)"
OIDC_ISSUER="https://token.actions.githubusercontent.com"
SUBSCRIPTION_ID="$(az account show --query 'id' -o tsv)"

echo "❱❱❱ 🥣 Adding federated credentials to managed identity"
az identity federated-credential create --name "github" \
--identity-name "${IDENTITY_NAME}" \
--resource-group "${RES_GROUP}" \
--issuer "${OIDC_ISSUER}" \
--subject "${SUBJECT}" -o tsv --query 'id'

# add reader role to managed identity
echo "❱❱❱ 💪 Assigning subscription reader role to managed identity"
az role assignment create --role "Reader" --assignee "${MI_PRINCIPAL_ID}" \
--scope "/subscriptions/${SUBSCRIPTION_ID}" -o tsv --query 'updatedOn'

# add secrets to GitHub repo
echo "❱❱❱ 🔑 Adding secrets to GitHub repo"
gh secret set AZURE_SUB_ID -b "${SUBSCRIPTION_ID}"
gh secret set AZURE_CLIENT_ID -b "${MI_CLIENT_ID}"
gh secret set AZURE_TENANT_ID -b "${MI_TENANT}"
