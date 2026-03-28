#Write-output "txt"
#write-warning "txt" 
#write-error -message 'xxx' -errorid 99 -category authenticationerror
#get-childitem | format-table -autosize -property name, length -groupby mode
#get-childitem | out-gridview -title "tekst"

$Uservalue = read-host 'enter name'
write-output 'How are you' $Uservalue 

$Uservalue = read-host "enter password" -assecurestring                                                                              
write-output $Uservalue 

Enter-PSSession -ComputerName RemoteServer -Port 5353 -Credential Domain\Username

Invoke-Command -ComputerName RemoteServer -Credential Domain\Username -ScriptBlock {PScommand}

$credin = get-credential
write-output $credin

$Uservalue = read-host -prompt ('enter value')
write-output 'Hi-there' $Uservalue 
 

 






