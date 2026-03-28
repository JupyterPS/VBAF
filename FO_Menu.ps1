using namespace System.Management.Automation.Host 

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
    $I = [ChoiceDescription]::new('&9', '') 
    $J = [ChoiceDescription]::new('&10', '')    
   
      
    $options = [ChoiceDescription[]]($A, $B, $C, $D, $E, $F, $G, $H, $I, $J)

    $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

     switch ($result) {

         0 { invoke-expression -Command $basePath\FO_VisRegMenu.ps1 }  
         1 { invoke-expression -Command $basePath\FO_VisDataMenu.ps1 } 
         2 { invoke-expression -Command $basePath\FO_VisSletMenu.ps1 }
         3 { invoke-expression -Command $basePath\FJ_VisSidsteLinie.ps1 } 
         4 { invoke-expression -Command $basePath\FJ_FjernSidsteLinie.ps1 }              
         5 { invoke-expression -Command $basePath\FJ_UdtrækPeriodeForbrug.ps1 }                            
         6 { invoke-expression -Command $basePath\FJ_VisPeriodeForbrug.ps1 }
         7 { invoke-expression -Command $basePath\FJ_LineChart.ps1 }
         8 { invoke-expression -Command $basePath\FJ_ÅrsforbrugChart.ps1 } 
         9 { invoke-expression -Command $basePath\FO_VisGrafMenu.ps1 } 
       
                   
    }

}
                                                                                                                                                                      
  New-Menu -Title "                                                                                                                                      _ _______ M e n u _______ _" -Question {   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                                      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~       
                                                                                                                         F O R S Y N I N G S C E N T R A L E N    

                                                                                                                                    ~~    AF 2👀22   ~~
                       
                                         1:           REGISTRER tal *** 1-2-3 forsyning                                            
                                         2:           VIS årets tal *** 1-2-3 forsyning  

                                         3:           RET sidste registrering *** 1-2-3 forsyning                                                                                                                                 
                                         4:           VIS sidste registrering
                                         5:           FJERN sidste registrering                                             
                                                                                                                                                                                                                                                                                    
                                         6:           UDTRÆK periode forbrug                                                                                                                                       
                                         7:           VIS periode forbrug til årets pris                                     
                                                                                   
                                         8:           VIS 7 dages udsving grafisk 
                                         9:           VIS 1 års forbrug grafisk     
                                       10:           VIS 3 års forbrug grafisk *** 1-2-3 forsyning 
                                                                                                                                                                                                                                                                                   
                                                                                               
                                                                                 
                                          }
                                          
                                                                                                                                                                                                              
                                 


                                 
                                   

 
  
 
 
 







