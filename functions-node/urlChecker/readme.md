# URL Checker & Email Alerter
This function checks a given URL on a schedule (default is every 10 minutes) checking the HTTP response code, and checking the context returned (e.g. HTML) for certain strings.

Alert notification emails will be sent when any of the checks you configure fail, i.e. string not found on page etc

Emails are sent using SendGrid, so a SendGrid API key is required, [but signup is free](https://signup.sendgrid.com/)


## App Settings
The function requires the following App Settings (env vars)

- `CHECK_URL` - The URL to fetch and check, if the HTTP response is not 200 the alert email will be sent
- `CHECK_FIND_STRING` - (optional) A string that is expected to be on the page, if not found the alert email will be sent
- `CHECK_NOT_FIND_STRING` - (optional) A string that is NOT expected to be on the page, if found the alert email will be sent
- `CHECK_EMAIL_TO` - Email address to send alert to
- `CHECK_EMAIL_FROM` - Email address alert will be sent from
- `SENDGRID_API_KEY` - Your SendGrid API key, with permission to send email

## Other config
Set the schedule and how often to run the check in `function.json` by changing the cron string in timerTrigger

