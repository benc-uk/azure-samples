//
// Photo analysis function using Azure Cognitive Service Vision API
//
const http = require('./simple-http.js');

const VISION_API_KEY = process.env.VISION_API_KEY;
const VISION_API_REGION = process.env.VISION_API_REGION || "westeurope"
const VISION_API_ENDPOINT = `https://${VISION_API_REGION}.api.cognitive.microsoft.com/vision/v1.0/analyze?visualFeatures=Categories,Tags,Description,Faces,ImageType,Color&details=Celebrities`;

module.exports = function (context, blobTrigger) {
  context.log("### New photo uploaded, starting analysis...");

  // Call cognitive service vision API
  // Post simple JSON object with the url of the image and put the key in the headers
  http.postJSON(
    VISION_API_ENDPOINT, 
    { url: context.bindingData.uri }, 
    { 'Ocp-Apim-Subscription-Key': VISION_API_KEY }
  )
  .then(resp => {
    context.log("### Cognitive API called successfully");
    context.log("### That looks a bit like: "+resp.description.captions[0].text);
    context.log("### Tags: "+JSON.stringify(resp.tags));

    // We want to inject the original image URL into our result object
    // Mutate the object and insert extra properties used by viewer app
    resp.srcUrl = context.bindingData.uri;
    resp.timestamp = new Date().getTime();
    resp.dateTime = new Date().toISOString();

    // Saving result to blob is very easy with Functions, we just assign the output variable
    // We need to convert the resp back to JSON string
    context.bindings.outputBlob = JSON.stringify(resp);
    context.done();
    context.log("### Function completed");
  })
  .catch(err => {
    // Error and general badness happened
    context.log("### Error! Cognitive API call failed!");
    context.log(err.message || "");
    context.done();    
  })
};