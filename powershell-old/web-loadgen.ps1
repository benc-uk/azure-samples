param (
    [string]$url = "http://127.0.0.1:5000/Stress", #"https://contoso-sports.azurewebsites.net/Store",
    [int]$sleep = 20
)

while ($true) {
    try {
        echo $newurl
        $start = get-date
        $resp = Invoke-WebRequest -Uri $url -TimeoutSec 10
        $end = get-date
        $timetaken = [Math]::Round(($end - $start).TotalMilliseconds, 2)

               
        echo ("{0} #### HTTP:{1} Resp time:{2}ms" -f (get-date -Format "HH:mm:ss"), $resp.StatusCode, $timetaken)
    } catch {   
        echo ("ERROR: {0}" -f $_.Exception.Message)
    }

    Start-Sleep -Milliseconds $sleep
}