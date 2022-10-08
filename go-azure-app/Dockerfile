#
# Stage 1: Build the Go app
#
FROM golang:1.18-alpine AS builder
ARG VERSION=1.0.0

WORKDIR /build
COPY * ./

RUN apk add --no-cache ca-certificates
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
  go build \
  -ldflags "-X 'main.version=${VERSION}'" \
  -o ./server

#
# Stage 2: Run the app
#
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/server /server
ENV PORT=8000
EXPOSE 8000
ENTRYPOINT ["/server"]
