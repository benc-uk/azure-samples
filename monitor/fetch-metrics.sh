#!/bin/bash

resource="/subscriptions/52512f28-c6ed-403e-9569-82a9fb9fec91/resourceGroups/Demo.AppService/providers/Microsoft.Web/sites/nodejs-demoapp"
metric="Requests"
filter="Instance eq '*'"
timeSpan="2019-07-11T00:00:00Z/2019-07-12T00:00:00Z"
interval="PT15M"
aggregation="Average"

echo "### Saving metric definitions as metric-defs.json"
requestURL="https://management.azure.com${resource}/providers/microsoft.insights/metricDefinitions?api-version=2018-01-01"
az rest --method GET --uri "$requestURL" --output-file metric-defs.json

echo ""
echo "### Listing metric dimensions for: ${metric}"
requestURL="https://management.azure.com${resource}/providers/microsoft.insights/metrics?resultType=metadata&metricnames=${metric}&timespan=${timeSpan}&\$filter=${filter}&interval=${interval}&aggregation=${aggregation}&api-version=2018-01-01"
az rest --method GET --uri "$requestURL" --query "value[0].timeseries[].metadatavalues[].{dimensionName:name.value,dimensionValue:value}" -o table


echo ""
echo "### Listing metric values for: ${metric}"
requestURL="https://management.azure.com${resource}/providers/microsoft.insights/metrics?metricnames=${metric}&timespan=${timeSpan}&\$filter=${filter}&interval=${interval}&aggregation=${aggregation}&api-version=2018-01-01"
az rest --method GET --uri "$requestURL" --query "value[0].timeseries[0].data" -o table
