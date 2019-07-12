module.exports = async function (context, inputQueueMessage) {
    context.log('### Convert job picked off queue...');
    context.bindings.outputBlob = JSON.stringify(inputQueueMessage, null, 2);
    context.log('### Saved message as JSON blob');
};