# ===== Build stage ========================================

# Must use Debian not Alpine image base
FROM golang:1.14-buster as build
WORKDIR /build

COPY go.mod .
COPY *.go ./
RUN go build -o func-server

# ===== Runtime stage ======================================

# We use the node base image, even though we don't need node!
FROM mcr.microsoft.com/azure-functions/node:3.0
WORKDIR /functions

ENV AzureWebJobsScriptRoot=/functions
ENV AzureFunctionsJobHost__Logging__Console__IsEnabled=true

COPY host.json .
COPY helloFunction/ ./helloFunction
COPY resizeImageFunction/ ./resizeImageFunction
COPY fractalFunction/ ./fractalFunction
COPY --from=build build/func-server .