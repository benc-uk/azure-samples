//
// Web Monitor v1.0.0
// Monitors one or more URLs and checking the results in a number of ways, then sends alert emails
// Ben Coleman, 2020 (MIT License)
//

const HTTP = require('./http')

//
// Main entry point, which loads config & runs all URL checks
//
async function runAllChecks(context, scheduleTimer) {
  let timeStamp = new Date().toUTCString()
  context.log(`### Web Monitor checks starting ${timeStamp}`)

  // Handle loading the config, die if we can't get config
  let config
  try {
    config = parseConfig()
  } catch (err) {
    throw `### ERROR! Failed to load config - ${err}`
  }

  context.log(`### Config loaded with ${config.checks.length} URL checks`)
  // Debug
  if (process.env.WEBMONITOR_DEBUG === "true") {
    context.log(`### DEBUG: Config: ${JSON.stringify(config, null, 1)}`)
  }

  let sendEmail = false   // Set if any checks fail
  let emailMessages = ''  // String appended with each failed check message
  for (let check of config.checks) {
    try {
      const message = await checkURL(check, context, config.ignoreRedirects, config.headers)
      if (message) {
        sendEmail = true
        emailMessages += `<li>&#x1F4A5; ${check.url} - ${message}</li>`
      }
    } catch (err) {
      sendEmail = true
      emailMessages += `<li>&#x1F4A3; HTTP error with ${check.url} - ${err}</li>`
    }
  }

  if (sendEmail) {
    context.log(`### One or more URL checks has triggered, sending email notification to ${config.emailTo}`)

    context.bindings.message = {
      personalizations: config.emailTo.map(e => {
        return {
          to: [{ email: e }],
          subject: config.emailSubject
        }
      }),
      from: { email: config.emailFrom },
      content: [{
        type: 'text/html',
        value: `<h3>&#x1F525; ${timeStamp} - One or more URL checks has triggered</h3><ul>${emailMessages}</ul><br><p>Simple Web Monitor - Ben Coleman, 2020<br>https://github.com/benc-uk/azure-samples/tree/master/functions-node/webMonitor/</p>`
      }]
    }
  }

  context.done()
}

//
// Make HTTP request for URL and run checks
//
async function checkURL(check, context, ignoreRedirects, globalHeaders) {
  if (!check || !check.url) throw "Check is missing URL!"
  if (!check.statuses) check.statuses = [200]

  if (check.disabled) {
    context.log(`### Skipping: ${check.url}`)
    return
  }

  context.log(`### Checking: ${check.url}`)

  // Use simple HTTP client (see http.js) to make request
  // Add any global headers (for all requests)
  const client = new HTTP('', false, null, globalHeaders, false)
  const startTime = Date.now()

  // Make the HTTP request, with any additional check level headers
  let response = await client.get(check.url, check.headers)

  // Handle redirects, which is the default unless ignoreRedirects is set
  if (!ignoreRedirects && (response.status == 301 || response.status == 302)) {
    context.log(` - Following redirect to ${response.headers.location}`)
    response = await client.get(response.headers.location, check.headers)
  }
  const endTime = Date.now()

  // Debug
  if (process.env.WEBMONITOR_DEBUG === "true") {
    context.log(`### DEBUG: Status: ${response.status}`)
    context.log(`### DEBUG: Headers: ${JSON.stringify(response.headers, null, 1)}`)
    context.log('### DEBUG: Content: ')
    context.log(response.data)
    // if (!fs.existsSync(`${__dirname}/debug/`)) { fs.mkdirSync(`${__dirname}/debug`) }
    // const fn = check.url.replace(/https?:\/\//g, "").replace(/\//g, ":")
    // fs.writeFileSync(`${__dirname}/debug/${fn}.log`, `${response.status}\n\n${JSON.stringify(response.headers, null, 1)}\n\n${response.data}`)
  }

  // Check status code
  let msg = ''
  const statusOK = check.statuses.includes(response.status)
  if (!statusOK) {
    msg = `The HTTP status code '${response.status}' wasn't one of: ${check.statuses}`
    context.log(`### - ${msg}`)
    return msg
  }

  // Look for expected content
  if (check.expect) {
    let re = new RegExp(check.expect, 'gms')
    if (response.data.search(re) == -1) {
      msg = `Expected to find '${check.expect}' in content, but it was not found`
      context.log(`### - ${msg}`)
      return msg
    }
  }

  // Look for regex not wanted in content
  if (check.dontExpect) {
    let re = new RegExp(check.dontExpect, 'gms')
    if (response.data.search(re) != -1) {
      msg = `The regex '${check.dontExpect}' found in content, but it was not expected`
      context.log(`### - ${msg}`)
      return msg
    }
  }

  // Scan headers for regex
  if (check.headerExpect) {
    let re = new RegExp(check.headerExpect)
    const headers = JSON.stringify(response.headers)
    if (headers.search(re) == -1) {
      msg = `Response HTTP headers did not contain '${check.headerExpect}'`
      context.log(`### - ${msg}`)
      return msg
    }
  }

  // Check content size minimum
  if (check.contentSizeMin) {
    if (response.data.length < check.contentSizeMin) {
      msg = `Response content was ${response.data.length} bytes, below the threshold of: ${check.contentSizeMin} bytes`
      context.log(`### - ${msg}`)
      return msg
    }
  }

  // Check content size maximum
  if (check.contentSizeMax) {
    if (response.data.length > check.contentSizeMax) {
      msg = `Response content was ${response.data.length} bytes, over the threshold of: ${check.contentSizeMax} bytes`
      context.log(`### - ${msg}`)
      return msg
    }
  }

  // Check response time in milli-seconds
  if (check.responseTime) {
    const time = endTime - startTime
    if (time > check.responseTime) {
      msg = `Response time of ${time}ms exceeded the threshold of ${check.responseTime}ms`
      context.log(`### - ${msg}`)
      return msg
    }
  }

  return null
}

//
// Parse config and trap errors, set defaults
// Both WEBMONITOR_CONFIG env var and config.json file can be used
//
function parseConfig() {
  let config
  if (process.env.WEBMONITOR_CONFIG) {
    // Strip escaped newlines
    let configString = process.env.WEBMONITOR_CONFIG.replace(/\\n/g, "\n")
    //console.log(configString)
    config = JSON.parse(configString)
  } else {
    config = require('./config.json')
  }

  if (!config.emailTo) throw "emailTo missing from config"
  if (!Array.isArray(config.emailTo) || !config.emailTo.length > 0) throw "emailTo should be an array with at least one element"
  if (!config.emailFrom) config.emailFrom = "webmonitor@benco.io"
  if (!config.emailSubject) config.emailSubject = "Web Monitor Alert!"
  if (!config.headers) config.headers = {}

  if (!config.checks || config.checks.length == 0) throw "Need at least one check"

  return config
}

module.exports = runAllChecks