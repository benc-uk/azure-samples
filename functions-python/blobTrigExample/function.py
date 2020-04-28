import logging
import json

import azure.functions as func

def main(myblob: func.InputStream):
  # Just logging 
  logging.info(f"### Python blob trigger function processed blob \n### Name: {myblob.name}\n### Blob Size: {myblob.length} bytes\n")

  # Read in the blob contents
  blobContents = myblob.read()

  # Unmarshall the JSON string into a dict
  data = json.loads(blobContents)

  # Results!
  logging.info(f"### Message in JSON blob was: {data['message']}\n")
  logging.info(f"### Count in JSON blob was: {data['count']}\n")