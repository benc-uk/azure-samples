import * as dotenv from 'dotenv'
dotenv.config()

import axios from 'axios'
import { DefaultAzureCredential } from '@azure/identity'

const creds = new DefaultAzureCredential()
const token = await creds.getToken('https://management.azure.com/')
const res = await axios.get(
  `https://management.azure.com/subscriptions/${process.env.AZURE_SUBSCRIPTION_ID}/providers/Microsoft.Web/sites?api-version=2019-08-01`,
  {
    headers: {
      Authorization: `Bearer ${token.token}`,
    },
  }
)

for (const app of res.data.value) {
  console.log(`Web App: ${app.name} https://${app.defaultHostName}`)
}
