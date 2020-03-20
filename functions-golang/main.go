package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/benc-uk/gofract/pkg/colors"
	"github.com/benc-uk/gofract/pkg/fractals"
	"github.com/disintegration/imaging"
)

//
//
//
func main() {
	httpInvokerPort, exists := os.LookupEnv("FUNCTIONS_HTTPWORKER_PORT")

	if exists {
		log.Println("### FUNCTIONS_HTTPWORKER_PORT: " + httpInvokerPort)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/helloFunction", helloFunctionHandler)
	mux.HandleFunc("/resizeImageFunction", resizerFunctionHandler)
	mux.HandleFunc("/fractalFunction", fractalFunctionHandler)

	log.Println("### Function handler server started on port:", httpInvokerPort)

	err := http.ListenAndServe(fmt.Sprintf(":%v", httpInvokerPort), mux)
	if err != nil {
		panic(err.Error())
	}
}

//
// Simple HTTP echo test
//
func helloFunctionHandler(resp http.ResponseWriter, req *http.Request) {
	body := "none"
	if req.Method == "POST" {
		bodyBytes, err := ioutil.ReadAll(req.Body)
		if err == nil {
			body = string(bodyBytes)
		}
	}

	log.Println("### helloFunctionHandler invoked, for HTTP route /helloFunction")
	uaParts := strings.Split(req.Header.Get("User-Agent"), " ")
	funcRuntimeVer := uaParts[len(uaParts)-1]

	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	respData := map[string]string{
		"Method":       req.Method,
		"Message":      "Hello from Go running in Azure Functions!",
		"Timestamp":    time.Now().Local().String(),
		"FuncRuntime":  funcRuntimeVer,
		"InvocationID": req.Header.Get("X-Azure-Functions-InvocationId"),
		"Hostname":     hostname,
		"Body":         body,
	}

	jsonResp, err := json.Marshal(respData)
	if err != nil {
		http.Error(resp, err.Error(), http.StatusInternalServerError)
		return
	}

	resp.Header().Set("Content-Type", "application/json")
	resp.Write(jsonResp)
}

//
// Resize images from blob storage back into blob storage
//
func resizerFunctionHandler(resp http.ResponseWriter, req *http.Request) {
	log.Println("### resizerFunctionHandler invoked, for HTTP route /resizeImageFunction")

	// Step 1. Decode the HTTP payload as JSON into a FunctionsInvokeRequest
	var invokeRequest FunctionsInvokeRequest
	decoder := json.NewDecoder(req.Body)
	err := decoder.Decode(&invokeRequest)
	if err != nil {
		log.Println("### ERROR! invoke request decode " + err.Error())
		http.Error(resp, err.Error(), http.StatusInternalServerError)
		return
	}

	// Step 2. Get the inputBlob trigger data, it will be base64 encoded
	// Decode that into a byte array
	imageBytes, err := base64.StdEncoding.DecodeString(invokeRequest.Data["inputBlob"])
	if err != nil {
		log.Println("### ERROR! base64 decode " + err.Error())
		http.Error(resp, err.Error(), http.StatusInternalServerError)
		return
	}

	// Step 3. Decode the image bytes into a image.Image
	// Using base image library, it should support PNG and JPEG
	image, imageType, err := image.Decode(bytes.NewReader(imageBytes))
	if err != nil {
		log.Println("### ERROR! image decode " + err.Error())
		http.Error(resp, err.Error(), http.StatusInternalServerError)
		return
	}

	// Step 4. Resize into a new 200 pixel wide image.Image (keeping aspect ratio)
	// Using https://github.com/disintegration/imaging
	outImageThumb := imaging.Resize(image, 200, 0, imaging.Lanczos)

	// Step 5. Convert resized output image into a byte array
	outImageBuffer := new(bytes.Buffer)
	_ = jpeg.Encode(outImageBuffer, outImageThumb, nil)
	outImageBytes := outImageBuffer.Bytes()

	// Step 6. Build output response FunctionsInvokeResponse struct
	// This holds our output data associated with the named output binding
	invokeResponse := FunctionsInvokeResponse{
		Logs: []string{
			fmt.Sprintf("Input image name: %v", invokeRequest.Metadata.Name),
			fmt.Sprintf("Input image type: %v", imageType),
			fmt.Sprintf("Input image dimensions: %v,%v", image.Bounds().Max.X, image.Bounds().Max.Y),
			fmt.Sprintf("Output image size: %v bytes", len(outImageBytes)),
		},
		Outputs: map[string]interface{}{
			"outputBlob": outImageBytes,
		},
	}

	// Step 7. Marshall output response into JSON
	invokeResponseJSON, err := json.Marshal(invokeResponse)
	if err != nil {
		http.Error(resp, err.Error(), http.StatusInternalServerError)
		return
	}

	// Finally! Send HTTP response back...
	resp.Header().Set("Content-Type", "application/json")
	resp.Write(invokeResponseJSON)
}

func fractalFunctionHandler(resp http.ResponseWriter, req *http.Request) {
	width, err := strconv.Atoi(req.URL.Query().Get("width"))
	if err != nil {
		width = 1200
	}
	zoom, err := strconv.ParseFloat(req.URL.Query().Get("zoom"), 64)
	if err != nil {
		zoom = 1.0
	}
	i, err := strconv.ParseFloat(req.URL.Query().Get("i"), 64)
	if err != nil {
		i = -0.6
	}
	r, err := strconv.ParseFloat(req.URL.Query().Get("r"), 64)
	if err != nil {
		r = 0.0
	}
	iters, err := strconv.ParseFloat(req.URL.Query().Get("iters"), 64)
	if err != nil {
		iters = 100
	}

	fractal := fractals.Fractal{
		FractType:    "mandelbrot",
		Center:       fractals.ComplexPair{i, r},
		MagFactor:    zoom,
		MaxIter:      iters,
		W:            3.0,
		H:            2.0,
		ImgWidth:     width,
		JuliaSeed:    fractals.ComplexPair{0.355, 0.355},
		InnerColor:   "#000000",
		FullScreen:   false,
		ColorRepeats: 2.0,
	}

	gradient := colors.GradientTable{}
	gradient.AddToTable("#000762", 0.0)
	gradient.AddToTable("#0B48C3", 0.2)
	gradient.AddToTable("#ffffff", 0.4)
	gradient.AddToTable("#E3A000", 0.5)
	gradient.AddToTable("#000762", 0.9)

	imgHeight := int(float64(fractal.ImgWidth) * float64(fractal.H/fractal.W))
	image := image.NewRGBA(image.Rect(0, 0, fractal.ImgWidth, imgHeight))

	fractal.Render(image, gradient)

	outImageBuffer := new(bytes.Buffer)
	_ = png.Encode(outImageBuffer, image)
	outImageBytes := outImageBuffer.Bytes()

	resp.Header().Set("Content-Type", "image/png")
	resp.Write(outImageBytes)
}
