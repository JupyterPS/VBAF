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

         0 { Psedit $basePath\ClassBattle.ps1 }        
         1 { Psedit $basePath\Enotek.ps1 } 
         2 { Psedit $basePath\CompanyHeadQuarters.ps1 } 
        
    }
}

  New-Menu -Title "                                                                                                                                   _ _______ OmeOnuP _______ _" -Question {   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                                                                                                                 Object-Oriented-Scripts

                                                                                                                                     ~~    2👀23   ~~

                                         1:           Monster Battle Class       
                                                                                                                         
                                         2:           Enotek                                                                 
                                                                                                              
                                         3:           Company Head Quarters                                      
                                          }









