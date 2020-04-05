const storage = require('azure-storage');

module.exports = function (context, req) {
  const blobService = storage.createBlobService(process.env.AzureWebJobsStorage);

  deleteAll(context, blobService, 'photo-in');
  deleteAll(context, blobService, 'photo-out');

  context.res.status = 200;
  context.res.body = "DONE";
  context.done();
};

function deleteAll(context, svc, container) {
  context.log(`### Starting clean up of: ${container}`)
  svc.listBlobsSegmented(container, null, (err, res) => {
    if(err) return err;
    for(let blob of res.entries) {
      svc.deleteBlob(container, blob.name, (err, res) => {
        if(!err) context.log(`### ${blob.name} deleted from ${container}`)
      })
    }
  });
}