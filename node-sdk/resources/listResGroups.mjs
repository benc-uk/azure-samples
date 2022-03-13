import * as AzureResources from '@azure/arm-resources'
import { DefaultAzureCredential } from '@azure/identity'

import * as dotenv from 'dotenv'
dotenv.config()

const creds = new DefaultAzureCredential()
const client = new AzureResources.ResourceManagementClient(creds, process.env.AZURE_SUBSCRIPTION_ID)

const resGroupPages = await client.resourceGroups.list().byPage()
for await (let page of resGroupPages) {
  for (const rg of page) {
    console.log(`Resource group: ${rg.name}`)
  }
}
