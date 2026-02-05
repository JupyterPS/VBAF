#Requires -Version 5.1
# Dashboard 1
<#
.SYNOPSIS
    Learning Dashboard Demo
.DESCRIPTION
    Demonstrates the learning dashboard with simulated training data.
    Shows neural network training and RL agent learning simultaneously.
.NOTES
    FIXED: Clean class loading to avoid caching issues
#>

# CRITICAL: Check if classes are already loaded (cache issue)
if ([System.Management.Automation.PSTypeName]'MetricsCollector'.Type) {
    Write-Host "? WARNING: Classes already loaded in this session!" -ForegroundColor Yellow
    Write-Host "  For best results, close PowerShell and start fresh." -ForegroundColor Yellow
    Write-Host "  Or run: Launch-Dashboard-Clean.ps1" -ForegroundColor Cyan
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit
    }
}

$basePath = $PSScriptRoot

# Load visualization components IN ORDER
. (Join-Path $basePath "VBAF.Visualization.MetricsCollector.ps1")
. (Join-Path $basePath "VBAF.Visualization.GraphRenderer.ps1")
. (Join-Path $basePath "VBAF.Visualization.LearningDashboard.ps1")

Write-Host "`n+----------------------------------------------+" -ForegroundColor Cyan
Write-Host "¦     LEARNING DASHBOARD - DEMO               ¦" -ForegroundColor Cyan
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan

Write-Host "`nStarting dashboard with simulated training..." -ForegroundColor Yellow
Write-Host "This will show:"
Write-Host "  • Neural network error decreasing"
Write-Host "  • RL agent rewards increasing"
Write-Host "  • Epsilon (exploration) decaying"
Write-Host "  • Real-time statistics"
Write-Host ""
Write-Host "Controls:" -ForegroundColor Cyan
Write-Host "  [SPACE] - Pause/Resume updates"
Write-Host "  [R]     - Reset all metrics"
Write-Host ""

# Create dashboard
$dashboard = New-Object LearningDashboard -ArgumentList "VBAF Training Visualization"

# Simple training data generator (no background jobs - they cause issues)
$script:epoch = 0
$script:startError = 0.5
$script:startReward = 5.0
$script:epsilonValue = 1.0

# Create timer that generates and updates data
$dataTimer = New-Object System.Windows.Forms.Timer
$dataTimer.Interval = 100  # 100ms = 10 data points per second

$dataTimer.Add_Tick({
    $script:epoch++
    
    if ($script:epoch -le 500) {
        # Simulate neural network error decreasing
        $trainingError = $script:startError * [Math]::Exp(-$script:epoch / 100.0) + (Get-Random -Minimum 0.0 -Maximum 0.05)
        
        # Simulate RL reward increasing
        $baseReward = $script:startReward + ($script:epoch / 50.0)
        $rewardValue = $baseReward + (Get-Random -Minimum -2.0 -Maximum 2.0)
        
        # Epsilon decay
        $script:epsilonValue *= 0.995
        if ($script:epsilonValue -lt 0.01) { $script:epsilonValue = 0.01 }
        
        # Update dashboard - EXPLICIT TYPE CASTING
        $dashboard.Metrics.RecordError([double]$trainingError)
        $dashboard.Metrics.RecordReward([double]$rewardValue)
        $dashboard.Metrics.RecordEpsilon([double]$script:epsilonValue)
        
        # Show progress in console
        if ($script:epoch % 50 -eq 0) {
            Write-Host "Epoch $($script:epoch): Error=$($trainingError.ToString('F4')), Reward=$($rewardValue.ToString('F2')), Epsilon=$($script:epsilonValue.ToString('F3'))"
        }
    } else {
        # Training complete
        Write-Host "`n? Training simulation complete (500 epochs)" -ForegroundColor Green
        $dataTimer.Stop()
    }
}.GetNewClosure())

# Start data generation
$dataTimer.Start()

# Show dashboard (blocking)
try {
    $dashboard.Show()
} finally {
    # Cleanup
    $dataTimer.Stop()
    $dataTimer.Dispose()
}

Write-Host "`n? Dashboard closed" -ForegroundColor Green

