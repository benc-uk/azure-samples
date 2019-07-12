from azure.cognitiveservices.vision.computervision import ComputerVisionClient
from azure.cognitiveservices.vision.computervision.models import VisualFeatureTypes
from msrest.authentication import CognitiveServicesCredentials
import os
import sys
import json
from dotenv import load_dotenv

# Standard boilerplate for the cognitive API
load_dotenv()
VISION_API_KEY = os.getenv("VISION_API_KEY")
VISION_API_REGION = os.getenv("VISION_API_REGION")

RAW_MODE = False # Change to True to get the raw JSON response and print it

if len(sys.argv) < 2:
  print("Please provide image file name!")
  sys.exit(0)

# Cognitive Services client 
client = ComputerVisionClient(endpoint=f"https://{VISION_API_REGION}.api.cognitive.microsoft.com/", 
  credentials=CognitiveServicesCredentials(VISION_API_KEY))

print(f"### Using API endpoint: {client.config.endpoint}")

# Open Image
img_file = sys.argv[1]
print(f"### Analyzing {img_file}")
image_file = open(img_file, "rb")

# VisualFeatureTypes can include other features to detect, check the docs
result = client.analyze_image_in_stream(image_file, raw=RAW_MODE, visual_features=[
  VisualFeatureTypes.description, 
  VisualFeatureTypes.tags,
  VisualFeatureTypes.color,  
  VisualFeatureTypes.faces])

if(RAW_MODE):
  print(json.dumps(result.response.json(), indent=2))
  exit(0)

# Print description
print(f"###\n### That looks like: {result.description.captions[0].text}\n###")

# Print tags
print("### Tags:")
for tag in result.tags:
  print(f" - {tag.name} {tag.confidence:.2f}")

# Print faces
print("### Faces:")
for face in result.faces:
  print(f" - {face.age} {face.gender}")

# Print colours
print("### Colors:")
print(f" - {result.color.dominant_colors}")


