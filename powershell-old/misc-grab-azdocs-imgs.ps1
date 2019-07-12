$base = "https://docs.microsoft.com/en-us/azure/"
$outdir = ".\svgout2\"
New-Item -ItemType directory -Path $outdir -Force | Out-Null

$resp = Invoke-WebRequest -Uri ($base + "#pivot=services&panel=all")
$regex_matches = ($resp.Content | Select-String '<img src="(.*?svg)"' -AllMatches)

foreach($m in $regex_matches.Matches) {
    $r = Get-Random;
    $m.Groups[1].Value | Out-File -FilePath ($outdir + $r + ".svg")
}

foreach($m in $regex_matches.Matches) {
    $img_uri = $m.Groups[1].Value;
    $parts = ($img_uri -split "/");
    $name = $parts[$parts.Length - 1];
    
    if($img_uri -Like "http*") {
        Invoke-WebRequest -Uri ($img_uri) -OutFile ($outdir + $name);
    } else {
        Invoke-WebRequest -Uri ($base + $img_uri) -OutFile ($outdir + $name);
    }
}
