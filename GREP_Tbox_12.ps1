                                                                                                                                                     <#
                                                   - oo00oo -  
                                              
                                                  M o d u l e s        
                                              
                                               M A C H I N E  R O O M  
                                               
                                               (Qualified staff only) 
                                                                                                                                                      #>



# 12. Modules


  # A way to package and distribute functions, cmdlets, and other resources. 
  # Modules can be imported into scripts to extend functionality and organize code.
  # Modules can be created as .psm1 files or as a folder containing a module manifest.

       # Importing a module
       Import-Module MyModule

       # Creating a module
       New-Module -Name MyModule -ScriptBlock {
           function SayHello {
               Write-Host "Hello from MyModule!"
           }
       }

       # Creating a simple module
       New-Module -Name MyModule -ScriptBlock {
           function Get-Greeting {
               param ([string]$Name)
               "Hello, $Name!"
           }
       }
       
       # Importing the module
       Import-Module MyModule
       Get-Greeting -Name "Alice"  # Outputs: Hello, Alice!


<###################################### >>> Additional referrals <<< ###############################

Start-Process "https:/books.goalkicker.com/PowerShellBook/PowerShellNotesForProfessionals.pdf"            Chapter14 Modules                                                    # God ovesigt    
  
###################################################################################################>  


<###################################################################################################
A way to package and distribute functions, cmdlets, and other resources. 
Modules can be imported into scripts to extend functionalit and organize code.
Modules can be created as .psm1 files or as a folder containing a module manifest.
###################################################################################################>

       # Importing a module
       Import-Module MyModule

       # Creating a module
       New-Module -Name MyModule -ScriptBlock {
           function SayHello {
               Write-Host "Hello from MyModule!"
           }
       }

       # Creating a simple module
       New-Module -Name MyModule -ScriptBlock {
           function Get-Greeting {
               param ([string]$Name)
               "Hello, $Name!"
           }
       }
       
       # Importing the module
       Import-Module MyModule
       Get-Greeting -Name "Alice"  # Outputs: Hello, Alice!

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"
