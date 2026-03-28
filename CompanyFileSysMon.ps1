# FileSystemMonitoring.ps1

Write-Host "=> _____ FileSystemMonitoring _____________ <=`n"

# Monitor file system changes
function Monitor-FileSystem {
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = "$basePath\"
    $watcher.Filter = "*.txt"
    $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite'
    $watcher.IncludeSubdirectories = $true

    Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action { param($source, $e) Write-Host "File $($e.FullPath) was changed." }
    Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action { param($source, $e) Write-Host "File $($e.FullPath) was created." }
    Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action { param($source, $e) Write-Host "File $($e.FullPath) was deleted." }
}

Monitor-FileSystem







