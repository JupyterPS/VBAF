 
 Get-Module -ListAvailable | foreach {“`r`nmodule name: $_”; “`r`n”;gcm -Module $_.name -CommandType cmdlet, function | select name}  # lister og lister (skal forstås)






