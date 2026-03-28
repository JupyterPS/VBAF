using namespace System.Management.Automation.Host 
cls
function New-Menu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Question
    )

    $A = [ChoiceDescription]::new('&1', '')     
    $B = [ChoiceDescription]::new('&2', '')
    $C = [ChoiceDescription]::new('&3', '')
    $D = [ChoiceDescription]::new('&4', '')
    $E = [ChoiceDescription]::new('&5', '')
    $F = [ChoiceDescription]::new('&6', '')    
    $G = [ChoiceDescription]::new('&7', '')    
    $H = [ChoiceDescription]::new('&8', '')    
    
    $options = [ChoiceDescription[]]($A, $B, $C, $D, $E, $F, $G, $H)

    $result = $host.ui.PromptForChoice($Title, $Question, $options, 0) 

     switch ($result) {

         0 { PSedit $basePath\HO_SpeedUpPS.ps1 }  
         1 { invoke-expression -Command $basePath\HO_Administrator.ps1 }          
         2 { PSedit $basePath\HO_ResetFirefox.ps1 }
         3 { invoke-expression -Command $basePath\HO_HTMLReport.ps1  }      
         4 { invoke-expression -Command $basePath\HO_DiscSpace.ps1 }               
         5 { PSedit $basePath\HO_CleanFilesFolders.ps1 }
         6 { invoke-expression -Command $basePath\HO_ClearBin.ps1 } 
         7 { PSedit $basePath\HO_PCClean-up.ps1 }   
       
        
    }

}
                                                                                                                                                                      
  New-Menu -Title "                                                                                                                                      _ _______ M e n u _______ _" -Question {   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                                    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~       
                                                                                                                                  H O V E D K O N T O R E T        

                                                                                                                                     ~~    AF 2👀20   ~~
                       
                                           1:   Speed Up PowerShell
                                           2:   Run as Administrator
                                           3:   Reset Firefox
                                           4:   View PC Specifications
                                           5:   Show Disk Capacity                                      
                                           6:   Clean Up Files and Folders
                                           7:   Empty Recycle Bin
                                           8:   Perform Periodic Total Cleanup                                                                                        
                                                                                 
                                         }                                                                                                                                                              



