Add-Type -AssemblyName System.Windows.Forms

# Define paths for Win10 and Win11
$pathWin11 = "C:\Users\henni\OneDrive\SharedPowerShell\WindowsPowerShell"
$pathWin10 = "C:\Users\Henning\OneDrive\SharedPowerShell\WindowsPowerShell"


# Define tabs and their content (file paths to be opened in each tab)
$Tabs = [ordered]@{
    'Tab One' = @(
        "${basePath}\FO_FJ3ÅrsforbrugChart.ps1",
        "${basePath}\FJ_LineChart.ps1",
        "${basePath}\FO_EL3ÅrsforbrugChart.ps1",
        "${basePath}\FJ_ÅrsforbrugChart.ps1",
        "${basePath}\FO_Vand3ÅrsforbrugChart.ps1",
        "${basePath}\CompanyTree.ps1"
    )
}

# Set default interval (in seconds) between tab switches
$defaultInterval = 3
$cycles = 1  # Number of complete loops through the tabs before stopping

# Function to display the current tab info and countdown in the console
function Display-Status($tabName, $timeLeft) {
    Write-Host "Switching to tab: $tabName" 
    for ($i = $timeLeft; $i -gt 0; $i--) {
        Start-Sleep 1  # Sleep for 1 second to simulate the interval
    }
}

# Function to open the scripts in each tab and execute them
function Open-And-Execute-Tabs {
    for ($loop = 1; $loop -le $cycles; $loop++) {
        Write-Host "Starting cycle $loop of $cycles." -ForegroundColor Green

        foreach ($tab in $Tabs.Keys) {
            Write-Host "Opening scripts for $tab" -ForegroundColor Cyan

            # Clear the current tab before adding new files
            if ($psISE.CurrentPowerShellTab.Files | Where-Object { $_.IsSaved -eq $false }) {
                Write-Host "Warning: Unsaved files detected! Please save before continuing." -ForegroundColor Yellow
            } else {
                $psISE.CurrentPowerShellTab.Files.Clear()
            }

            # Open each file in the tab
            foreach ($script in $Tabs[$tab]) {
                Write-Output "Attempting to add and execute: $script"

                # Add script to ISE
                try {
                    $file = $psISE.CurrentPowerShellTab.Files.Add($script)
                    Write-Output "Added $script to ISE"
                } catch {
                    Write-Error "Error adding script $script to ISE: $($_.Exception.Message)"
                }

                # Execute the script
                try {
                    . "$script"  # Dot-source the script to load its content
                    Write-Output "Sourced script $script"
                } catch {
                    Write-Error "Error sourcing script $($script): $($_.Exception.Message)"
                }

                # Wait briefly before moving to the next file
                Start-Sleep 1  # Short 1-second sleep after each script execution
            }

            # Wait for the set interval on this tab (3 seconds default)
            Start-Sleep $defaultInterval  # Wait for 3 seconds before moving to the next tab
        }
    }
    Write-Host "Company slideshow with the newest info, finished after $cycles cycle!" -ForegroundColor Green
}

# Start the slideshow process
Open-And-Execute-Tabs












