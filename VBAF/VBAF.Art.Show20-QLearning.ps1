#Requires -Version 5.1

<#
.SYNOPSIS
    Wine Castle Parade with Q-Learning Agent
.DESCRIPTION
    Enhanced Show20 where the agent LEARNS which castle types
    create the best visual experience over time.
.NOTES
    Integration of Show20Agent visual rendering + QLearningAgent intelligence
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Set base path
$basePath = $PSScriptRoot

# Load RL dependencies
. "$basePath\VBAF.RL.QTable.ps1"
. "$basePath\VBAF.RL.ExperienceReplay.ps1"
. "$basePath\VBAF.RL.QLearningAgent.ps1"

# -------------------------------
# FORM
# -------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Width = 1200
$form.Height = 500
$form.Text = "Wine Castle Parade - Q-Learning Agent Learning Live!"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Dock = 'Fill'
$form.Controls.Add($mainPanel)

# Castle rendering panel (top 80%)
$castlePanel = New-Object System.Windows.Forms.Panel
$castlePanel.Width = 1200
$castlePanel.Height = 350
$castlePanel.Top = 0
$castlePanel.BackColor = [Drawing.Color]::Black
$mainPanel.Controls.Add($castlePanel)

# Enable DoubleBuffering
$prop = $castlePanel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance,NonPublic")
$prop.SetValue($castlePanel, $true, $null)

# Stats panel (bottom 20%)
$statsPanel = New-Object System.Windows.Forms.Panel
$statsPanel.Width = 1200
$statsPanel.Height = 150
$statsPanel.Top = 350
$statsPanel.BackColor = [Drawing.Color]::FromArgb(20, 20, 30)
$mainPanel.Controls.Add($statsPanel)

# -------------------------------
# Q-LEARNING AGENT SETUP
# -------------------------------
$castleTypes = @("Gothic", "FairyTale", "Fortress", "Palace", "Wizard", "Cathedral", "Oriental", "Ruins")
$agent = New-Object QLearningAgent -ArgumentList @(,$castleTypes)

# Learning tracking
$script:Episode = 0
$script:EpisodeReward = 0.0
$script:EpisodeRewards = New-Object System.Collections.ArrayList
$script:RecentCastles = New-Object System.Collections.ArrayList
$script:CastleCount = 0

# -------------------------------
# CASTLE STATE
# -------------------------------
$script:Castles = @()
for ($i = 0; $i -lt 8; $i++) {
    $castle = @{
        X = ($i * 250)
        Y = 0
        Width = 0
        Height = 0
        Speed = (Get-Random -Minimum 3 -Maximum 9) / 10.0
        Type = ""
        Color = [Drawing.Color]::White
        WindowColor = [Drawing.Color]::White
        Towers = @()
        Flags = @()
        Torches = @()
        State = ""          # State when created
        Action = ""         # Castle type chosen
        Reward = 0.0        # Reward received
    }
    $script:Castles += $castle
}

