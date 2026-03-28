Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms

# Create main Window
$Window = New-Object System.Windows.Window
$Window.Title = "PowerShell ISE WPF Dashboard"
$Window.Width = 400
$Window.Height = 300
$Window.WindowStartupLocation = 'CenterScreen'

# Grid Layout
$Grid = New-Object System.Windows.Controls.Grid
$Window.Content = $Grid

# Define 3 Rows
for ($i = 0; $i -lt 3; $i++) {
    $Row = New-Object System.Windows.Controls.RowDefinition
    $Row.Height = 'Auto'
    $Grid.RowDefinitions.Add($Row)
}

# CPU Usage Label
$CPULabel = New-Object System.Windows.Controls.Label
$CPULabel.FontSize = 16
$CPULabel.Content = "CPU Usage: "
[System.Windows.Controls.Grid]::SetRow($CPULabel, 0)
$Grid.Children.Add($CPULabel)

# Memory Usage Label
$MemLabel = New-Object System.Windows.Controls.Label
$MemLabel.FontSize = 16
$MemLabel.Content = "Memory Usage: "
[System.Windows.Controls.Grid]::SetRow($MemLabel, 1)
$Grid.Children.Add($MemLabel)

# Disk Usage Label
$DiskLabel = New-Object System.Windows.Controls.Label
$DiskLabel.FontSize = 16
$DiskLabel.Content = "Disk C: Free Space: "
[System.Windows.Controls.Grid]::SetRow($DiskLabel, 2)
$Grid.Children.Add($DiskLabel)

# Timer to update the values every 2 seconds
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [TimeSpan]::FromSeconds(2)
$Timer.Add_Tick({
    # CPU
    $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select -ExpandProperty Average
    $CPULabel.Content = "CPU Usage: $cpu %"

    # Memory
    $mem = Get-CimInstance Win32_OperatingSystem
    $total = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
    $free  = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
    $used  = [math]::Round($total - $free, 2)
    $MemLabel.Content = "Memory Usage: $used GB / $total GB"

    # Disk
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskFree = [math]::Round($disk.FreeSpace / 1GB, 2)
    $diskTotal = [math]::Round($disk.Size / 1GB, 2)
    $DiskLabel.Content = "Disk C: Free: $diskFree GB / $diskTotal GB"
})
$Timer.Start()

$Window.ShowDialog() | Out-Null
