#
# CHANGE THESE TO MATCH YOUR ENVIRONMENT
#

$resId = "/subscriptions/52512f28-c6ed-403e-9569-82a9fb9fec91/resourceGroups/Demo.AppService/providers/Microsoft.Web/sites/nodejs-demoapp"

#
# Get auth token from AAD
#
$currentAzContext = Get-AzContext 
echo "### Aquiring token from AAD for signed in context"
$currentAzContext
$profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient(
  [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
)
$token = $profileClient.AcquireAccessToken($currentAzContext.Subscription.TenantId).AccessToken

# Build an array of HTTP header values
$authHeader = @{
 'Content-Type' = 'application/json'
 'Accept' = 'application/json'
 'Authorization' = "Bearer " + $token
}


#
# Azure Monitor API from here
#

# Get metric definitions
#$request = "https://management.azure.com"+$resId+"/providers/microsoft.insights/metricDefinitions?api-version=2018-01-01"
#Invoke-RestMethod -Uri $request -Headers $authHeader -Method Get -OutFile ".\metric-defs.json"

# Get dimension values...
$metric = "Requests"
$filter = "Instance eq '*'"
$timeSpan = "2019-07-11T00:00:00Z/2019-07-12T00:00:00Z"

$request = "https://management.azure.com${resId}/providers/microsoft.insights/metrics?metricnames=${metric}&timespan=${timeSpan}&resultType=metadata&`$filter=${filter}&api-version=2018-01-01"
$dimensions = Invoke-RestMethod -Uri $request -Headers $authHeader -Method Get 

echo "### DIMENSION VALUES FOR: ${metric}"
echo $dimensions.value.timeseries | Format-Table

# Get metric values...
$metric = "Requests"
$filter = "Instance eq '*'"
$timeSpan = "2019-07-11T00:00:00Z/2019-07-12T00:00:00Z"
$interval = "PT15M"
$aggregation = "Average"

$request = "https://management.azure.com${resId}/providers/microsoft.insights/metrics?metricnames=${metric}&timespan=${timeSpan}&`$filter=${filter}&interval=${interval}&aggregation=${aggregation}&api-version=2018-01-01"

echo $request

$metricValues = Invoke-RestMethod -Uri $request -Headers $authHeader -Method Get #-OutFile ".\metric-values.json"

echo "### METRIC VALUES FOR: ${metric}"
echo $metricValues.value.timeseries[0].data
