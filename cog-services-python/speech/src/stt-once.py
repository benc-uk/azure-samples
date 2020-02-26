import time
import wave
import os
import sys
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

# Call the API with recognize_once, this only checks the first 15 seconds
# And returns the first "utterance"
result = speech_recognizer.recognize_once()

# Check the result
if result.reason == speechsdk.ResultReason.RecognizedSpeech:
  print("### Recognized: {}".format(result.text))
elif result.reason == speechsdk.ResultReason.NoMatch:
  print("### No speech could be recognized: {}".format(result.no_match_details))
elif result.reason == speechsdk.ResultReason.Canceled:
  cancellation_details = result.cancellation_details
  print("### Speech Recognition canceled: {}".format(cancellation_details.reason))
  if cancellation_details.reason == speechsdk.CancellationReason.Error:
    print("### Error details: {}".format(cancellation_details.error_details))
