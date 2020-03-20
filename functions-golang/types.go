package main

// FunctionsInvokeRequest is request input
type FunctionsInvokeRequest struct {
	Data map[string]string

	Metadata struct {
		Properties string
		URI        string
		Name       string
		Sys        string
	}
}

// FunctionsInvokeResponse is response when returning a struct/obj
type FunctionsInvokeResponse struct {
	Outputs     map[string]interface{}
	Logs        []string
	ReturnValue interface{}
}

// FunctionsInvokeResponseString is response when returning a string
type FunctionsInvokeResponseString struct {
	Outputs     map[string]interface{}
	Logs        []string
	ReturnValue string
}
