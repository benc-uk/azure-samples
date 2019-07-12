const parse = require('csv-parse');

module.exports = function (context, triggerBlob) {
  context.log(`### Processing input file: ${context.bindingData.name} Size:${triggerBlob.length} bytes`);

  // Parse CSV and process each record/row
  parse(triggerBlob.toString(), { columns: true, trim: true, skip_empty_lines: true }, (err, records) => {
    if(!err) {
      context.log(`### CSV parsed, with ${records.length} records`);

      // Loop through records and create a message batch 
      context.bindings.outputQueue = [];
      for(let record of records) {
        context.bindings.outputQueue.push(JSON.stringify(record))
      }

      context.log("### Function complete, sending record messages to queue");
      context.done();
    } else {
      context.log("### CSV parse error!", err);
      context.done();
    }
  })
};