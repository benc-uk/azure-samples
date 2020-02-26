from azure.cognitiveservices.vision.computervision import ComputerVisionClient
from azure.cognitiveservices.vision.computervision.models import VisualFeatureTypes
from msrest.authentication import CognitiveServicesCredentials
from dotenv import load_dotenv
import os
import sys
import datetime
import time
from PIL import Image, ImageDraw

# Change if you need
OUTPUT_FOLDER = "output"

# Standard boilerplate for the cognitive API
load_dotenv()
API_KEY = os.getenv("API_KEY")
API_REGION = os.getenv("API_REGION")

if len(sys.argv) < 2:
  print("Please provide image file name!")
  sys.exit(0)

# Cognitive Services client 
client = ComputerVisionClient(
  endpoint=f"https://{API_REGION}.api.cognitive.microsoft.com/", 
  credentials=CognitiveServicesCredentials(API_KEY)
)

print(f"### Using API endpoint: {client.config.endpoint}")

filename_in = os.path.join(sys.argv[1])
image_file = open(filename_in, "rb")
print(f"### Processing: {filename_in}")

result = client.recognize_printed_text_in_stream(image_file, language="en", detect_orientation=True)

print(f"### Result angle: {result.text_angle}, orientation: {result.orientation}, regions: {len(result.regions)}")

# Now output result image with bounding boxes drawn over
source_img = Image.open(filename_in).convert("RGBA")
draw = ImageDraw.Draw(source_img)

# Results are grouped by regions and then lines
#  - drawn bounding boxes and re-render output image
for region in result.regions:
  bbox = [int(n) for n in region.bounding_box.split(",")]
  draw.rectangle([bbox[0], bbox[1], bbox[0]+bbox[2], bbox[1]+bbox[3]], outline="green", width=3)
  for line in region.lines:
    bbox = [int(n) for n in line.bounding_box.split(",")]
    draw.rectangle([bbox[0], bbox[1], bbox[0]+bbox[2], bbox[1]+bbox[3]], outline="red", width=3)
    line_text = " ".join([word.text for word in line.words])
    print(f"  {line_text}")

# Name output with timestamp
st = datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d_%H-%M-%S')
filename_out = os.path.join(OUTPUT_FOLDER, f"{st}.png")
source_img.save(filename_out, "PNG")
print(f"### Results written to: {filename_out}")