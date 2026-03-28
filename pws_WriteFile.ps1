$lines = @(1,"2",3,(get-date))
$path = "$basePath\myfile1.txt"
$lines | Out-File -FilePath $path

$data[0,2,3]
$data | ForEach-Object {"Item: [$PSItem]"}
     
$data = @(
       [pscustomobject]@{FirstName='Kevin';LastName='Marquette'}
       [pscustomobject]@{FirstName='John'; LastName='Doe'}
   )
$data[0].FirstName

$data = @(1,2,3,4)
$data -join '-'

$data -contains '2'

[int[]] $numbers = 1,2,3

$myarray = [System.Collections.ArrayList]::new()  # .net framework arraylist
[void]$myArray.Add('Value')

$bucket1 = [System.Collections.ArrayList]@(1,2,3,4,5)







