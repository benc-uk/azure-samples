import time
import wave
import os
import sys
import azure.cognitiveservices.speech as speechsdk
from dotenv import load_dotenv

# Change if you need
OUTPUT_FOLDER = "output"

# Standard boilerplate for the cognitive API
load_dotenv()
API_KEY = os.getenv("API_KEY")
API_REGION = os.getenv("API_REGION")

if len(sys.argv) < 2:
  print("Please provide an input text as argument")
  sys.exit(0)
input_text = sys.argv[1]

# Connect using the Microsoft hosted service
speech_config = speechsdk.SpeechConfig(
  speech_recognition_language='en-gb',
  subscription=API_KEY, 
  region=API_REGION
)

# Optional, set the voice
# Full list here https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/language-support#text-to-speech
voice = "en-GB-Susan-Apollo"
speech_config.speech_synthesis_voice_name = voice

# Connect via hostname of container
# speech_config = speechsdk.SpeechConfig(
#   speech_recognition_language='en-gb',
#   host="http://localhost:5000"
# )

import datetime
# Name output with timestamp
st = datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d_%H-%M-%S')
filename_out = os.path.join(OUTPUT_FOLDER, st+'.wav')

# The output file
audio_config = speechsdk.audio.AudioOutputConfig(filename=filename_out)

# Main SpeechSynthesizer object
speech_synth = speechsdk.SpeechSynthesizer(
  speech_config=speech_config, 
  audio_config=audio_config
)

result = speech_synth.speak_text(input_text)

# Check result
if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
  print("### Speech synthesized to speaker for text [{}] with voice [{}]".format(input_text, voice))
  print("### Results written to: " + filename_out)
elif result.reason == speechsdk.ResultReason.Canceled:
  cancellation_details = result.cancellation_details
  print("### Speech synthesis canceled: {}".format(cancellation_details.reason))
  if cancellation_details.reason == speechsdk.CancellationReason.Error:
    print("### Error details: {}".format(cancellation_details.error_details))

