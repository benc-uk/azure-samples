//
// Standalone wrapper without the need for Functions runtime
//

// Import the main Function code
const runAllChecks = require('./index')
const HTTP = require('./http')

// Fake context object 
const ctx = {
  bindings: {},

  log(msg) {
    console.log(msg)
  },

  // Most of this code is to directly call SendGrid API rather than use Function output binding
  async done() {
    if (ctx.bindings && ctx.bindings.message) {
      console.log("### Standalone wrapper - calling SendGrid API")
      if (!process.env.SENDGRID_API_KEY) {
        console.log("### Error! SENDGRID_API_KEY is not set, unable to send email")
        return
      }
      //console.log(ctx.bindings.message.content[0].value)

      const sendGridEndpoint = 'https://sendgrid.com/v3'
      const client = new HTTP(sendGridEndpoint, false, { type: 'bearer', creds: process.env.SENDGRID_API_KEY }, null, false)
      try {
        const response = await client.post('/mail/send', ctx.bindings.message)
        if (!(response.status == 200 || response.status == 202)) {
          console.log(`### SendGrid Error! ${response.status} ${response.data}`)
        }
      } catch (err) {
        console.log(`### SendGrid Error! ${err}`)
        return
      }
    }
  }
}

// Run at startup
runAllChecks(ctx, null)

// Run on timer, configure with WEBMONITOR_INTERVAL
const INTERVAL = parseInt(process.env.WEBMONITOR_INTERVAL || "300") * 1000
setInterval(() => {
  ctx.bindings = {}
  runAllChecks(ctx, null)
}, INTERVAL)
