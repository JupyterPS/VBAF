
New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application                                             #1. Class i The .NET Framework Class Library  2. Parameter
$x  = New-Object -TypeName System.Diagnostics.EventLog -ArgumentList Application                                       #1. Her er objected med data
$x  | get-Member -MemberType Method                                                                                    #1. Lister Methods     
$x.Clear()                                                                                                             #1. The Method Clear sletter loggen    
New-Object -ComObject WScript.Shell                                                                                    #Følgende 4 er COM classes på script området (-ComObject)  
New-Object -ComObject WScript.Network
New-Object -ComObject Scripting.Dictionary                                                                                                                             
New-Object -ComObject Scripting.FileSystemObject
$x = New-Object -ComObject WScript.Shell
get-Member -InputObject $x






