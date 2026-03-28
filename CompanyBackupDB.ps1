# Backup Database Script

# Define source and destination paths
$sourcePath = "$basePath\Company.db"
$destinationPath = "$basePath\CompanyBackup.db"

# Perform the backup
Copy-Item -Path $sourcePath -Destination $destinationPath -Force

# Output confirmation
Write-Host "Backup completed successfully."












