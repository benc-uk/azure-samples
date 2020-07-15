from azure.identity import DeviceCodeCredential
from msgraphcore import GraphSession
import os, json

# Keep secrets/config in .env file
from dotenv import load_dotenv
load_dotenv()

# Graph API scopes we need
scopes = ['User.Read', 'User.ReadBasic.All']

# Use device code flow as we're a console app
# Set CLIENT_ID in .env file before running
browser_credential = DeviceCodeCredential(client_id=os.environ['CLIENT_ID'])
graph_session = GraphSession(browser_credential, scopes)

# User search term
searchString="Ben C"

# Call graph with a search for users
result = graph_session.get(f"/users?$filter=startswith(displayName, '{searchString}') or startswith(userPrincipalName, '{searchString}')")

# Just dump JSON to stdout, obviously a real app would do something less dumb
print(json.dumps(result.json(), indent=2))