# Deploy Minecraft Server in Azure

Using [Azure Cloud Shell](https://shell.azure.com) you can deploy a Minecraft server as a Container Instance

Pick the resource group, region and server name. Server name must be unique and a valid DNS name (no spaces or dots etc).  
Run directly using this command
```
curl -s https://raw.githubusercontent.com/benc-uk/azure-samples/master/azure-cli/minecraft-server.sh | bash -s "RESGRP" "REGION" "SERVERNAME"
```

It deploys the Bedrock server by default, if you want the Java edition pass one extra parameter `itzg/minecraft-server`
