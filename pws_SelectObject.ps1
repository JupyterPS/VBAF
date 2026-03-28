New-Item -ItemType File -Name 'Myfile.txt' 
$file = Get-Item $basePath\Myfile.txt
$file.CreationTime       #property 
Get-Content $file.FullName
$file | Get-Member
#Selecting/inspecting Object Properties
$file | Select-Object Length, CreationTime, LastAccessTime 







