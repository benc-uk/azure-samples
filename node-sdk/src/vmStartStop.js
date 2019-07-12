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
var resourceGroupName = "dummy";
var vmAction = "start";

if(process.argv.length < 4) {
  console.log("### Error! please provide both resource group name and VM action (start or stop)");
  process.exit(-1);
} else {
  resourceGroupName = process.argv[2];
  vmAction = process.argv[3];
}

//
// Main function 
// 
async function main() {
  // Login to Azure
  var credentials = await RestNodeAuth.loginWithServicePrincipalSecret(clientId, secret, domain);

  // New method to create ComputeManagementClient since June 2019 SDK update
  var computeClient = new ArmCompute.ComputeManagementClient(credentials, subscriptionId);

  // List all VMs in resource group
  var vmlist = await computeClient.virtualMachines.list(resourceGroupName);

  console.log(`### Found ${vmlist.length} VMs in group ${resourceGroupName}`);

  for (var vm of vmlist) {
    // We call await here so will synchronously run and wait for VM to start/stop
    // Remove await for async starting/stopping
    switch (vmAction) {
      case "start":
        console.log(`### Now starting ${vm.name}...`);
        var res = await computeClient.virtualMachines.start(resourceGroupName, vm.name);
        console.log(`### Status: ${res.status}`);
        break;
      case "stop":
        console.log(`### Now stopping ${vm.name}...`);
        var res = await computeClient.virtualMachines.deallocate(resourceGroupName, vm.name);
        console.log(`### Status: ${res.status}`);
        break;
      default:
        console.log(`### Invalid action specified, must be 'start' or 'stop'`);
    }
  }
}

//
// Entrypoint - It starts here...
//
main()
  .catch(err => { console.log(`### Error happened! ${err}`) })
