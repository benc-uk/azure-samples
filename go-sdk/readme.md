# Go SDK for Azure - Examples
Some raw/basic examples of using the Go SDK for Azure to deploy various resources  

These have been created/tested with Go v1.12 (using modules), I don't know or care if they work with older versions of Go before they introduced modules


## Usage
Create a `.env` file containing all your secrets and place it at the root of this project (i.e. above the `src` directory)
Optionally set these via environmental variables on your system though another means

Example file
```c
AZURE_TENANT_ID="your-tenant-id"
AZURE_SUBSCRIPTION_ID="your-tenant-id"
AZURE_CLIENT_ID="your-service-principal-id"
AZURE_CLIENT_SECRET="your-service-principal-secret-password"
```

## src/webapp
Deploy a Windows App Service Web App (and App Service Plan) and pulls code down from GitHub to deploy a fully functioning site

Takes four parameters
- Resource group name (will be created)
- Azure region location
- App Service site name
- Public Git URL (e.g. GitHub) to deploy to the new Web App

```
cd cmd/webapp
go run main.go myResGrp northeurope demosite2018 https://github.com/benc-uk/nodejs-demoapp.git
```

## src/webapp-container
Deploy a Linux App Service Web App (and App Service Plan) and pulls container image down from Dockerhub to deploy a fully functioning site

Takes four parameters
- Resource group name (will be created)
- Azure region location
- App Service site name
- Dockerhub public image, e.g. `nginx` or one from your own repo

```
cd cmd/webapp-container
go run main.go -g temp.myResGrp -l northeurope -n demosite22 -i bencuk/nodejs-demoapp
```