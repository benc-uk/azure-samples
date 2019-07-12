// We use dotenv to keep all secrets in, it's great
require('dotenv').config()

const RestNodeAuth = require('@azure/ms-rest-nodeauth');
const ArmCompute = require("@azure/arm-compute");

// I used a .env file to keep these secret
var clientId = process.env['CLIENT_ID'];
var domain = process.env['DOMAIN'];
var secret = process.env['APPLICATION_SECRET'];
var subscriptionId = process.env['AZURE_SUBSCRIPTION_ID'];

console.log(`### Logging into ${domain}...`);

// Change these as needed
var resourceGroupName = "MC_Demo.AKS_aksnew_westeurope";
var vmssName = "aks-nodepool1-40534889-vmss"

//
// Main function 
// 
async function main() {
  var credentials = await RestNodeAuth.loginWithServicePrincipalSecret(clientId, secret, domain);
  var computeClient = new ArmCompute.ComputeManagementClient(credentials, subscriptionId);

  console.log(`### Shutting down VMSS ${vmssName}...`);
  var res = await computeClient.virtualMachineScaleSets.deallocate(resourceGroupName, vmssName);
  console.log(res);
}

//
// Entrypoint - It starts here...
//
main()
  .catch(err => { console.log(`### Error happened! ${err}`) })
