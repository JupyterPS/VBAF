# CompanyEvents.ps1
Write-Host("`n")
Write-Host "=> _____ CompanyEvent _____________________ <=`n"

# Handle events
function Handle-Events {
    $VerbosePreference = 'Continue'

    # Event handler functions
    function Handle-FirstEvent { Write-Host "First event triggered."; New-Event -SourceIdentifier SecondEvent }
    function Handle-SecondEvent { Write-Host "Second event triggered."; New-Event -SourceIdentifier ThirdEvent }
    function Handle-ThirdEvent { Write-Host "Third event triggered."; New-Event -SourceIdentifier FourthEvent }
    function Handle-FourthEvent { Write-Host "Fourth event triggered."; New-Event -SourceIdentifier FifthEvent }
    function Handle-FifthEvent { Write-Host "Fifth event triggered."; Write-Host "End of the domino effect." }

    # Register the events
    Register-EngineEvent -SourceIdentifier FirstEvent -Action { Handle-FirstEvent }
    Register-EngineEvent -SourceIdentifier SecondEvent -Action { Handle-SecondEvent }
    Register-EngineEvent -SourceIdentifier ThirdEvent -Action { Handle-ThirdEvent }
    Register-EngineEvent -SourceIdentifier FourthEvent -Action { Handle-FourthEvent }
    Register-EngineEvent -SourceIdentifier FifthEvent -Action { Handle-FifthEvent }

    # Trigger the initial event to start the domino effect
    Write-Host "Starting the domino effect by triggering the first event."
    New-Event -SourceIdentifier FirstEvent
}
Handle-Events

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Host "PowerShell is exiting. Please remember to log your hours for the day."
}

function Show-LogHoursMessage {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show('Please remember to log your hours for the day.')
}

try {
    Write-Host "Doing some work..."
} finally {
    Show-LogHoursMessage
    Write-Host "Exiting PowerShell session, bye for now"
}

# Register event handler for UserLogin
Register-EngineEvent -SourceIdentifier UserLogin -Action {
    $userName = $event.MessageData[0]
    Write-Host "User $userName has logged in."
}

# Trigger the UserLogin event with MessageData

# Data Import/Export Events
Register-EngineEvent -SourceIdentifier DataImported -Action {
    param($eventArgs)
    $filePath = $event.MessageData[0]
    Write-Host "Data has been imported from $filePath."
}

# Trigger the event with MessageData
New-Event -SourceIdentifier DataImported -MessageData @("C:\path\to\datafile.csv")

# File Processing Events
Register-EngineEvent -SourceIdentifier FileProcessed -Action {
    param($eventArgs)
    $fileName = $event.MessageData[0]
    Write-Host "File $fileName has been processed."
}

New-Event -SourceIdentifier FileProcessed -MessageData @("example.txt")

# Threshold Alert Events
Register-EngineEvent -SourceIdentifier ThresholdExceeded -Action {
    $metric = $event.MessageData[0]
    $value = $event.MessageData[1]
    Write-Host "$metric has exceeded the threshold: $value"
}

# Trigger the event with sample data
New-Event -SourceIdentifier ThresholdExceeded -MessageData @("DiskSpace", "90%")

# System Health Check Events
Register-EngineEvent -SourceIdentifier HealthCheck -Action {
    param($eventArgs)
    $checkName = $event.MessageData[0]
    $status = $event.MessageData[1]
    Write-Host "Health check $checkName status: $status"
}

New-Event -SourceIdentifier HealthCheck -MessageData @("DatabaseConnection", "OK")

# Application-Specific Events
Register-EngineEvent -SourceIdentifier OrderPlaced -Action {
    param($eventArgs)
    $orderId = $event.MessageData[0]
    Write-Host "Order $orderId has been placed."
}

New-Event -SourceIdentifier OrderPlaced -MessageData @(12345)

# Maintenance Events
Register-EngineEvent -SourceIdentifier MaintenanceCompleted -Action {
    param($eventArgs)
    $taskName = $event.MessageData[0]
    Write-Host "Maintenance task $taskName has been completed."
}

New-Event -SourceIdentifier MaintenanceCompleted -MessageData @("CleanUp")

<#
# Initialization of the Timer
$timer = New-Object Timers.Timer
#$timer.Interval = 999999999  # Set to an interval that fits your needs
$timer.Interval = 60000  # Set to an interval that fits your needs
$timer.AutoReset = $true

# Define the Event Handler
Register-ObjectEvent -InputObject $timer -EventName "Elapsed" -SourceIdentifier "Timer.Elapsed" -Action {
    # Your periodic task code here
    Write-Host "Timer event triggered. Performing backup..."
    
    # Example backup operation
    Copy-Item -Path "$basePath\Company.db" `
              -Destination "$basePath\CompanyBackup.db"
}

# Start the Timer
$timer.Start()
Write-Host "Timer started."

# Keep the script running indefinitely
while ($true) {
    Start-Sleep -Seconds 1
}
#>
<#
# Function to stop and clean up the timer
function Stop-Timer {
    if ($global:timer) {
        # Check if the timer is running and stop it
        if ($global:timer.Enabled) {
            Write-Output "Stopping the timer..."
            $global:timer.Stop()
        }
        
        # Unregister the event
        Unregister-Event -SourceIdentifier "Elapsed" -ErrorAction SilentlyContinue
        
        # Dispose of the timer object
        $global:timer.Dispose()
        Write-Output "Timer disposed and cleaned up."
    } else {
        Write-Output "Timer object is not defined."
    }
}

# Call the function to stop the timer
Stop-Timer
#>
                                    
# PowerShell exit events