# -------------------------------
# CASTLE BUILDER (Simplified from your Agent2)
# -------------------------------
function Initialize-Castle($castle, $canvasWidth, $groundY) {
    # Get current state
    $context = @{ RecentTypes = $script:RecentCastles }
    $state = $agent.GetState($context)
    
    # Agent chooses castle type
    $castleType = $agent.ChooseAction($state)
    
    $castle.Type = $castleType
    $castle.State = $state
    $castle.Action = $castleType
    $castle.X = $canvasWidth + (Get-Random -Minimum 60 -Maximum 200)
    
    # Color themes
    $colorThemes = @(
        @{ Castle = [Drawing.Color]::FromArgb(140, 230, 230, 240); Window = [Drawing.Color]::FromArgb(220, 255, 240, 180); Name = "Moonstone" },
        @{ Castle = [Drawing.Color]::FromArgb(120, 180, 100, 130); Window = [Drawing.Color]::FromArgb(200, 255, 200, 120); Name = "Emerald" },
        @{ Castle = [Drawing.Color]::FromArgb(130, 150, 120, 160); Window = [Drawing.Color]::FromArgb(230, 255, 220, 180); Name = "Amethyst" },
        @{ Castle = [Drawing.Color]::FromArgb(110, 200, 160, 140); Window = [Drawing.Color]::FromArgb(200, 255, 210, 140); Name = "Sandstone" }
    )
    $theme = $colorThemes[(Get-Random -Minimum 0 -Maximum $colorThemes.Count)]
    $castle.Color = $theme.Castle
    $castle.WindowColor = $theme.Window
    
    # Simple castle structure (you can expand this with your full rendering)
    $castleWidth = Get-Random -Minimum 100 -Maximum 150
    $castleHeight = Get-Random -Minimum 80 -Maximum 120
    
    $castle.Width = $castleWidth
    $castle.Height = $castleHeight
    $castle.Y = $groundY - $castleHeight
    
    # Simple towers
    $towerCount = Get-Random -Minimum 3 -Maximum 5
    $castle.Towers = @()
    for ($t = 0; $t -lt $towerCount; $t++) {
        $castle.Towers += @{
            X = ($t * ($castleWidth / $towerCount))
            Width = 20
            Height = Get-Random -Minimum 40 -Maximum 70
        }
    }
    
    # Calculate reward for this castle
    $isVaried = ($script:RecentCastles.Count -eq 0) -or ($script:RecentCastles[-1] -ne $castleType)
    
    # Visual balance (you could make this more sophisticated)
    $visualBalance = (Get-Random -Minimum 50 -Maximum 100) / 100.0
    
    # Engagement (simulated viewer interest)
    $engagement = (Get-Random -Minimum 30 -Maximum 100) / 100.0
    
    $outcome = @{
        CastleType = $castleType
        IsVaried = $isVaried
        VisualBalance = $visualBalance
        Engagement = $engagement
    }
    
    $reward = $agent.CalculateReward($outcome)
    $castle.Reward = $reward
    $script:EpisodeReward += $reward
    
    # Update recent history
    $script:RecentCastles.Add($castleType) | Out-Null
    if ($script:RecentCastles.Count -gt 5) {
        $script:RecentCastles.RemoveAt(0)
    }
    
    # Get next state
    $nextContext = @{ RecentTypes = $script:RecentCastles }
    $nextState = $agent.GetState($nextContext)
    
    # Agent learns
    $agent.Learn($state, $castleType, $reward, $nextState)
    
    $script:CastleCount++
    
    # Episode = every 10 castles
    if ($script:CastleCount % 10 -eq 0) {
        $agent.EndEpisode($script:EpisodeReward)
        $script:EpisodeRewards.Add($script:EpisodeReward) | Out-Null
        $script:Episode++
        $script:EpisodeReward = 0.0
    }
}

function Render-Castle($g, $castle, $groundY) {
    # Shadow
    $shadowBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(40, 0, 0, 0))
    $g.FillEllipse($shadowBrush, [int]$castle.X, $groundY+2, [int]$castle.Width, 15)
    $shadowBrush.Dispose()
    
    # Castle body
    $castleBrush = New-Object Drawing.SolidBrush($castle.Color)
    $g.FillRectangle($castleBrush, [int]$castle.X, [int]$castle.Y, [int]$castle.Width, [int]$castle.Height)
    $castleBrush.Dispose()
    
    # Towers
    foreach ($tower in $castle.Towers) {
        $tx = [int]($castle.X + $tower.X)
        $ty = [int]($castle.Y - $tower.Height + 25)
        $tw = [int]$tower.Width
        $th = [int]$tower.Height
        
        $towerBrush = New-Object Drawing.SolidBrush($castle.Color)
        $g.FillRectangle($towerBrush, $tx, $ty, $tw, $th)
        $towerBrush.Dispose()
    }
    
    # Windows
    $windowBrush = New-Object Drawing.SolidBrush($castle.WindowColor)
    for ($w = 0; $w -lt 4; $w++) {
        $wx = [int]($castle.X + (Get-Random -Minimum 15 -Maximum ($castle.Width - 20)))
        $wy = [int]($castle.Y + (Get-Random -Minimum 20 -Maximum ($castle.Height - 25)))
        $g.FillRectangle($windowBrush, $wx, $wy, 5, 8)
    }
    $windowBrush.Dispose()
    
    # Show castle type and reward (learning feedback!)
    $font = New-Object Drawing.Font("Consolas", 8)
    $textBrush = New-Object Drawing.SolidBrush([Drawing.Color]::Yellow)
    $rewardText = "$($castle.Type) (+$($castle.Reward.ToString('F1')))"
    $g.DrawString($rewardText, $font, $textBrush, [int]$castle.X, [int]($castle.Y - 15))
    $font.Dispose()
    $textBrush.Dispose()
}

