package main

//
// Basic REST API that uses Azure SDK for Go to interact with Azure Storage
// Ben Coleman, 2022
//

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
	"github.com/gorilla/mux"

	_ "github.com/joho/godotenv/autoload" // Autoloads .env file if it exists
)

var version = "0.0.1" // App version number, set at build time with -ldflags "-X 'main.version=1.2.3'"

type SimpleAPI struct {
	blobClient *azblob.Client
}

//
// Main entry point, will start HTTP service
//
func main() {
	log.SetOutput(os.Stdout) // Personal preference on log output
	log.Printf("### Azure SDK storage example v%v starting...", version)

	// Port to listen on, change the default as you see fit
	serverPort := os.Getenv("PORT")
	if serverPort == "" {
		serverPort = "8000"
	}
	storageName := os.Getenv("AZURE_STORAGE_NAME")
	if storageName == "" {
		log.Fatalln("### FATAL: AZURE_STORAGE_NAME not set")
	}

	// Use DefaultAzureCredential to connect to Azure resources
	// See https://learn.microsoft.com/en-us/azure/developer/go/azure-sdk-authentication
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		log.Fatal(err)
	}
	// Create the shared blob client
	blobClient, err := azblob.NewClient(fmt.Sprintf("https://%s.blob.core.windows.net/", storageName), cred, nil)
	if err != nil {
		log.Fatal(err)
	}
	// Create the API object which will hold the blob client, and is passed to the routes
	api := &SimpleAPI{blobClient: blobClient}

	// Use gorilla/mux for routing
	router := mux.NewRouter()

	// Register our API routes
	router.HandleFunc("/", api.routeRoot).Methods("GET")
	router.HandleFunc("/list/{containerName}", api.routeListBlobs).Methods("GET")
	router.HandleFunc("/create/{containerName}/{blobName}", api.routeCreateBlob).Methods("POST")

	// Start the HTTP server
	log.Printf("### Server listening on %v\n", serverPort)
	err = http.ListenAndServe(fmt.Sprintf("0.0.0.0:%s", serverPort), router)
	if err != nil {
		log.Fatalln("### FATAL: Failed to start server:", err)
	}
}

//
// Simple root route, returns 200 OK
//
func (api *SimpleAPI) routeRoot(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("OK"))
}

//
// List blobs in a container, returns JSON
//
func (api *SimpleAPI) routeListBlobs(resp http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	containerName := vars["containerName"]

	// List all the blobs in the container
	pager := api.blobClient.NewListBlobsFlatPager(containerName, nil)
	for pager.More() {
		page, err := pager.NextPage(context.TODO())
		if err != nil {
			resp.WriteHeader(http.StatusInternalServerError)
			_, _ = resp.Write([]byte(fmt.Sprintf("Error listing blobs: %v", err)))
			return
		}

		// Build a JSON response
		blobs := []string{}
		for _, blob := range page.Segment.BlobItems {
			blobs = append(blobs, *blob.Name)
		}
		jsonResp, _ := json.Marshal(blobs)
		resp.Header().Set("Content-Type", "application/json")
		_, _ = resp.Write([]byte(jsonResp))

		log.Printf("### Listed blobs in: %s", containerName)
	}
}

//
// Create or update a blob using POST data
//
func (api *SimpleAPI) routeCreateBlob(resp http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	containerName := vars["containerName"]
	blobName := vars["blobName"]

	// get post body with ioutils
	body, err := ioutil.ReadAll(req.Body)
	if err != nil {
		resp.WriteHeader(http.StatusInternalServerError)
		_, _ = resp.Write([]byte(fmt.Sprintf("Error reading request body: %v", err)))
		return
	}

	// Create a new blob
	_, err = api.blobClient.UploadBuffer(context.TODO(), containerName, blobName, body, nil)
	if err != nil {
		resp.WriteHeader(http.StatusInternalServerError)
		_, _ = resp.Write([]byte(fmt.Sprintf("Error creating blob: %v", err)))
		return
	}

	log.Printf("### Created/updated blob: %s/%s", containerName, blobName)
	_, _ = resp.Write([]byte("Blob " + blobName + " was created/updated OK"))
}
