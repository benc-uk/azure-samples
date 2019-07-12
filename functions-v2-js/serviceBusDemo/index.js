module.exports = function(context, sbMessage) {
    context.log('JavaScript ServiceBus queue trigger function received message', sbMessage);

    context.log("### MESSAGE PAYLOAD JSON TEXT:  "+sbMessage.text);
    context.log("### MESSAGE PAYLOAD JSON VALUE: "+sbMessage.value);

    context.done();
};