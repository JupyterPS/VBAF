
                                                                                                                                                             <#
                                                   - oo00oo -  
                                              
                                                  Error Handling        
                                              
                                               M A C H I N E  R O O M  
                                               
                                               (Qualified staff only) 
                                                                                                                                                         #>


# 16. Error Handling


  # Mechanisms to handle errors that occur during script execution. PowerShell provides try, catch, and finally blocks
  # to manage exceptions and ensure graceful error handling.
  # This allows scripts to continue running or to provide meaningful error messages.

       try {
           $result = 1 / 0  # This will cause a division by zero error
       } catch {
           Write-Host "An error occurred: $_"
       } finally {
           Write-Host "This block always runs."
       }


<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/powershellbyexample.dev/"                                                           Error Actions
Start-Process "https:/powershellbyexample.dev/"                                                           Error Handling  
  
###################################################################################################>  

$Modules = @(
    "AZ",
    "ExchangeOnlineManagement",
    "ImportExcel",
    "Microsoft.Graph",
    "Microsoft.Online.SharePoint.PowerShell",
    "MicrosoftTeams",
    "Microsoft365DSC",
    "PNP.PowerShell"
)
Foreach($Module in $Modules){
    Try{
        Install-Module $module
    }Catch{
        write-host "Error Installing $module `n : $_ `n `n"
    }
}

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"