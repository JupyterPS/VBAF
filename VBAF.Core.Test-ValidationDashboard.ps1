#Requires -Version 5.1
# Dashboard 3
<#
.SYNOPSIS
    Validation dashboard for VBAF foundation components
.DESCRIPTION
    Visual proof that neural networks, Q-learning, and experience replay work.
    Three panels: NN training XOR, Q-learning grid world, Experience replay stats
.EXAMPLE
    
#>

# Load dependencies
$basePath = $PSScriptRoot
. (Join-Path $basePath "VBAF.Core.AllClasses.ps1")
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==================== VALIDATION STATE ====================
class ValidationState {
    # Neural Network State
    [object]$NeuralNetwork
    [System.Collections.ArrayList]$NNErrorHistory
    [int]$NNEpoch
    [double]$NNCurrentError
    [bool]$NNTraining
    
    # Q-Learning State
    [object]$QLAgent
    [int]$QLEpisode
    [double]$QLTotalReward
    [System.Collections.ArrayList]$QLRewardHistory
    [int]$GridX
    [int]$GridY
    [int]$GoalX
    [int]$GoalY
    
    # Experience Replay State
    [object]$ExperienceReplay
    [int]$ReplaySize
    [System.Collections.ArrayList]$ReplaySizeHistory
    
    ValidationState() {
        $this.NNErrorHistory = New-Object System.Collections.ArrayList
        $this.NNEpoch = 0
        $this.NNCurrentError = 1.0
        $this.NNTraining = $false
        
        $this.QLRewardHistory = New-Object System.Collections.ArrayList
        $this.QLEpisode = 0
        $this.QLTotalReward = 0
        $this.GridX = 0
        $this.GridY = 0
        $this.GoalX = 9
        $this.GoalY = 9
        
        $this.ReplaySizeHistory = New-Object System.Collections.ArrayList
        $this.ReplaySize = 0
    }
}

$global:valState = New-Object ValidationState

# ==================== NEURAL NETWORK SETUP ====================
function Initialize-NeuralNetwork {
    Write-Host "Initializing Neural Network for XOR..." -ForegroundColor Cyan
    
    # Create XOR training data
    $global:xorData = @(
        @{Input=@(0.0,0.0); Expected=@(0.0)},
        @{Input=@(0.0,1.0); Expected=@(1.0)},
        @{Input=@(1.0,0.0); Expected=@(1.0)},
        @{Input=@(1.0,1.0); Expected=@(0.0)}
    )
    
    # Create network: 2 inputs, 4 hidden, 1 output
    try {
        $global:valState.NeuralNetwork = New-Object NeuralNetwork -ArgumentList @(2, 4, 1), 0.5
        Write-Host "  ? Neural Network created (2-4-1 architecture)" -ForegroundColor Green
    } catch {
        Write-Host "  ? Failed to create Neural Network: $_" -ForegroundColor Red
    }
}

# ==================== Q-LEARNING GRID WORLD SETUP ====================
function Initialize-QLearning {
    Write-Host "Initializing Q-Learning Grid World..." -ForegroundColor Cyan
    
    # Create simple grid world agent
    $actions = @("up", "down", "left", "right")
    
    try {
        # Use 3-parameter constructor: actions, learningRate, epsilon
        $global:valState.QLAgent = New-Object QLearningAgent -ArgumentList (,$actions), 0.1, 0.3
        $global:valState.ExperienceReplay = New-Object ExperienceReplay -ArgumentList 100
        Write-Host "  ? Q-Learning agent created (10x10 grid)" -ForegroundColor Green
    } catch {
        Write-Host "  ? Failed to create Q-Learning agent: $_" -ForegroundColor Red
    }
}

# ==================== TRAINING STEP FUNCTIONS ====================
function Step-NeuralNetwork {
    if (-not $global:valState.NNTraining) { return }
    if ($global:valState.NNEpoch -ge 1000) { 
        $global:valState.NNTraining = $false
        return 
    }
    
    # Train one epoch
    $totalError = 0
    foreach ($sample in $global:xorData) {
        $output = $global:valState.NeuralNetwork.Forward($sample.Input)
        $error = $sample.Expected[0] - $output[0]
        $totalError += $error * $error
        $global:valState.NeuralNetwork.Backward($sample.Expected)
    }
    
    $global:valState.NNCurrentError = $totalError / $global:xorData.Count
    $global:valState.NNErrorHistory.Add($global:valState.NNCurrentError) | Out-Null
    $global:valState.NNEpoch++
}

