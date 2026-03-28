#########################################################################  .NET 

[System.Environment] | Get-Member -Static                                  #Class static lister inhold 
[System.Environment]::Commandline                                          #Den første property i classen lister inhold 
[System.Environment]::MachineName                                          #Viser computer id.  -   mange gode properties
[System.Math] | Get-Member -Static -MemberType Methods                     #Samme for static math
[System.Math]::Sqrt(9)                                                     #Sådan bruges første method
#$r=Read-Host "Enter a radius"                                             #en sjov brug af .net class dirkte 
#([math]::Pow($r,2))*[math]::pi 

[System.DateTime] | Get-Member                                             #Jeg er ikke helt klar over forskellen på denne og nedenstående
$DateTime | Get-Member    -MemberType  Properties                          #Kan vise begge,den ene,den anden
$DateTime = New-Object System.DateTime  -ArgumentList 2015, 10, 10         #Da System.DateTime ikke er static (loadet ind automatisk i Powershell) skal classen instantiates først)
$DateTime | Select-Object -Property  *                                     #Angiver tidsværdierne NU   

[system.reflection.assembly]::loadwithpartialname('Microsoft.VisualBasic') | Out-Null   #for classes der ikke er loadet er dette stmt nødvendigt                                                            
#========> Start-Process https://learn.microsoft.com/en-us/dotnet/api/                  <====== til at finde .net Classes 






