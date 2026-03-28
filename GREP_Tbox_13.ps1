
                                                                                                                                                     <#
                                                   - oo00oo -  
                                              
                                                 P i p e l i n e        
                                              
                                               M A C H I N E  R O O M  
                                               
                                               (Qualified staff only) 
                                                                                                                                                     #>
 


# 13. Pipeline



<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"            Chapter25 Pipeline   
  
###################################################################################################>  

<###################################################################################################
A method for passing the output of one command as input to another. 
The pipeline operator (|) is used to connect commands, allowing for powerful data manipulation and processing.
Each command in the pipeline processes the data and passes it to the next command.
###################################################################################################>


Get-Process | Where-Object { $_.CPU -gt 100 } | Sort-Object CPU -Descending

#_________

function Write-FromPipeline{
[CmdletBinding()]
param(
[Parameter(ValueFromPipeline)]
$myInput
)
begin {
Write-Verbose -Message "Beginning Write-FromPipeline"
}
process {
Write-Output -InputObject $myInput
}
end {
Write-Verbose -Message "Ending Write-FromPipeline"
}
}

$foo = 'hello','world',1,2,3
$foo | Write-FromPipeline -Verbose

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"




 

