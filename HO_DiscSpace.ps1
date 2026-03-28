Get-PSDrive | Where-Object{$_.free -gt 1} | ForEach-Object{$count = 0; Write-Host "";}{ $_.name + ": used: " + "{0:n2}" -f ($_.used/1gb) + " free: " + "{0:n2}" -f ($_.free/1gb) + " total: " + "{0:n2}" -f (($_.used/1gb)+($_.free/1gb));
$count = $count +$_.free;}{write-host"";write-host "total free space " ("{0:n2}" -f ($count/1gb)) -backgroundcolor magenta}
 