function Step-QLearning {
    # Get current state
    $state = "$($global:valState.GridX),$($global:valState.GridY)"
    
    # Choose action
    $action = $global:valState.QLAgent.ChooseAction($state)
    
    # Execute action
    $newX = $global:valState.GridX
    $newY = $global:valState.GridY
    
    if ($action -eq "up" -and $newY -gt 0) { $newY-- }
    if ($action -eq "down" -and $newY -lt 9) { $newY++ }
    if ($action -eq "left" -and $newX -gt 0) { $newX-- }
    if ($action -eq "right" -and $newX -lt 9) { $newX++ }
    
    # Calculate reward
    $reward = -0.1  # Step penalty
    if ($newX -eq $global:valState.GoalX -and $newY -eq $global:valState.GoalY) {
        $reward = 10.0  # Goal reward
    }
    
    $nextState = "$newX,$newY"
    
    # Learn
    $global:valState.QLAgent.Learn($state, $action, $reward, $nextState)
    
    # Store experience
    $experience = @{
        State = $state
        Action = $action
        Reward = $reward
        NextState = $nextState
    }
    $global:valState.ExperienceReplay.Add($experience)
    
    # Update state
    $global:valState.GridX = $newX
    $global:valState.GridY = $newY
    $global:valState.QLTotalReward += $reward
    
    # Reset if goal reached
    if ($newX -eq $global:valState.GoalX -and $newY -eq $global:valState.GoalY) {
        $global:valState.QLRewardHistory.Add($global:valState.QLTotalReward) | Out-Null
        $global:valState.QLEpisode++
        $global:valState.GridX = 0
        $global:valState.GridY = 0
        $global:valState.QLTotalReward = 0
    }
    
    # Update replay stats
    $global:valState.ReplaySize = $global:valState.ExperienceReplay.Size()
    $global:valState.ReplaySizeHistory.Add($global:valState.ReplaySize) | Out-Null
}

# ==================== DRAWING FUNCTIONS ====================
function Draw-NeuralNetworkPanel {
    param($g, $width, $height)
    
    # Background
    $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 30))
    $g.FillRectangle($bgBrush, 0, 0, $width, $height)
    $bgBrush.Dispose()
    
    # Title
    $titleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.DrawString("Neural Network - XOR Training", $titleFont, $titleBrush, 10, 10)
    $titleFont.Dispose()
    $titleBrush.Dispose()
    
    # Status
    $font = New-Object System.Drawing.Font("Consolas", 10)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
    $status = "Epoch: $($global:valState.NNEpoch) | Error: $([Math]::Round($global:valState.NNCurrentError, 4))"
    if ($global:valState.NNTraining) { $status += " | TRAINING" }
    $g.DrawString($status, $font, $brush, 10, 40)
    
    # Learning curve
    if ($global:valState.NNErrorHistory.Count -gt 1) {
        $graphY = 80
        $graphHeight = $height - 120
        $graphWidth = $width - 40
        
        # Grid
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(50, 50, 50))
        for ($i = 0; $i -le 5; $i++) {
            $y = $graphY + ($graphHeight * $i / 5)
            $g.DrawLine($gridPen, 20, $y, 20 + $graphWidth, $y)
        }
        $gridPen.Dispose()
        
        # Error line
        $maxError = 1.0
        if ($global:valState.NNErrorHistory.Count -gt 0) {
            $max = ($global:valState.NNErrorHistory | Measure-Object -Maximum).Maximum
            if ($max -gt 0) { $maxError = $max }
        }
        
        $points = New-Object System.Collections.ArrayList
        for ($i = 0; $i -lt $global:valState.NNErrorHistory.Count; $i++) {
            $x = 20 + ($i / [Math]::Max(1, $global:valState.NNErrorHistory.Count - 1)) * $graphWidth
            $y = $graphY + $graphHeight - (($global:valState.NNErrorHistory[$i] / $maxError) * $graphHeight)
            $point = New-Object System.Drawing.PointF($x, $y)
            $points.Add($point) | Out-Null
        }
        
        if ($points.Count -gt 1) {
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Lime, 2)
            $g.DrawLines($pen, $points.ToArray([System.Drawing.PointF]))
            $pen.Dispose()
        }
    }
    
    $font.Dispose()
    $brush.Dispose()
}

