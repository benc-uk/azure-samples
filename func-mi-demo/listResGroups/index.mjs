import * as AzureResources from '@azure/arm-resources'
import { DefaultAzureCredential, ManagedIdentityCredential } from '@azure/identity'

export default async function (context, req) {
  if (!process.env.AZURE_SUBSCRIPTION_ID) {
    context.res = {
      status: 400,
      body: 'ERROR! AZURE_SUBSCRIPTION_ID is not set! 😩',
    }
    return
  }

  let creds
  if (process.env.MI_CLIENT_ID) {
    context.log('Attempting to using MSI, with client: ', process.env.MI_CLIENT_ID)
    creds = new ManagedIdentityCredential(process.env.MI_CLIENT_ID)
  } else {
    // This will use system assigned managed identity or Azure CLI creds if available
    creds = new DefaultAzureCredential()
  }

  if (!creds) {
    context.res = {
      status: 400,
      body: 'Failed to get credentials',
    }
    return
  }

  const client = new AzureResources.ResourceManagementClient(creds, process.env.AZURE_SUBSCRIPTION_ID)

  let htmlOut = `<html><body><h1>Resource Groups in subscription: ${process.env.AZURE_SUBSCRIPTION_ID}</h1><ul>`
  let status = 200
  try {
    const resGroupPages = await client.resourceGroups.list().byPage()
    for await (let page of resGroupPages) {
      for (const rg of page) {
        htmlOut += `<li>Resource group: ${rg.name}</li>`
      }
    }
  } catch (err) {
    context.log(err)
    htmlOut += `<li>ERROR: ${err}</li>`
    status = 500
  }

  htmlOut += `</ul></body></html>`
  context.res = {
    headers: {
      'Content-Type': 'text/html',
    },
    status: status,
    body: htmlOut,
  }
}
