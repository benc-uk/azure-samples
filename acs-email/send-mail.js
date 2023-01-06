// ================================================================
//
// Sample taken from https://docs.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email?pivots=programming-language-javascript
// Send email using the Azure Communication Services Email SDK
//
// ================================================================

const { EmailClient } = require('@azure/communication-email')
require('dotenv').config()

const connectionString = process.env.COMMUNICATION_SERVICES_CONNECTION_STRING

// Change these!
const domain = 'd51fdd01-2a9e-4a95-9cea-3e159c0e15ba.azurecomm.net'
const toEmail = 'benc.uk@gmail.com'

async function main() {
  try {
    var client = new EmailClient(connectionString)
    console.log(`### 📧 Email client created, will use domain ${domain}`)

    // Construct an email object to send
    const emailMessage = {
      sender: `<DoNotReply@${domain}>`,
      content: {
        subject: 'Test message from Azure Communication Services',
        plainText: 'This email message was sent from Azure Communication Service Email using the JS SDK',
      },
      recipients: {
        to: [
          {
            email: toEmail,
          },
        ],
      },
    }

    var response = await client.send(emailMessage)
    console.log(`### 📨 Email sent: ${response.messageId}`)
    const messageId = response.messageId

    // Loop and check status
    const statusInterval = setInterval(() => {
      let counter = 0
      checkStatus(client, messageId, statusInterval, counter)
    }, 1000)
  } catch (e) {
    console.log(`### 💥 ERROR! ${e.message}`)
    process.exit(2)
  }
}

// Check status of email and give up if is been sent or after 12 tries
async function checkStatus(client, messageId, statusInterval, counter) {
  counter++
  const response = await client.getSendStatus(messageId)
  if (response) {
    console.log(`### 📩 Email status for ${messageId}: ${response.status}`)
    if (response.status.toLowerCase() !== 'queued' || counter > 12) {
      clearInterval(statusInterval)
    }
  }
}

// Entry point is here!
main()
