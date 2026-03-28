$path = "$basePath\myfile.txt"
$lines = get-content -Path $path
    foreach($line in $lines) {
    if ($line -imatch "Hello there") {
        write-host $line
    }        
}  