function Draw-QLearningPanel {
    param($g, $width, $height)
    
    # Background
    $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 30))
    $g.FillRectangle($bgBrush, 0, 0, $width, $height)
    $bgBrush.Dispose()
    
    # Title
    $titleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.DrawString("Q-Learning - Grid World (10x10)", $titleFont, $titleBrush, 10, 10)
    $titleFont.Dispose()
    $titleBrush.Dispose()
    
    # Status
    $font = New-Object System.Drawing.Font("Consolas", 10)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
    $status = "Episode: $($global:valState.QLEpisode) | Position: ($($global:valState.GridX),$($global:valState.GridY))"
    $g.DrawString($status, $font, $brush, 10, 40)
    
    # Draw grid
    $cellSize = 25
    $gridStartX = 20
    $gridStartY = 80
    
    for ($y = 0; $y -lt 10; $y++) {
        for ($x = 0; $x -lt 10; $x++) {
            $cellX = $gridStartX + ($x * $cellSize)
            $cellY = $gridStartY + ($y * $cellSize)
            
            # Cell color
            $cellBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 50, 50))
            
            # Agent position
            if ($x -eq $global:valState.GridX -and $y -eq $global:valState.GridY) {
                $cellBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            }
            
            # Goal position
            if ($x -eq $global:valState.GoalX -and $y -eq $global:valState.GoalY) {
                $cellBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Green)
            }
            
            $g.FillRectangle($cellBrush, $cellX, $cellY, $cellSize - 2, $cellSize - 2)
            $cellBrush.Dispose()
        }
    }
    
    # Reward history graph
    if ($global:valState.QLRewardHistory.Count -gt 1) {
        $graphY = $gridStartY + 270
        $graphHeight = $height - $graphY - 20
        $graphWidth = $width - 40
        
        $points = New-Object System.Collections.ArrayList
        $maxReward = ($global:valState.QLRewardHistory | Measure-Object -Maximum).Maximum
        $minReward = ($global:valState.QLRewardHistory | Measure-Object -Minimum).Minimum
        $range = $maxReward - $minReward
        if ($range -eq 0) { $range = 1 }
        
        for ($i = 0; $i -lt $global:valState.QLRewardHistory.Count; $i++) {
            $x = 20 + ($i / [Math]::Max(1, $global:valState.QLRewardHistory.Count - 1)) * $graphWidth
            $normalized = ($global:valState.QLRewardHistory[$i] - $minReward) / $range
            $y = $graphY + $graphHeight - ($normalized * $graphHeight)
            $point = New-Object System.Drawing.PointF($x, $y)
            $points.Add($point) | Out-Null
        }
        
        if ($points.Count -gt 1) {
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Orange, 2)
            $g.DrawLines($pen, $points.ToArray([System.Drawing.PointF]))
            $pen.Dispose()
        }
    }
    
    $font.Dispose()
    $brush.Dispose()
}

function Draw-ExperienceReplayPanel {
    param($g, $width, $height)
    
    # Background
    $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 30))
    $g.FillRectangle($bgBrush, 0, 0, $width, $height)
    $bgBrush.Dispose()
    
    # Title
    $titleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.DrawString("Experience Replay Buffer", $titleFont, $titleBrush, 10, 10)
    $titleFont.Dispose()
    $titleBrush.Dispose()
    
    # Status
    $font = New-Object System.Drawing.Font("Consolas", 10)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
    $status = "Buffer Size: $($global:valState.ReplaySize) / 100"
    $g.DrawString($status, $font, $brush, 10, 40)
    
    # Buffer fill bar
    $barX = 20
    $barY = 80
    $barWidth = $width - 40
    $barHeight = 30
    
    $emptyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 50, 50))
    $g.FillRectangle($emptyBrush, $barX, $barY, $barWidth, $barHeight)
    $emptyBrush.Dispose()
    
    $fillWidth = ($global:valState.ReplaySize / 100.0) * $barWidth
    $fillBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Magenta)
    $g.FillRectangle($fillBrush, $barX, $barY, $fillWidth, $barHeight)
    $fillBrush.Dispose()
    
    # Buffer size history
    if ($global:valState.ReplaySizeHistory.Count -gt 1) {
        $graphY = 140
        $graphHeight = $height - 160
        $graphWidth = $width - 40
        
        $points = New-Object System.Collections.ArrayList
        
        for ($i = 0; $i -lt $global:valState.ReplaySizeHistory.Count; $i++) {
            $x = 20 + ($i / [Math]::Max(1, $global:valState.ReplaySizeHistory.Count - 1)) * $graphWidth
            $y = $graphY + $graphHeight - (($global:valState.ReplaySizeHistory[$i] / 100.0) * $graphHeight)
            $point = New-Object System.Drawing.PointF($x, $y)
            $points.Add($point) | Out-Null
        }
        
        if ($points.Count -gt 1) {
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Magenta, 2)
            $g.DrawLines($pen, $points.ToArray([System.Drawing.PointF]))
            $pen.Dispose()
        }
    }
    
    $font.Dispose()
    $brush.Dispose()
}

# ==================== MAIN FORM ====================
Write-Host "      - oo00oo - " -ForegroundColor Yellow
Write-Host "VBAF Validation Dashboard" -ForegroundColor Cyan
Write-Host "      - oo00oo - " -ForegroundColor Yellow

Initialize-NeuralNetwork
Initialize-QLearning

