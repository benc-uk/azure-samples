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

	parser := argparse.NewParser("webapp-git", "Deploy an Azure App Service and deploy a git repo to it")
	appServiceName := parser.String("n", "name", &argparse.Options{Required: true, Help: "App Service web app name"})
	gitRepoURL := parser.String("r", "repo", &argparse.Options{Required: true, Help: "Git repository URL"})
	azureResGroup := parser.String("g", "group", &argparse.Options{Required: true, Help: "Azure resource group"})
	azureLocation := parser.String("l", "location", &argparse.Options{Required: true, Help: "Azure location / region"})

	err := parser.Parse(os.Args)
	if err != nil {
		fmt.Print(parser.Usage(err))
		os.Exit(1)
	}

	ctx, cancel := context.WithTimeout(context.Background(), time.Minute*10)
	defer cancel()

	authorizer, err := auth.NewAuthorizerFromEnvironment()
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

	planID, err := CreateServicePlan(ctx, authorizer, *azureResGroup, *azureLocation, "app-service-plan")
	if err != nil {
		log.Fatal(err)
		return
	}
	fmt.Println("### App Service Plan:", *planID)

	err = CreateWebAppFromGit(ctx, authorizer, *azureResGroup, *azureLocation, *appServiceName, *gitRepoURL, planID)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("### Web App fully deployed at:", "http://"+*appServiceName+".azurewebsites.net/")
}

// CreateServicePlan - Create an Azure App Service plan
// ====================================================
func CreateServicePlan(ctx context.Context, authorizer autorest.Authorizer, resGroup, azureLocation, name string) (id *string, err error) {
	fmt.Println("### Creating App Service Plan")
	spin := spinner.New(spinner.CharSets[14], 100*time.Millisecond)
	spin.Start()
	client := web.NewAppServicePlansClient(azureSubID)
	client.Authorizer = authorizer

	aspFuture, err := client.CreateOrUpdate(
		ctx,
		resGroup,
		name,
		web.AppServicePlan{
			Sku: &web.SkuDescription{
				Name:     to.StringPtr("B1"),
				Capacity: to.Int32Ptr(1),
			},
			Location: to.StringPtr(azureLocation),
		})
	if err != nil {
		return
	}

	err = aspFuture.Future.WaitForCompletionRef(ctx, client.Client)
	if err != nil {
		return
	}
	spin.Stop()

	createdPlan, err := client.Get(ctx, resGroup, name)

	return createdPlan.ID, nil
}

// CreateWebAppFromGit - Create an Azure App Service web app and deploy to it from Git
// ===================================================================================
func CreateWebAppFromGit(ctx context.Context, authorizer autorest.Authorizer, resGroup, azureLocation, name, gitRepoURL string, planID *string) (err error) {
	fmt.Println("### Creating Web App")
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
				ServerFarmID: planID,
			},
		})
	if err != nil {
		return err
	}

	err = futureSite.Future.WaitForCompletionRef(ctx, client.Client)
	if err != nil {
		return err
	}
	spin.Stop()

	fmt.Println("### Deploying app from Git:", gitRepoURL)
	fmt.Println("### This might take a couple of minutes...")
	spin.Start()
	futureSrc, err := client.CreateOrUpdateSourceControl(
		ctx,
		resGroup,
		name,
		web.SiteSourceControl{
			SiteSourceControlProperties: &web.SiteSourceControlProperties{
				RepoURL:             &gitRepoURL,
				Branch:              to.StringPtr("master"),
				IsManualIntegration: to.BoolPtr(true),
			},
		})

	err = futureSrc.Future.WaitForCompletionRef(ctx, client.Client)
	if err != nil {
		return err
	}
	spin.Stop()

	return
}
