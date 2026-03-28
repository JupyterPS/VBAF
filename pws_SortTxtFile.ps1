$path = "$basePath\myfile.txt" 
Get-Content $path | Sort-Object -Unique | ForEach-Object {$_ } | set-content $path   