$form = New-Object System.Windows.Forms.Form
$form.Text = "VBAF Validation Dashboard - Foundation Proof"
$form.Width = 1400
$form.Height = 600
$form.BackColor = [System.Drawing.Color]::Black
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.TopMost = $true  # Bring to front when opening

# Create panels
$nnPanel = New-Object System.Windows.Forms.Panel
$nnPanel.Left = 10
$nnPanel.Top = 50
$nnPanel.Width = 440
$nnPanel.Height = 450
$nnPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Controls.Add($nnPanel)

$qlPanel = New-Object System.Windows.Forms.Panel
$qlPanel.Left = 460
$qlPanel.Top = 50
$qlPanel.Width = 440
$qlPanel.Height = 450
$qlPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Controls.Add($qlPanel)

$erPanel = New-Object System.Windows.Forms.Panel
$erPanel.Left = 910
$erPanel.Top = 50
$erPanel.Width = 440
$erPanel.Height = 450
$erPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.Controls.Add($erPanel)

# Enable double buffering
$prop = $nnPanel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance,NonPublic")
$prop.SetValue($nnPanel, $true, $null)
$prop.SetValue($qlPanel, $true, $null)
$prop.SetValue($erPanel, $true, $null)

# Paint events
$nnPanel.Add_Paint({
    param($sender, $e)
    Draw-NeuralNetworkPanel $e.Graphics $sender.Width $sender.Height
})

$qlPanel.Add_Paint({
    param($sender, $e)
    Draw-QLearningPanel $e.Graphics $sender.Width $sender.Height
})

$erPanel.Add_Paint({
    param($sender, $e)
    Draw-ExperienceReplayPanel $e.Graphics $sender.Width $sender.Height
})

# Control buttons
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "? Start NN Training"
$startButton.Left = 10
$startButton.Top = 10
#$startButton.Width = 150
#$startButton.Height = 30
$startButton.Width = 120
$startButton.Height = 20
$startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)  # Bright blue
$startButton.ForeColor = [System.Drawing.Color]::White
$startButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$startButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$startButton.Add_Click({
    if (-not $global:valState.NNTraining) {
        # Start/Resume
        $global:valState.NNTraining = $true
        $timer.Start()
        $startButton.Text = "? Pause NN Training"
        $startButton.BackColor = [System.Drawing.Color]::FromArgb(255, 140, 0)  # Orange
        $stopButton.Enabled = $true
        $stopButton.Text = "? Stop All"
    } else {
        # Pause
        $global:valState.NNTraining = $false
        $startButton.Text = "? Resume NN"
        $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 80)  # Green
    }
})
$form.Controls.Add($startButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "? Stop All"
$stopButton.Left = 170
$stopButton.Top = 10
#$stopButton.Width = 120
#$stopButton.Height = 30
$stopButton.Width = 100
$stopButton.Height = 20
$stopButton.BackColor = [System.Drawing.Color]::FromArgb(220, 50, 50)  # Bright red
$stopButton.ForeColor = [System.Drawing.Color]::White
$stopButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$stopButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$stopButton.Add_Click({
    $global:valState.NNTraining = $false
    $timer.Stop()
    $startButton.Text = "? Resume"
    $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 80)  # Green
    $startButton.Enabled = $true
    $stopButton.Text = "? Stopped"
    $stopButton.Enabled = $false
})
$form.Controls.Add($stopButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready - Press Start to begin"
$statusLabel.Left = 300
$statusLabel.Top = 15
$statusLabel.Width = 1000
$statusLabel.ForeColor = [System.Drawing.Color]::Lime
$statusLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($statusLabel)

# Update timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 50  # 20 FPS
$timer.Add_Tick({
    # Step NN training
    Step-NeuralNetwork
    
    # Step Q-Learning (every frame)
    Step-QLearning
    
    # Update status
    if ($global:valState.NNTraining) {
        $accuracy = (1.0 - $global:valState.NNCurrentError) * 100
        $statusLabel.Text = "Training... Epoch: $($global:valState.NNEpoch) | Accuracy: $([Math]::Round($accuracy, 1))% | QL Episodes: $($global:valState.QLEpisode)"
    } elseif ($global:valState.NNEpoch -ge 1000) {
        $statusLabel.Text = "? Training Complete! NN converged. QL Episodes: $($global:valState.QLEpisode)"
        $statusLabel.ForeColor = [System.Drawing.Color]::Lime
    }
    
    # Redraw panels
    $nnPanel.Invalidate()
    $qlPanel.Invalidate()
    $erPanel.Invalidate()
})
$timer.Start()

Write-Host "  ? Dashboard ready!" -ForegroundColor Green
Write-Host "      - oo00oo - " -ForegroundColor Yellow

$form.ShowDialog()
$timer.Stop()