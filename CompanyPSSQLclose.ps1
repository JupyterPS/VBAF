Write-Host("`n")
# Close the SQLite connection only if it's currently open
if ($db.State -eq [System.Data.ConnectionState]::Open) {
    Write-Output "Closing the connection."
    $db.Close()
} else {
    Write-Output "Connection is not open. No need to close it."
}






