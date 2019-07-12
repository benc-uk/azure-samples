//
// Multi purpose Function.
// - Serves the camera single page "mobile app" (static HTML file)
// - Receives images from the camera app and saves them to blob storage 
//
module.exports = function (context, req) {
  context.log('JavaScript HTTP trigger function processed a request.');

  // If we get receive a GET, lets serve up a page of static HTML
  // This page is the HTML5/JS camera mini "app" that will POST photos back to this Function in Base64 format
  // NOTE. Serving static content like this from a Function, is a really hacky thing to do! Not best practice!
  if (req.method == 'GET') {
    context.log("### User requested camera app web page");

    // Look I told you this was a hack! I feel bad about this code now
    var cameraHtml = require('fs').readFileSync(__dirname+'/camera.html').toString();
    context.res.status = 200;
    context.res.headers['Content-Type'] = "text/html";
    context.res.body = cameraHtml;
  }

  // If we get a POST - it's an image being uploaded from the camera app
  // So... Base64 decode it and write to the outputBlob stream 
  if (req.method == 'POST') {
    context.log("### New image/photo uploaded, storing as blob");
    var buffer = new Buffer.from(req.body.toString(), 'base64');
    context.bindings.outputBlob = buffer;
    context.res.status = 200;
    context.res.body = "";
  }

  context.log("### Function complete");
  context.done();
};
