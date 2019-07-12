<#
.SYNOPSIS
    Generates documentation from an ARM template file
.DESCRIPTION
    Scans an Azure JSON ARM template and creates a markdown readme file (readme.md)
.NOTES
    Author:   Ben Coleman
    Date/Ver: Jun 2017, v1
#>

# Change as required!
param(
    [string]$template = "azuredeploy.json",
    [bool]$deploy     = 1,
    [string]$outfile  = "readme.md"
)

# Change to taste
$template_desc = "Overall template description here"
$param_desc = "Parameter description"
$output_desc = "Output description"

$json = Get-Content -Path $template | ConvertFrom-Json

# Guess work on title based on parent folder 
try {
    $title = (Split-Path $template -Parent)
    $title = $title.Split('\')[$title.Split('\').Length-1]
    $title = $title.Replace('-', ' ')
    $title = (Get-Culture).textinfo.totitlecase($title)
} catch {
    $title = "Template Title Change Me"
}

# First line is title followed by description
$out = "# "
$out += $title + "`n"
$out += $template_desc + "`n`n`n"

# List of resources
$res_array = @{}
foreach($res in $json.resources.PSObject.Properties.Value) {
    try { 
        $res_array.Add($res.type, '')
    } Catch {
    }
}
$out += "### Deployed Resources`n"
foreach($r in $res_array.Keys) {
    $out += "- " + $r + "`n"
}

# Parameters
$out += "`n`n### Parameters`n"
foreach($p in $json.parameters.PSObject.Properties) {
    $desc = $param_desc
    
    if($p.value.metadata.description) {
        $desc = $p.value.metadata.description
    }
    
    $out += "- ``" + $p.Name + "``: $desc `n"
}

# Outputs
$out += "`n`n### Outputs`n"
foreach($o in $json.outputs.PSObject.Properties) {
    $out += "- ``" + $o.Name + "``: "+$output_desc+" `n"
}

# Link to quick deploy this template
if($deploy) {
    $out += "`n`n### Quick Deploy`n[![deploy](http://files.bencoleman.co.uk/img/azuredeploy.png)](https://portal.azure.com/#create/Microsoft.Template/uri/)"
}
$out += "`n`n### Notes`n"

# Put output file in same folder as input template
$out | Out-File -FilePath ((Split-Path $template -Parent) + "\" + $outfile)