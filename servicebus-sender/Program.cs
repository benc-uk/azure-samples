using System;
using Microsoft.Azure.ServiceBus;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Dynamic;
using System.Collections.Generic;

namespace ServicebusSender
{
    class Program
    {
        static IQueueClient queueClient;

        static void Main(string[] args)
        {
            DotNetEnv.Env.Load();

            string serviceBusConnectionString = System.Environment.GetEnvironmentVariable("SB_CONN_STRING");
            string queueName = System.Environment.GetEnvironmentVariable("SB_QUEUE");
            int batchCount = Int32.Parse(System.Environment.GetEnvironmentVariable("BATCH_COUNT"));
            int batchSize = Int32.Parse(System.Environment.GetEnvironmentVariable("BATCH_SIZE"));
            
            queueClient = new QueueClient(serviceBusConnectionString, queueName);

			// Send the messages to the queue
            for(var b = 0; b < batchCount; b++) {
                System.Console.WriteLine("=== Sending batch of {0} messages to service bus queue: {1}...", batchSize, queueName);
                SendMessagesAsync(batchSize).GetAwaiter().GetResult();
            }
        }

        static async Task SendMessagesAsync(int batchSize)
        {
            List<Message> messageBatch = new List<Message>();

            var rand = new Random();

            try {
                for(var m = 0; m < batchSize; m++) {
                    dynamic product = new ExpandoObject();
                    product.ProductName = "Lemon Curd";
                    product.Enabled = true;
                    product.StockCount = rand.Next(4000);
                    product.Tags = new[] {"foo", "bar", "baz"};

                    var message = new Message(Encoding.UTF8.GetBytes(Newtonsoft.Json.JsonConvert.SerializeObject(product)));
                    message.ContentType = "application/json";
                    messageBatch.Add(message);
                }
                
                await queueClient.SendAsync(messageBatch);            
            } catch (System.Exception e) {
                System.Console.WriteLine("!!! Exception: {0}", e.Message);
            }
        }
    }
}
