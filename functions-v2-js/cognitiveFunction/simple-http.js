/*
  Simple compact HTTP library in vanilla Node.js 8.x
  Ben Coleman, Oct 2018
*/

// HTTP GET request without options
const getUrl = function(url) {
  let req = require('url').parse(url);
  return httpClient(req);
};

// HTTP GET request for JSON API resources
const getJSON = function(url, headers = {}) {
  let req = require('url').parse(url);
  req.headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}
  Object.assign(req.headers, headers);
  return httpClient(req)
    .then((resp) => {return JSON.parse(resp)})
};

// HTTP POST request for JSON API resources
const postJSON = function(url, data, headers = {}) {
  let req = require('url').parse(url);
  req.headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}
  Object.assign(req.headers, headers);
  req.method = 'POST';
  return httpClient(req, typeof data == 'object' ? JSON.stringify(data) : data)
    .then((resp) => {return JSON.parse(resp)})
};

// Generic HTTP request with full control
const httpClient = function(req, sendbody = null) {
  return new Promise((resolve, reject) => {
    const lib = req.protocol && req.protocol.startsWith('https') ? require('https') : require('http');
    const request = lib.request(req, (response) => {
      if (response.statusCode < 200 || response.statusCode > 299) {
        reject(new Error('Failed to load page, status code: ' + response.statusCode));
      }
      let body = [];
      response.on('data', (chunk) => body.push(chunk));
      response.on('end', () => resolve(body.join('')));
    });
    request.on('error', (err) => reject(err));
    if(sendbody) request.write(sendbody);
    request.end();
  })
};

module.exports.httpClient = httpClient;
module.exports.getUrl = getUrl,
module.exports.getJSON = getJSON,
module.exports.postJSON = postJSON

/*
// Example 1
getUrl('http://benco.io/')
  .then((resp) => console.log(resp))
  .catch((err) => console.error(err));

//Example 2
httpClient({ hostname: 'example.net' })
  .then((resp) => console.log(resp))
  .catch((err) => console.error(err));

// JSON get example
getJSON('https://postman-echo.com/get?foo1=bar1&foo2=bar2')
.then(r => console.log(r))

// JSON post example
postJSON('https://postman-echo.com/post', {foo: 'bar', baz: 42}, {'header1': 'goats'})
.then(r => console.log(r))
*/