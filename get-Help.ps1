help get-childitem 
help -name get-service -examples
get-help get-service 
get-help get-childitem -detailed  
get-help get-childitem -full
get-help get-childitem -parameter *
get-help get-member -parameter # Get all the files on the Desktop
$files = Get-ChildItem -path $basePath 
$files | Sort-Object Name 
$files | Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-7)} | Sort-Object CreationTime | Select-Object Name, CreationTime, LastAccessTime, Length
get-help get-childitem -examples  
get-help about_*                                                                                                       #(Se under Windows PowerShell About Help Topics)
get-help about_command_syntax
get-help #<cmdlet-name># -detailed   







