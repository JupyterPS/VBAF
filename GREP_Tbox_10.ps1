                                                                                                                                                            <#
                                                   - oo00oo -  
                                              
                                                 Cmdlet Binding        
                                              
                                               M A C H I N E  R O O M  
                                               
                                               (Qualified staff only) 
                                                                                                                                                  #>



# 10. Cmdlet Binding 



<###################################################################################################
   A keyword used in function definitions to enable advanced function features, 
   such as parameter validation, support for common parameters 
   and the ability to use the -WhatIf and -Confirm parameters.
   It allows for more robust and user-friendly functions.
###################################################################################################>


function Test-Function {
           [CmdletBinding()]
           param (
               [string]$Name
           )
           Write-Host "Hello, $Name!"
       }

       function Get-UserInfo {
       [CmdletBinding()]
       param (
           [Parameter(Mandatory = $true, Position = 0)]
           [string]$Username,
       
           [Parameter()]
           [ValidateSet("Full", "Summary")]
           [string]$DetailLevel = "Summary"
       )
       
       # Simulating user data retrieval
       $userData = @{
           "Alice" = @{ Age = 30; City = "New York" }
           "Bob"   = @{ Age = 25; City = "Los Angeles" }
       }
       
       # Check if the user exists
       if (-not $userData.ContainsKey($Username)) {
           Write-Error "User '$Username' not found."
           return
       }
       
       # Output user information based on DetailLevel
       switch ($DetailLevel) {
           "Full" {
               $info = $userData[$Username]
               Write-Host "User: $Username, Age: $($info.Age), City: $($info.City)"
           }
           "Summary" {
               Write-Host "User: $Username"
           }
       }
       }

       # Example usage
       Get-UserInfo -Username "Alice" -DetailLevel "Full"  # Outputs: User: Alice, Age: 30, City: New York

###################################################################################################


Function Get-Something {
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True)]
        [string[]]$Computername
    )
    Begin {
        Write-Verbose "Initialize stuff in Begin block"
    }

    Process {
        Write-Verbose "Stuff in Process block to perform"
        $Computername
    }

    End {
        Write-Verbose "Final work in End block"
    }
}
1,2,3,4,5,6 | get-something -verbose


function Get-UserInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter()]
        [ValidateSet("Full", "Basic")]
        [string]$InfoLevel = "Basic"
    )

    process {
        if ($InfoLevel -eq "Full") {
            Write-Verbose "Retrieving full information for user: $Username"
            # Simulate retrieving full user info
            return "Full info for $Username"
        } else {
            Write-Verbose "Retrieving basic information for user: $Username"
            # Simulate retrieving basic user info
            return "Basic info for $Username"
        }
    }
}
Get-UserInfo -Username "jdoe" -InfoLevel "Full" -Verbose


function Write-PipeLineInfoValue {
    [cmdletbinding()]
    param(
        [parameter(
            Mandatory         = $true,
            ValueFromPipeline = $true)]
            $pipelineInput
)

    Begin {

        Write-Host `n"The begin {} block runs once at the start, and is good for setting up variables."
        Write-Host "-------------------------------------------------------------------------------"

    }

    Process {

        ForEach ($input in $pipelineInput) {

            Write-Host "Process [$($input.Name)] information"

            if ($input.Path) {
        
                Write-Host "Path: $($input.Path)"`n
        
            } else {

                Write-Host "No path found!"`n -ForegroundColor Red

            }

        }

    }

    End {

        Write-Host "-------------------------------------------------------------------------------"
        Write-Host "The end {} block runs once at the end, and is good for cleanup tasks."`n

    }

}
Get-Process | Select-Object -First 10 | Write-PipeLineInfoValue


function Write-PipeLineInfoPropertyName {
    [cmdletbinding()]
    param(
        [parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string[]]
            $Name
)

    Begin {

        Write-Host `n"The begin {} block runs once at the start, and is good for setting up variables."
        Write-Host "-------------------------------------------------------------------------------"

    }

    Process {

        ForEach ($input in $name) {

            Write-Host "Value of input's Name property: [$($input)]"

        }

    } 

    End {

        Write-Host "-------------------------------------------------------------------------------"
        Write-Host "The end {} block runs once at the end, and is good for cleanup tasks."`n

    }

}
Get-Process | Select-Object -First 10 | Write-PipeLineInfoPropertyName

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"




