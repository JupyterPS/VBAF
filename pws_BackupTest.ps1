function Start-BackupTimer {
    param(
        [int]$IntervalDays = 1  # Set to 12 days by default
    )

    # Convert days to milliseconds for the timer interval
    $intervalMs = $IntervalDays * 24 * 60 * 60 * 1000

    # Initialize the timer
    $global:backupTimer = New-Object Timers.Timer
    $global:backupTimer.Interval = $intervalMs
    $global:backupTimer.AutoReset = $true

    # Define the action to take when the timer elapses
    Register-ObjectEvent -InputObject $global:backupTimer -EventName "Elapsed" -SourceIdentifier "BackupTimer.Elapsed" -Action {
        Write-Host "Timer event triggered. Performing backup..."
        Copy-Item -Path "$basePath\Company.db" -Destination "$basePath\CompanyBackup.db" -Force
        Write-Host "Backup completed."
    }

    # Start the timer
    $global:backupTimer.Start()
    Write-Host "Backup timer started. It will run every $IntervalDays days."

    # Manual activation test function
    function Test-Timer {
        Write-Host "Testing if the timer is still running..."
        if ($global:backupTimer.Enabled) {
            Write-Host "Timer is active."
        } else {
            Write-Host "Timer is not active."
        }
    }

    # Return the test function for manual invocation
    return Get-Command Test-Timer
}

# Start the backup timer with a 12-day interval
$testTimer = Start-BackupTimer -IntervalDays 1

# To test if the timer is running, manually call:
# $testTimer.Invoke()







