import logging
import azure.functions as func

def main(event: func.EventHubEvent, outputblob: func.Out[func.InputStream]):
  logging.info('### Message received!')
  logging.info('DeviceId: ' + str(event.iothub_metadata['connection-device-id']))
  logging.info('Time: ' + str(event.iothub_metadata['enqueuedtime']))
  logging.info('SequenceNumber: ' + str(event.sequence_number))
  
  logging.info('=== START MESSAGE BODY ===')
  logging.info(event.get_body())
  logging.info('===  END MESSAGE BODY  ===')

  # Send to blob storage, dump the unmodified JSON payload
  outputblob.set(event.get_body())
  
