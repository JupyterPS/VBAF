# Determine the user profile paths
$path1 = "C:\Users\Henning\OneDrive\SharedPowerShell\WindowsPowerShell"
$path2 = "$basePath"

# Determine which path exists and set the script directory
if (Test-Path -Path $path1) {
    $scriptDirectory = $path1
    #Write-Host "Using script directory: $scriptDirectory (Henning)"
} elseif (Test-Path -Path $path2) {
    $scriptDirectory = $path2
    #Write-Host "Using script directory: $scriptDirectory (henni)"
} else {
    #Write-Error "Neither script directory exists. Please verify the paths."
    return
}

#Write-Host "Starting Jumplist.ps1"
#Write-Host "Script directory set to $scriptDirectory"

# Load PowerShell scripts in the directory
try {
    $scripts = Get-ChildItem -Path $scriptDirectory -Filter *.ps1
    #Write-Host "Retrieved script list: $($scripts.Count) scripts found"
} catch {
    #Write-Error "Error retrieving scripts from ${scriptDirectory}: $_"
}

# Additional code to load DLLs and create the JumpList...















