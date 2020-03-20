# ===== Build stage ========================================

# !GOTCHA! Must use Debian not Alpine image base!
FROM golang:1.14-buster as build
WORKDIR /build

COPY go.mod .
COPY *.go ./

# Build the HTTP hander executable 
RUN go build -o func-server

# ===== Runtime stage ======================================

# !GOTCHA! We use the node base image, even though we don't need node!
FROM mcr.microsoft.com/azure-functions/node:3.0

# !GOTCHA! Must use /home/site/wwwroot otherwise it doesn't work when deployed
WORKDIR /home/site/wwwroot

ENV AzureWebJobsScriptRoot=/home/site/wwwroot
ENV AzureFunctionsJobHost__Logging__Console__IsEnabled=true

# Copy in Functions and handler server executable
COPY host.json .
COPY helloFunction/ ./helloFunction
COPY resizeImageFunction/ ./resizeImageFunction
COPY fractalFunction/ ./fractalFunction
COPY --from=build build/func-server .