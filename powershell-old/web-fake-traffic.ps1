
while ($true) {
    $delay_min = (Get-Random -Minimum 1 -Maximum 5) * 60
    $burst_ms = Get-Random -Minimum 1 -Maximum 20
    $count = Get-Random -Minimum 50 -Maximum 100

    echo ("### Starting run of {0} with delay {1}" -f $count, $burst_ms)

    for($c = $count; $c -gt 0; $c--) {
        $id = Get-Random -Minimum 1 -Maximum 7

        #$url = "https://contoso-sports.azurewebsites.net/Store/Details/"+$id
        $url = "http://bcdevopstest.azurewebsites.net/"

        $resp = Invoke-WebRequest -Uri $url -TimeoutSec 10
        echo ("{1} -- {0}" -f $resp.StatusCode, $url);
        Start-Sleep -Milliseconds $burst_ms
    }

    echo ("### Waiting {0} mins..." -f ($delay_min/60))
    Start-Sleep -Seconds $delay_min
}