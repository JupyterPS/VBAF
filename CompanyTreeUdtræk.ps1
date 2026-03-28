# CompanyTreeUdtræk.ps1
# Define the path to the input file
$inputFilePath = "$basePath\Company4.ps1" # Change this to your actual file path

<#                                One at a time
  
Company1.ps1                   
Company2.ps1                   
Company3.ps1                                  
Company4.ps1    
CompanyBase.ps1 
CompanyOperations.ps1 

#>

# Function to extract classes, functions, and methods from the input file
function Extract-ClassesFunctionsMethods {
    param (
        [string]$filePath
    )

    # Initialize arrays to hold the extracted information
    $classes = @()
    $functions = @()
    $methods = @()

    # Read the content of the file
    $content = Get-Content $filePath

    # Regular expressions to match classes, functions, and methods
    $classPattern = 'class\s+(\w+)'
    #$functionPattern = 'function\s+(\w+)'
    $functionPattern = 'function\s+([\w-]+)'
    $methodPattern = '^\s*\[void\]\s+(\w+)\s*\('  # Pattern for methods starting with [void]

    # Loop through each line in the content
    foreach ($line in $content) {
        # Match and extract classes
        if ($line -match $classPattern) {
            $classes += $matches[1]
        }

        # Match and extract functions
        if ($line -match $functionPattern) {
            $functions += $matches[1]
        }

        # Match and extract methods (assuming methods are defined as function within classes)
        if ($line -match $methodPattern) {
            $methods += $matches[1]
        }
    }

    # Remove duplicates from methods and sort them
    $methods = $methods | Sort-Object -Unique

    # Return a structured object with the results
    return @{
        Classes  = $classes
        Functions = $functions
        Methods   = $methods
    }
}

# Extract classes, functions, and methods
$results = Extract-ClassesFunctionsMethods -filePath $inputFilePath

# Display the extracted information
Write-Host "#_____________________Classes_______________________"
$results.Classes | ForEach-Object { Write-Host "class $_" }
Write-Host ""

Write-Host "#_____________________Functions_______________________"
$results.Functions | ForEach-Object { Write-Host $_ }
Write-Host ""

Write-Host "#_____________________Methods_______________________"
$results.Methods | ForEach-Object { Write-Host $_ }







