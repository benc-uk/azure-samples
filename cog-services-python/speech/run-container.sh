# Parse the .env file as bash variables
eval $(egrep -v '^#' .env | xargs)

# Start container
docker run --rm -p 5000:5000 containerpreview.azurecr.io/microsoft/cognitive-services-speech-to-text:latest EULA=accept BILLING=https://$API_REGION.api.cognitive.microsoft.com APIKEY=$API_KEY
