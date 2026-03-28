$test = Get-Content $basePath\FO_FjernvarmeForbrug≈ret.txt
$output = $test[0..($test.count - 2)]
Set-Content -Path '$basePath\FO_FjernvarmeForbrug≈ret.txt' -Value $output
Get-Content "$basePath\FO_FjernvarmeForbrug≈ret.txt" 
         
         







