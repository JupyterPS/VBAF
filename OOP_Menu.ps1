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
    $I = [ChoiceDescription]::new('&9', '') 
    $J = [ChoiceDescription]::new('&10', '') 
 
    


    $options = [ChoiceDescription[]]($A, $B, $C, $D, $E, $F, $G, $H, $I, $J)

    $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)


    switch ($result) {

         0 { Psedit $basePath\OO1_Class.ps1 }
         1 { Psedit $basePath\OO2_Properties.ps1 }
         2 { Psedit $basePath\OO3_Method.ps1 }
         3 { Psedit $basePath\OO4_Enum.ps1 }
         4 { Psedit $basePath\OO5_ClassConstructor.ps1 }          
         5 { Psedit $basePath\OO6_ClassInheritance.ps1 }
         6 { Psedit $basePath\OO7_Call_Get+Set+.ps1 }
         7 { Psedit $basePath\OO8_Polymorphism.ps1 }   
         8 { Psedit $basePath\OO9_OOP_Definitions.ps1 }                                        
         9 { invoke-expression -Command $basePath\OOA_LoadTabs.ps1 }    
        

    }
}

  New-Menu -Title "                                                                                                                                   _ _______ OmeOnuP _______ _" -Question {   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                                                  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                                                                                                                 Object-Oriented Concepts

                                                                                                                                      ~~    2👀22   ~~

                                         1:           CLASS
                                         2:           PROPERTY
                                         3:           METHOD

                                         4:           Enum

                                         5:           CLASS Constructor
                                         6:           CLASS Inheritance

                                         7:           CALL GetSet  
                                         8:           POLYMORPHISM

                                         9:           OOP Definitons                                
                                       10:           ACTIVATE all Tabs
                                        

                                        

                                          }