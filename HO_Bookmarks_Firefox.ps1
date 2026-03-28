<# 
    Firefox Smart Repair Script
    - Kills Firefox
    - Finds default profile
    - Backs up profile
    - Clears WAL/SHM
    - Renames broken SQLite DBs
    - Restores newest bookmark backup
#>

$ErrorActionPreference = "Stop"

Write-Host "=== FIREFOX SMART REPAIR SCRIPT ===`n"

# 1. Kill all Firefox processes
Write-Host "Step 1: Closing Firefox..."
Get-Process firefox -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host " - Killing firefox.exe (PID $($_.Id))"
    $_ | Stop-Process -Force
}
Start-Sleep -Seconds 2

# 2. Locate profile root
$profilesRoot = Join-Path $env:APPDATA "Mozilla\Firefox\Profiles"
if (-not (Test-Path $profilesRoot)) {
    Write-Host "ERROR: No Firefox profiles folder found at: $profilesRoot"
    exit 1
}

Write-Host "Profiles root: $profilesRoot"

# 3. Detect default profile (heuristic: *.default* with longest name / latest modified)
$profileCandidates = Get-ChildItem $profilesRoot -Directory |
    Where-Object { $_.Name -match "default" } |
    Sort-Object LastWriteTime -Descending

if (-not $profileCandidates -or $profileCandidates.Count -eq 0) {
    Write-Host "ERROR: No default-like profile found under: $profilesRoot"
    Write-Host "Profiles found:"
    Get-ChildItem $profilesRoot -Directory | ForEach-Object { Write-Host " - " $_.FullName }
    exit 1
}

$profile = $profileCandidates[0]
$profilePath = $profile.FullName

Write-Host "Step 2: Using profile: $profilePath"

# 4. Make a full backup of the profile
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $env:USERPROFILE "FirefoxProfileBackups"
if (-not (Test-Path $backupRoot)) {
    New-Item -ItemType Directory -Path $backupRoot | Out-Null
}

$backupPath = Join-Path $backupRoot ("ProfileBackup-" + $profile.Name + "-" + $timestamp)

Write-Host "Step 3: Backing up profile to: $backupPath"
Copy-Item -Path $profilePath -Destination $backupPath -Recurse -Force

Write-Host "Backup complete."

# 5. Identify key DB files
$placesFile      = Join-Path $profilePath "places.sqlite"
$faviconsFile    = Join-Path $profilePath "favicons.sqlite"
$placesShm       = Join-Path $profilePath "places.sqlite-shm"
$placesWal       = Join-Path $profilePath "places.sqlite-wal"
$faviconsShm     = Join-Path $profilePath "favicons.sqlite-shm"
$faviconsWal     = Join-Path $profilePath "favicons.sqlite-wal"

Write-Host "`nStep 4: Cleaning WAL/SHM leftovers (if any)..."

$walShmFiles = @($placesShm, $placesWal, $faviconsShm, $faviconsWal)
foreach ($f in $walShmFiles) {
    if (Test-Path $f) {
        Write-Host " - Removing leftover file: $f"
        Remove-Item $f -Force
    }
}

# 6. Rename suspected corrupted DBs
Write-Host "`nStep 5: Renaming suspected corrupted DBs..."

if (Test-Path $placesFile) {
    $newName = $placesFile + ".broken-" + $timestamp
    Write-Host " - Renaming places.sqlite -> $newName"
    Rename-Item -Path $placesFile -NewName (Split-Path $newName -Leaf)
} else {
    Write-Host " - places.sqlite not found (maybe already missing)."
}

if (Test-Path $faviconsFile) {
    $newName = $faviconsFile + ".broken-" + $timestamp
    Write-Host " - Renaming favicons.sqlite -> $newName"
    Rename-Item -Path $faviconsFile -NewName (Split-Path $newName -Leaf)
} else {
    Write-Host " - favicons.sqlite not found (maybe already missing)."
}

# 7. Restore newest bookmark backup (if exists)
Write-Host "`nStep 6: Restoring newest bookmark backup (if available)..."

$bookmarkBackupDir = Join-Path $profilePath "bookmarkbackups"

if (-not (Test-Path $bookmarkBackupDir)) {
    Write-Host " - No bookmarkbackups folder found. Skipping bookmark restore."
} else {
    $backupFiles = Get-ChildItem $bookmarkBackupDir -Filter "*.jsonlz4" |
                   Sort-Object LastWriteTime -Descending

    if (-not $backupFiles -or $backupFiles.Count -eq 0) {
        Write-Host " - No .jsonlz4 bookmark backups found. Skipping bookmark restore."
    } else {
        $newestBackup = $backupFiles[0]
        Write-Host " - Newest backup: $($newestBackup.Name)"

        # Copy newest backup to profile root for easier manual import
        $targetBackup = Join-Path $profilePath ("restored-bookmarks-" + $newestBackup.Name)
        Copy-Item $newestBackup.FullName $targetBackup -Force

        Write-Host " - Copied newest backup to: $targetBackup"
        Write-Host "   You can import it via Firefox:"
        Write-Host "   Bookmarks -> Manage Bookmarks -> Import and Backup -> Restore -> Choose File"
        Write-Host "   Then select: $targetBackup"
    }
}

Write-Host "`n=== DONE ==="
Write-Host "Now start Firefox."
Write-Host "Firefox will rebuild places.sqlite and favicons.sqlite automatically."
Write-Host "If the error persists, we likely have a deeper profile or disk issue."
