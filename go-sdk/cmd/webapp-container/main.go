package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/Azure/azure-sdk-for-go/services/resources/mgmt/2018-05-01/resources"
	"github.com/Azure/azure-sdk-for-go/services/web/mgmt/2018-02-01/web"
	"github.com/Azure/go-autorest/autorest"
	"github.com/Azure/go-autorest/autorest/azure/auth"
	"github.com/Azure/go-autorest/autorest/to"
	"github.com/akamensky/argparse"
	"github.com/briandowns/spinner"
	"github.com/joho/godotenv"
)

var azureSubID string

func main() {
	godotenv.Load("../../.env")
	godotenv.Load(".env")
	azureSubID = os.Getenv("AZURE_SUBSCRIPTION_ID")

	parser := argparse.NewParser("webapp-container", "Deploy an Azure App Service web app container")
	appServiceName := parser.String("n", "name", &argparse.Options{Required: true, Help: "App Service web app name"})
	imageName := parser.String("i", "image", &argparse.Options{Required: true, Help: "Containter image to deploy to web app"})
	azureResGroup := parser.String("g", "group", &argparse.Options{Required: true, Help: "Azure resource group"})
	azureLocation := parser.String("l", "location", &argparse.Options{Required: true, Help: "Azure location / region"})

	err := parser.Parse(os.Args)
	if err != nil {
		fmt.Print(parser.Usage(err))
		os.Exit(1)
	}

	ctx, cancel := context.WithTimeout(context.Background(), time.Minute*10)
	defer cancel()

	//authorizer, err := auth.NewAuthorizerFromEnvironment()
	authorizer, err := auth.NewAuthorizerFromCLI()
	if err != nil {
		log.Fatal(err)
		return
	}

	// Create the resource group
	fmt.Println("### Creating Resource Group")
	resClient := resources.NewGroupsClient(azureSubID)
	resClient.Authorizer = authorizer
	_, err = resClient.CreateOrUpdate(
		ctx,
		*azureResGroup,
		resources.Group{
			Location: to.StringPtr(*azureLocation),
		})
	if err != nil {
		log.Fatal(err)
		return
	}

	// Create app service plan
	planID, err := CreateServicePlan(ctx, authorizer, *azureResGroup, *azureLocation, "app-service-plan")
	if err != nil {
		log.Fatal(err)
		return
	}

	// Deploy web app from container image into app service plan
	err = CreateWebAppContainer(ctx, authorizer, *azureResGroup, *azureLocation, *appServiceName, *imageName, planID)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("### Web App deployed at:", "http://"+*appServiceName+".azurewebsites.net/")
}

// CreateServicePlan - Create an Linux Azure App Service plan
// ==========================================================
func CreateServicePlan(ctx context.Context, authorizer autorest.Authorizer, resGroup, azureLocation, name string) (id *string, err error) {
	fmt.Println("### Creating Linux App Service Plan")
	spin := spinner.New(spinner.CharSets[14], 100*time.Millisecond)
	spin.Start()
	client := web.NewAppServicePlansClient(azureSubID)
	client.Authorizer = authorizer

	future, err := client.CreateOrUpdate(
		ctx,
		resGroup,
		name,
		web.AppServicePlan{
			Kind: to.StringPtr("linux"),
			Sku: &web.SkuDescription{
				Name:     to.StringPtr("B1"),
				Capacity: to.Int32Ptr(1),
			},
			Location: to.StringPtr(azureLocation),
			AppServicePlanProperties: &web.AppServicePlanProperties{
				Reserved: to.BoolPtr(true),
			},
		})
	if err != nil {
		return
	}

	err = future.WaitForCompletionRef(ctx, client.Client)
	if err != nil {
		return
	}
	spin.Stop()

	createdPlan, err := client.Get(ctx, resGroup, name)

	return createdPlan.ID, nil
}

// CreateWebAppContainer - Deploy web app and set it to run a container
// ====================================================================
func CreateWebAppContainer(ctx context.Context, authorizer autorest.Authorizer, resGroup, azureLocation, name, image string, planId *string) (err error) {
	fmt.Println("### Creating Container Web App from image", image)
	spin := spinner.New(spinner.CharSets[14], 100*time.Millisecond)
	spin.Start()
	client := web.NewAppsClient(azureSubID)
	client.Authorizer = authorizer

	futureSite, err := client.CreateOrUpdate(
		ctx,
		resGroup,
		name,
		web.Site{
			Location: to.StringPtr(azureLocation),
			SiteProperties: &web.SiteProperties{
				ServerFarmID: planId,
				SiteConfig: &web.SiteConfig{
					LinuxFxVersion: to.StringPtr(fmt.Sprintf("DOCKER|%s", image)),
				},
			},
		})
	if err != nil {
		return err
	}

	err = futureSite.WaitForCompletionRef(ctx, client.Client)
	if err != nil {
		return err
	}
	spin.Stop()

	return
}
