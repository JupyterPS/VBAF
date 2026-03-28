# Define paths for Win10 and Win11
$pathWin11 = "C:\Users\henni\OneDrive\WindowsPowerShell"
$pathWin10 = "C:\Users\Henning\OneDrive\WindowsPowerShell"

# Determine the base path dynamically
if (Test-Path $pathWin11) {
    $basePath = $pathWin11
    Write-Host "Using Win11 path: $pathWin11"
} elseif (Test-Path $pathWin10) {
    $basePath = $pathWin10
    Write-Host "Using Win10 path: $pathWin10"
} else {
    Write-Error "Neither path for Win11 nor Win10 exists. Please check the paths."
    return
}

# Output the base path for verification
Write-Host "Base path set to: $basePath"

# Set the current directory to the base path
Set-Location -Path $basePath
Write-Host "Current directory: $(Get-Location)"

# Store the base path in an environment variable (optional)
[System.Environment]::SetEnvironmentVariable("PS_ScriptPath", $basePath, "User")
Write-Host "Environment variable set: $Env:PS_ScriptPath"

# Confirm environment is ready
Write-Host "Environment setup complete. You can now access files."
