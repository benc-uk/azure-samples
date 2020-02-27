import time
import wave
import os
import sys
import json
import azure.cognitiveservices.speech as speechsdk
from dotenv import load_dotenv

# Standard boilerplate for the cognitive API
load_dotenv()
API_KEY = os.getenv("API_KEY")
API_REGION = os.getenv("API_REGION")

if len(sys.argv) < 2:
  print("Please provide an input wav file name!")
  sys.exit(0)
input_file = sys.argv[1]

# Connect using the Microsoft hosted service
speech_config = speechsdk.SpeechConfig(
  speech_recognition_language='en-gb',
  subscription=API_KEY, 
  region=API_REGION
)

# Connect via hostname of container
# speech_config = speechsdk.SpeechConfig(
#   speech_recognition_language='en-gb',
#   host="http://localhost:5000"
# )

# The input file
audio_config = speechsdk.audio.AudioConfig(filename=input_file)

# Main recognizer object
speech_recognizer = speechsdk.SpeechRecognizer(
  speech_config=speech_config, 
  audio_config=audio_config
)

done = False

def stop_cb(evt):
  #print('### CLOSING')
  global done
  done = True

# Connect callbacks to the events fired by the speech recognizer
#speech_recognizer.recognized.connect(lambda evt: print('### RECOGNIZED: {}'.format(json.dumps(json.loads(evt.result.json), indent=4, sort_keys=True))))
speech_recognizer.recognized.connect(lambda evt: print('### RECOGNIZED: {}'.format(evt.result.text) ))
speech_recognizer.session_started.connect(lambda evt: print('### SESSION STARTED!\n'))
speech_recognizer.session_stopped.connect(lambda evt: print('### SESSION STOPPED!'))
speech_recognizer.canceled.connect(lambda evt: print('\n### CANCELED {}'.format(evt.cancellation_details)))
#speech_recognizer.recognizing.connect(lambda evt: print('### RECOGNIZING: {}'.format(evt.result.text)))

# Stop recognition on either session stopped or canceled events
#speech_recognizer.session_stopped.connect(stop_cb)
speech_recognizer.canceled.connect(stop_cb)

# Start continuous speech recognition, loop & sleep
speech_recognizer.start_continuous_recognition()

while not done:
  time.sleep(.5)

speech_recognizer.stop_continuous_recognition()