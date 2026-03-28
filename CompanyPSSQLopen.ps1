# CompanyPSSQLopen.ps1
Import-Module PSSQLite
$db = New-SqliteConnection -DataSource "$basePath\Company.db"

# Check if the connection is already open
if ($db.State -ne [System.Data.ConnectionState]::Open) {
    Write-Output "Connection is not open. Attempting to open it now."
    
    try {
        $db.Open()
        Write-Output "Connection state after opening: $($db.State)"
    } catch {
        Write-Error "Failed to open the connection: $_"
    }
} else {
    Write-Output "Connection is already open. No need to open it again."
}







