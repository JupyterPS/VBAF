# Function to uninstall PowerShell 7 MSI installation
function Uninstall-PowerShell7 {
    $pw7 = Get-WmiObject -Class Win32_Product | Where-Object {
        $_.Name -match "PowerShell 7" -or $_.Name -match "PowerShell 7.1" -or $_.Name -match "PowerShell 7.*"
    }
    if ($pw7) {
        foreach ($app in $pw7) {
            Write-Host "Uninstalling: $($app.Name)"
            $app.Uninstall() | Out-Null
        }
    } else {
        Write-Host "PowerShell 7 MSI installation not found."
    }
}

# Function to remove leftover PowerShell 7 folders
function Remove-PowerShell7Folders {
    $paths = @(
        "$env:ProgramFiles\PowerShell\7",
        "$env:ProgramFiles(x86)\PowerShell\7",
        "$env:LocalAppData\Microsoft\PowerShell\7"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "Removing folder: $path"
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to clean PowerShell 7 entries from PATH environment variable
function Clean-PowerShell7FromPath {
    $oldPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    if ($oldPath -match "PowerShell\\7") {
        $newPath = (($oldPath -split ";") | Where-Object { $_ -notmatch "PowerShell\\7" }) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
        Write-Host "Removed PowerShell 7 paths from Machine PATH."
    } else {
        Write-Host "No PowerShell 7 entries found in Machine PATH."
    }

    # Also check User PATH
    $userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($userPath -match "PowerShell\\7") {
        $newUserPath = (($userPath -split ";") | Where-Object { $_ -notmatch "PowerShell\\7" }) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, [EnvironmentVariableTarget]::User)
        Write-Host "Removed PowerShell 7 paths from User PATH."
    } else {
        Write-Host "No PowerShell 7 entries found in User PATH."
    }
}

# Run the uninstall and cleanup
Uninstall-PowerShell7
Remove-PowerShell7Folders
Clean-PowerShell7FromPath

Write-Host "PowerShell 7 uninstall and cleanup complete."
