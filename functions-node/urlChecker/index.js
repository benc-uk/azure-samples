const HTTP = require('./http')

const URL = process.env.CHECK_URL || 'https://example.net'
const FIND_STRING = process.env.CHECK_FIND_STRING || ''
const NOT_FIND_STRING = process.env.CHECK_NOT_FIND_STRING || ''
const CHECK_EMAIL_TO = process.env.CHECK_EMAIL_TO || 'bob@bob.com'
const CHECK_EMAIL_FROM = process.env.CHECK_EMAIL_FROM || 'bob@bob.com'
const OK_STATUS = 200

main = async function (context, myTimer) {
  var timeStamp = new Date().toISOString()

  context.log(`### Page checker started ${timeStamp}`)

  if (!URL) {
    context.log(`### Page check skipped CHECK_URL is not set!`)
    context.done()
    return
  }

  context.log(`### Checking URL ${URL}`)
  context.log(`###  - Expecting '${FIND_STRING}' to be on the page`)
  context.log(`###  - Expecting '${NOT_FIND_STRING}' to NOT be on the page`)

  let response
  try {
    const client = new HTTP('', false, null, null, false)
    response = await client.get(URL)
  } catch (err) {
    console.log(`### ERROR! ${err}`)
    context.done()
    return
  }

  let httpStatusOK = true
  let findString = true
  let notFindString = true
  if (response.status != OK_STATUS) {
    httpStatusOK = false
  }
  if (httpStatusOK && FIND_STRING) {
    findString = response.data.includes(FIND_STRING)
  }
  if (httpStatusOK && NOT_FIND_STRING) {
    notFindString = !response.data.includes(NOT_FIND_STRING)
  }

  context.log(`### Page was ${response.data.length} bytes`)
  context.log(`### Check complete, httpStatusOK:${httpStatusOK} findString:${findString} notFindString:${notFindString}`)

  if (!(httpStatusOK && findString && notFindString)) {
    context.log(`### Check has failed, sending email notification to ${CHECK_EMAIL_TO}`)
    checkMessage = ``
    notCheckMessage = ``
    if (FIND_STRING && !findString) {
      checkMessage = `<p>Looked for '${FIND_STRING}' which was <b>NOT</b> found on the page!</p>`
    }
    if (NOT_FIND_STRING && !notFindString) {
      notCheckMessage = `<p>Expected '${NOT_FIND_STRING}' to not be on the page, but it <b>WAS</b> found'</p>`
    }

    context.bindings.message = {
      "personalizations": [{ "to": [{ "email": CHECK_EMAIL_TO }] }],
      from: { email: CHECK_EMAIL_FROM },
      subject: "URL Checker Failed!",
      content: [{
        type: 'text/html',
        value: `<h2>  Alert at ${timeStamp}<h2>
                <h3>URL check for ${URL} has failed. HTTP status was ${response.status}</h3>
                ${checkMessage}
                ${notCheckMessage}
                <br><p>Bye!</p>
                `
      }]
    }
  }

  context.done()
}

module.exports = main
