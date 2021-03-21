# Web Monitor

This function allows for the monitoring of a range of URLs and run checks against the result, such as scanning the content for strings, response times etc.  
Alert notification emails will be sent to when any of the checks you have configured for any of the URLs, are triggered.

# Pre-reqs

Emails are sent using SendGrid, so a SendGrid API key is required, [but signup is free](https://signup.sendgrid.com/)

# Configuration Environmental Variables

Required environmental variable / app settings

- `SENDGRID_API_KEY`: Your SendGrid API key

Optional environmental variable / app settings

- `WEBMONITOR_CONFIG` - Required when setting the monitor configuration without a config file, see below.
- `WEBMONITOR_DEBUG` - When set to 'true' HTTP response details will be logged to stdout, including response body.

# Monitor Config

Main monitor configuration is done one of two ways: Setting the `WEBMONITOR_CONFIG` environmentals variable, or with a `config.json` file. If both are available the environmental variable takes precedence. The config.json file method is easiest, however when deploying to an Azure Function, your deployed files are generally immutable in App Service/Azure Functions until you redeploy. If you expect to need to change the config often then use the app setting method.

When using `WEBMONITOR_CONFIG` variable / app setting, it should be a string holding a JSON stringify'ed valid JSON config (as shown below). This is a [simple online tool to stringify JSON](https://onlinetexttools.com/json-stringify-text)

Example of minimal config, which will check 'https://example.net' and sent any alerts to 'dave@example.net'

```json
{
  "emailTo": ["dave@example.net"],
  "checks": [
    {
      "url": "https://example.net"
    }
  ]
}
```

Full config reference

```text
{
  emailTo:         (REQUIRED) Array of email addresses to send alerts to
  emailFrom:       (optional) Email alerts will be sent from this address, default: 'webmonitor@benco.io'
  emailSubject:    (optional) Email subject, default: 'Web Monitor Alert!'
  headers:         (optional) Key value pairs added to HTTP request headers of all checks
  ignoreRedirects: (optional) Default is to follow redirects, set this to true to ignore them.
  checks: [
    {
      url:            (REQUIRED) URL to monitor and check
      statuses:       (optional) Array of HTTP status codes considered ok, default: [ 200 ]
      headers:        (optional) Key value pairs added to HTTP request headers of this check
      expect:         (optional) Check returned content looking for regex/string match
      dontExpect:     (optional) Check returned content, and regex/string should NOT match
      headerExpect:   (optional) Check returned headers looking for this regex/string
      contentSizeMin: (optional) Content length should be at least this number of bytes
      contentSizeMax: (optional) Content length should be less than this number of bytes
      responseTime:   (optional) Response time threshold in milli-seconds
    }
  ]
}
```

Note on uses of `expect`, `dontExpect` - these can be a simple text string to look for in the resulting body HTML or other content. They can also be a [regular expression](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions) for more advanced scanning

Example of a more complete config

```json
{
  "emailTo": ["dave@example.net", "bob@bob.com"],
  "emailFrom": "test@demo.com",
  "emailSubject": "Something bad happened!",
  "headers": {
    "user-agent": "web monitor v1.0"
  },
  "checks": [
    {
      "url": "https://example.net",
      "statuses": [202, 401],
      "expect": "Example Domain",
      "dontExpect": "Cheese cake",
      "contentSizeMin": 3000
    },
    {
      "url": "https://benc.io/api",
      "expect": "code: \\d+s", // Using regex
      "headers": {
        "Context-Type": "application/json"
      },
      "headerExpect": "\"connection\": \"close\"",
      "responseTime": 2000
    }
  ]
}
```

# Schedule Frequency

This is set in function.json in the `schedule` [cron style setting](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer?tabs=javascript) of the **scheduleTimer** binding

# Standalone Mode

The function can run outside of Azure Functions and without the Functions runtime.  
All the same environmental variables and config applies, in addition `WEBMONITOR_INTERVAL` sets the checking frequency in seconds (default 300), function.json is ignored

Start with

```bash
node standalone.js
```

A Dockerfile to build and run as a container is also provided
