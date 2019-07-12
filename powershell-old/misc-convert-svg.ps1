$indir = "C:\Users\becolem\Pictures\Microsoft_CloudnEnterprise_Symbols_v2.5_PUBLIC\BONUS\AzurePortaliconsDump\";
$outdir = "c:\temp\eps\";

get-childitem $indir  -recurse | where {$_.extension -eq ".svg"} | % {
     $out = $_.Name.Replace(".svg", "")
     $in = $_.FullName
     $dir = $_.DirectoryName.Replace($indir, "");
     #New-Item -ItemType Directory -Force -Path "$outdir$dir"
     $cmd = "C:\Users\becolem\Desktop\Inkscape-0.91-1-win64\inkscape\inkscape.exe '$in' --export-png '$outdir$dir\$out.png' -w 256 -h 256"
     #$cmd
     iex $cmd
     sleep -Milliseconds 300
}