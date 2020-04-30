from azure.cosmos import CosmosClient, PartitionKey, exceptions
import os
from dotenv import load_dotenv
load_dotenv()

DATABASE_NAME = 'testDb'
CONTAINER_NAME = 'products'
COSMOS_URL = os.environ['COSMOS_URL']
COSMOS_KEY = os.environ['COSMOS_KEY']

client = CosmosClient(COSMOS_URL, credential=COSMOS_KEY)

try:
  database = client.create_database(DATABASE_NAME)
except exceptions.CosmosResourceExistsError:
  database = client.get_database_client(DATABASE_NAME)

print(f"### Connected to {client.client_connection.url_connection}/{database.id}")

try:
  container = database.create_container(id=CONTAINER_NAME, partition_key=PartitionKey(path="/productName"))
except exceptions.CosmosResourceExistsError:
  container = database.get_container_client(CONTAINER_NAME)
except exceptions.CosmosHttpResponseError:
  raise

container_client  = database.get_container_client(CONTAINER_NAME)

for i in range(1, 10):
  container_client.upsert_item({
      'id': 'item{0}'.format(i),
      'productName': 'Widget',
      'productModel': 'Model {0}'.format(i)
    }
  )
  print(f"### Inserted data 'item{i}' into {CONTAINER_NAME}")