# -------------------------------
# CASTLE PANEL PAINT
# -------------------------------
$castlePanel.Add_Paint({
    param($s, $e)
    
    $g = $e.Graphics
    $w = $s.Width
    $h = $s.Height
    $groundY = [int]($h * 0.7)
    
    # Sky gradient
    $skyBrush = New-Object Drawing.Drawing2D.LinearGradientBrush(
        [Drawing.Point]::new(0, 0),
        [Drawing.Point]::new(0, $groundY),
        [Drawing.Color]::FromArgb(30, 60, 110),
        [Drawing.Color]::FromArgb(10, 20, 40)
    )
    $g.FillRectangle($skyBrush, 0, 0, $w, $groundY)
    $skyBrush.Dispose()
    
    # Ground
    $groundBrush = New-Object Drawing.Drawing2D.LinearGradientBrush(
        [Drawing.Point]::new(0, $groundY),
        [Drawing.Point]::new(0, $h),
        [Drawing.Color]::FromArgb(55, 60, 70),
        [Drawing.Color]::FromArgb(25, 28, 35)
    )
    $g.FillRectangle($groundBrush, 0, $groundY, $w, $h - $groundY)
    $groundBrush.Dispose()
    
    # Update and render castles
    foreach ($c in $script:Castles) {
        if ($c.Width -eq 0) {
            Initialize-Castle $c $w $groundY
        }
        
        $c.X -= $c.Speed
        
        if ($c.X + $c.Width -lt -50) {
            Initialize-Castle $c $w $groundY
        }
        
        Render-Castle $g $c $groundY
    }
})

# -------------------------------
# STATS PANEL PAINT
# -------------------------------
$statsPanel.Add_Paint({
    param($s, $e)
    
    $g = $e.Graphics
    $stats = $agent.GetStats()
    
    $font = New-Object Drawing.Font("Consolas", 10, [Drawing.FontStyle]::Bold)
    $whiteBrush = New-Object Drawing.SolidBrush([Drawing.Color]::White)
    $greenBrush = New-Object Drawing.SolidBrush([Drawing.Color]::LimeGreen)
    $yellowBrush = New-Object Drawing.SolidBrush([Drawing.Color]::Yellow)
    $cyanBrush = New-Object Drawing.SolidBrush([Drawing.Color]::Cyan)
    
    $y = 10
    
    # Title
    $g.DrawString("Q-LEARNING STATS (Live Learning!)", $font, $cyanBrush, 10, $y)
    $y += 25
    
    # Stats
    $g.DrawString("Episode: $($script:Episode)", $font, $whiteBrush, 10, $y)
    $g.DrawString("Castles: $($script:CastleCount)", $font, $whiteBrush, 200, $y)
    $g.DrawString("Current Reward: $($script:EpisodeReward.ToString('F2'))", $font, $greenBrush, 400, $y)
    $y += 20
    
    $avgReward = if ($stats.AverageReward -ne $null) { $stats.AverageReward.ToString('F2') } else { "0.00" }
    $g.DrawString("Avg Reward: $avgReward", $font, $whiteBrush, 10, $y)
    $g.DrawString("Epsilon: $($stats.Epsilon.ToString('F3'))", $font, $yellowBrush, 200, $y)
    
    $exploitPct = if ($stats.ExplorationRatio -ne $null) { ((1.0 - $stats.ExplorationRatio) * 100).ToString('F1') } else { "0.0" }
    $g.DrawString("Exploit: $exploitPct%", $font, $yellowBrush, 400, $y)
    $g.DrawString("Q-Table: $($stats.QTableSize) entries", $font, $whiteBrush, 600, $y)
    $y += 20
    
    # Recent performance
    if ($script:EpisodeRewards.Count -gt 0) {
        $recentCount = [Math]::Min(10, $script:EpisodeRewards.Count)
        $start = $script:EpisodeRewards.Count - $recentCount
        $recentTotal = 0.0
        for ($i = $start; $i -lt $script:EpisodeRewards.Count; $i++) {
            $recentTotal += $script:EpisodeRewards[$i]
        }
        $recentAvg = $recentTotal / $recentCount
        
        $g.DrawString("Recent Avg (last $recentCount): $($recentAvg.ToString('F2'))", $font, $greenBrush, 10, $y)
        
        # Trend indicator
        if ($script:EpisodeRewards.Count -gt 10) {
            $oldAvg = 0.0
            for ($i = 0; $i -lt 10; $i++) {
                $oldAvg += $script:EpisodeRewards[$i]
            }
            $oldAvg /= 10
            
            if ($recentAvg -gt $oldAvg) {
                $g.DrawString("? IMPROVING!", $font, $greenBrush, 600, $y)
            } elseif ($recentAvg -lt $oldAvg) {
                $g.DrawString("? Declining", $font, [Drawing.Brushes]::Red, 600, $y)
            } else {
                $g.DrawString("? Stable", $font, $yellowBrush, 600, $y)
            }
        }
    }
    
    $font.Dispose()
    $whiteBrush.Dispose()
    $greenBrush.Dispose()
    $yellowBrush.Dispose()
    $cyanBrush.Dispose()
})

# -------------------------------
# TIMER
# -------------------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 50  # 20 FPS
$timer.Add_Tick({
    $castlePanel.Invalidate()
    $statsPanel.Invalidate()
})
$timer.Start()

# Show form
$form.Add_Shown({
    $form.Activate()
})

$form.ShowDialog()