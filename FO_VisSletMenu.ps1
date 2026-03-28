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
 
    
    $options = [ChoiceDescription[]]($A, $B, $C)

    $result = $host.ui.PromptForChoice($Title, $Question, $options, 0) 

     switch ($result) {

         0 { invoke-expression -Command $basePath\FO_FjernvarmeForbrugÅret.txt }
         1 { invoke-expression -Command $basePath\FO_ElForbrugÅret.txt }
         2 { invoke-expression -Command $basePath\FO_VandForbrugÅret.txt } 
         
        
    }

}
                                                                                                                                                                      
  New-Menu -Title "                                                                                                                                      _ _______ M e n u _______ _" -Question {   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                                    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~       
                                                                                                                                               Ret data        

                                                                                                                                     ~~    AF 2👀22   ~~
                       
                                         1:           Fjernvarme
                                         2:           EL
                                         3:           Vand                                                                                                                                                                                                                                                   
                                                                                            
                                                                                 
                                          }           







