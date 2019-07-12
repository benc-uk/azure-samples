$connection = new-object System.Data.SqlClient.SQLConnection("Data Source=bchacking01.database.windows.net;User ID=ben;Password=Rephlex303!;Initial Catalog=hacking")
$command = new-object System.Data.sqlclient.sqlcommand("SELECT id, text FROM alltweets_new ORDER BY id OFFSET 0 ROWS FETCH NEXT 5000 ROWS ONLY;",$connection)
$connection.Open()
$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
$dataset = New-Object System.Data.DataSet
$adapter.Fill($dataSet) | Out-Null
$connection.Close()

$docs = @()
foreach ($row in $dataset.Tables[0].Rows) { 
  $docs += @{ "id"=$row[0]; "text"=$row[1].Trim() }
}

$json = ConvertTo-Json @{"documents"=$docs} -Compress

$res = ""
$res = Invoke-WebRequest -Uri "https://westus.api.cognitive.microsoft.com/text/analytics/v2.0/topics" -Method "POST" -Body $json -Headers @{"Ocp-Apim-Subscription-Key"="3b0c24e1ce05448fa51cda237dcb807c"} -ContentType "application/json; charset=utf-8"
echo "======================================="
$res
$res.Content
echo "Check results here: $($res.Headers['location'])"
