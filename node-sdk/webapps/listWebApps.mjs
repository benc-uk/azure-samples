import * as AppService from '@azure/arm-appservice'
import { DefaultAzureCredential } from '@azure/identity'

import * as dotenv from 'dotenv'
dotenv.config()

const creds = new DefaultAzureCredential()
const client = new AppService.WebSiteManagementClient(creds, process.env.AZURE_SUBSCRIPTION_ID)

const planPages = await client.appServicePlans.list().byPage()
for await (let page of planPages) {
  for (const plan of page) {
    console.log('Plan: ', plan.name)
  }
}

const webappPages = await client.webApps.list().byPage()
for await (let page of webappPages) {
  for (const app of page) {
    console.log(`Web App: ${app.name} https://${app.defaultHostName}`)
  }
}
