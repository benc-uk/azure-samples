import requests
import time
import os
import sys
from dotenv import load_dotenv
from PIL import Image, ImageDraw

# Change if you need
OUTPUT_FOLDER = "output"

# Basic boilerplate for the API
load_dotenv()
VISION_API_KEY = os.getenv("VISION_API_KEY")
VISION_API_REGION = os.getenv("VISION_API_REGION")

if len(sys.argv) < 2:
  print("Please provide image file name!")
  sys.exit(0)

filename_in = os.path.join(sys.argv[1])
image_file = open(filename_in, "rb")
print("### Processing: " + filename_in)

# We need two API calls: One call to submit the image for processing, 
# - the other to retrieve the results once it is complete

headers = {
  'Ocp-Apim-Subscription-Key': VISION_API_KEY,
  'Content-Type': 'application/octet-stream'
}

# Change mode here!
params = {'mode': 'Printed'}
text_recognition_url = "https://" + VISION_API_REGION + ".api.cognitive.microsoft.com/vision/v2.0/read/core/asyncBatchAnalyze"
response = requests.post(text_recognition_url, headers=headers, params=params, data=image_file)
print("### Status Code: " + str(response.status_code))
response.raise_for_status()

# Holds the URI used to retrieve the recognized text.
operation_url = response.headers["Operation-Location"]

# The recognized text isn't immediately available, so poll to wait for completion.
analysis = {}
poll = True
while (poll):
    response_final = requests.get(
        response.headers["Operation-Location"], headers=headers)
    analysis = response_final.json()
    print("### Operation status: " + str(analysis["status"]))
    time.sleep(1)
    if ("recognitionResults" in analysis):
        poll= False 
    if ("status" in analysis and analysis['status'] == 'Failed'):
        poll= False

# Now output result image with red bounding boxes drawn over
source_img = Image.open(filename_in).convert("RGBA")
draw = ImageDraw.Draw(source_img)

if ("recognitionResults" in analysis):  
  for line in analysis["recognitionResults"][0]["lines"]:
    print("### Result line: " + line["text"]) # + " === " + str(line["boundingBox"]))
    draw.rectangle(((line["boundingBox"][0], line["boundingBox"][1]), (line["boundingBox"][4], line["boundingBox"][5])), outline="red", width=3)

import datetime
# Name output with timestamp
st = datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d_%H-%M-%S')
filename_out = os.path.join(OUTPUT_FOLDER, st+'.png')
source_img.save(filename_out, "PNG")
print("### Results written to: " + filename_out)
