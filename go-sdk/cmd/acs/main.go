package main

import (
	"log"
	"os"

	"github.com/benc-uk/go-acs-email/client"
	_ "github.com/joho/godotenv/autoload"
)

const fromAddress = "DoNotReply@d51fdd01-2a9e-4a95-9cea-3e159c0e15ba.azurecomm.net"
const subject = "Test using Azure Email API"
const emailBody = "<h1>Hello!</h1>This email was sent using Go and the Azure Communication Services REST API"

func main() {
	endpoint := os.Getenv("ACS_ENDPOINT")
	accessKey := os.Getenv("ACS_ACCESS_KEY")
	if endpoint == "" || accessKey == "" {
		log.Fatal("Please set ACS_ENDPOINT and ACS_ACCESS_KEY")
	}
	log.Println("### Using ACS endpoint:", endpoint)

	acsClient := client.New(accessKey, endpoint)
	email := client.NewHTMLEmail(fromAddress, "benc.uk@gmail.com", subject, emailBody)

	msgID, err := acsClient.SendEmail(email)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("### Email was sent to '%s' with message ID: %s", email.Recipients.To[0].Email, msgID)
}
