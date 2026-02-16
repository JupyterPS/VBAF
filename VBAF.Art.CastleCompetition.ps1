#Requires -Version 5.1

<#
.SYNOPSIS
    Multi-Agent Castle Competition - Three RL agents compete for aesthetic space
.DESCRIPTION
    ClassicAgent, WhimsicalAgent, and ModernAgent compete to generate the most
    aesthetically pleasing castle parade. Features emergent coordination behaviors.
    
    WEEK 8 GRAND FINALE - Brings together:
    - Neural networks (from Week 1)
    - Q-Learning (from Week 2)
    - Visualization (from Week 3)
    - Multi-agent systems (from Week 6)
    - Aesthetic rewards (Option 3)
    
.NOTES
    Part of VBAF - Art/Generative Module
    The culmination of Phase 1-2!
.EXAMPLE
    
#>

# Load dependencies
$basePath = $PSScriptRoot
. (Join-Path $basePath "VBAF.RL.QTable.ps1")
. (Join-Path $basePath "VBAF.RL.ExperienceReplay.ps1")
. (Join-Path $basePath "VBAF.RL.QLearningAgent.ps1")
. (Join-Path $basePath "VBAF.Art.AestheticReward.ps1")

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==================== CASTLE AGENT SPECIALIZATIONS ====================

class CastleAgent {
    [string]$Name
    [string]$AgentType
    [System.Drawing.Color]$Color
    [string[]]$PreferredTypes
    [object]$Brain  # QLearningAgent
    [double]$TotalReward
    [int]$CastlesGenerated
    [System.Collections.ArrayList]$RewardHistory
    [System.Collections.ArrayList]$CastleHistory
    
    CastleAgent([string]$name, [string]$type, [System.Drawing.Color]$color, [string[]]$preferred) {
        $this.Name = $name
        $this.AgentType = $type
        $this.Color = $color
        $this.PreferredTypes = $preferred
        
        # All castle types available as actions
        $allTypes = @("Gothic", "FairyTale", "Cathedral", "Wizard", "Palace", "Oriental", "Fortress", "Ruins")
        $this.Brain = New-Object QLearningAgent -ArgumentList (,$allTypes), 0.15, 0.8
        
        $this.TotalReward = 0.0
        $this.CastlesGenerated = 0
        $this.RewardHistory = New-Object System.Collections.ArrayList
        $this.CastleHistory = New-Object System.Collections.ArrayList
    }
    
    # Decide which castle to generate
    [string] DecideCastle([hashtable]$context) {
        # Get state from context
        $state = $this.GetState($context)
        
        # Choose action using epsilon-greedy
        $castleType = $this.Brain.ChooseAction($state)
        
        # Bias toward preferred types (early exploration)
        if ($this.Brain.Epsilon -gt 0.5) {
            if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt 0.3) {
                # 30% chance to pick from preferred types
                $randomIndex = Get-Random -Minimum 0 -Maximum $this.PreferredTypes.Count
                $castleType = $this.PreferredTypes[$randomIndex]
            }
        }
        
        return $castleType
    }
    
    # Get state representation
    [string] GetState([hashtable]$context) {
        # State = combination of:
        # - Recent castle types (all agents)
        # - Current screen crowding
        # - Own recent performance
        
        $recentCastles = if ($context.ContainsKey("RecentCastles") -and $context.RecentCastles.Count -gt 0) {
            $context.RecentCastles[-1]
        } else {
            "EMPTY"
        }
        
        $crowding = if ($context.ContainsKey("CurrentCastleCount")) {
            if ($context.CurrentCastleCount -le 3) { "LOW" }
            elseif ($context.CurrentCastleCount -le 6) { "MED" }
            else { "HIGH" }
        } else {
            "MED"
        }
        
        return "$recentCastles|$crowding"
    }
    
    # Learn from outcome
    [void] Learn([string]$state, [string]$action, [double]$reward, [string]$nextState) {
        $this.Brain.Learn($state, $action, $reward, $nextState)
        $this.TotalReward += $reward
        $this.CastlesGenerated++
        $this.RewardHistory.Add($reward) | Out-Null
        $this.CastleHistory.Add($action) | Out-Null
    }
    
    # Get agent stats
    [hashtable] GetStats() {
        $avgReward = if ($this.CastlesGenerated -gt 0) {
            $this.TotalReward / $this.CastlesGenerated
        } else {
            0.0
        }
        
        $recentAvg = 0.0
        if ($this.RewardHistory.Count -gt 0) {
            $recentCount = [Math]::Min(10, $this.RewardHistory.Count)
            $start = $this.RewardHistory.Count - $recentCount
            $sum = 0.0
            for ($i = $start; $i -lt $this.RewardHistory.Count; $i++) {
                $sum += [double]$this.RewardHistory[$i]
            }
            $recentAvg = $sum / $recentCount
        }
        
        return @{
            Name = $this.Name
            Type = $this.AgentType
            CastlesGenerated = $this.CastlesGenerated
            TotalReward = $this.TotalReward
            AverageReward = $avgReward
            RecentAverage = $recentAvg
            Epsilon = $this.Brain.Epsilon
        }
    }
}

# ==================== COMPETITION ENVIRONMENT ====================

class CompetitionEnvironment {
    [object]$ClassicAgent
    [object]$WhimsicalAgent
    [object]$ModernAgent
    [object]$Rewarding  # AestheticReward
    
    [System.Collections.ArrayList]$AllCastles
    [System.Collections.ArrayList]$RecentCastles
    [int]$Episode
    [int]$Step
    [int]$MaxStepsPerEpisode
    
    [System.Collections.ArrayList]$EpisodeTotalRewards
    [System.Collections.ArrayList]$CoordinationScores
    
    CompetitionEnvironment() {
        # Create three competing agents
        $this.ClassicAgent = New-Object CastleAgent -ArgumentList "Classic", "Classic", `
            ([System.Drawing.Color]::FromArgb(139, 69, 19)), `
            @("Gothic", "Cathedral", "Fortress")
        
        $this.WhimsicalAgent = New-Object CastleAgent -ArgumentList "Whimsical", "Whimsical", `
            ([System.Drawing.Color]::FromArgb(255, 105, 180)), `
            @("FairyTale", "Wizard", "Palace")
        
        $this.ModernAgent = New-Object CastleAgent -ArgumentList "Modern", "Modern", `
            ([System.Drawing.Color]::FromArgb(64, 224, 208)), `
            @("Oriental", "Ruins", "Fortress")
        
        # Create aesthetic reward system
        $this.Rewarding = New-Object AestheticReward
        
        # Initialize tracking
        $this.AllCastles = New-Object System.Collections.ArrayList
        $this.RecentCastles = New-Object System.Collections.ArrayList
        $this.Episode = 0
        $this.Step = 0
        $this.MaxStepsPerEpisode = 30
        
        $this.EpisodeTotalRewards = New-Object System.Collections.ArrayList
        $this.CoordinationScores = New-Object System.Collections.ArrayList
    }
    
    # Run one step of competition
    [hashtable] RunStep() {
        $this.Step++
        
        # Build context
        $context = @{
            RecentCastles = $this.RecentCastles
            CurrentCastleCount = [Math]::Min(20, $this.RecentCastles.Count)
        }
        
        # Randomly select which agent generates this castle
        $agentChoice = Get-Random -Minimum 0 -Maximum 3
        
        if ($agentChoice -eq 0) {
            $agent = $this.ClassicAgent
        } elseif ($agentChoice -eq 1) {
            $agent = $this.WhimsicalAgent
        } else {
            $agent = $this.ModernAgent
        }
        
        # Agent decides castle type
        $state = $agent.GetState($context)
        $castleType = $agent.DecideCastle($context)
        
        # Calculate reward
        $rewardBreakdown = $this.Rewarding.CalculateReward($castleType, $context)
        $reward = $rewardBreakdown.TotalReward
        
        # Add to history
        $this.RecentCastles.Add($castleType) | Out-Null
        if ($this.RecentCastles.Count -gt 20) {
            $this.RecentCastles.RemoveAt(0)
        }
        
        $castleRecord = @{
            Agent = $agent.Name
            Type = $castleType
            Reward = $reward
            RewardBreakdown = $rewardBreakdown
            Step = $this.Step
            Color = $agent.Color
        }
        $this.AllCastles.Add($castleRecord) | Out-Null
        
        # Next state
        $nextContext = @{
            RecentCastles = $this.RecentCastles
            CurrentCastleCount = [Math]::Min(20, $this.RecentCastles.Count)
        }
        $nextState = $agent.GetState($nextContext)
        
        # Agent learns
        $agent.Learn($state, $castleType, $reward, $nextState)
        
        return $castleRecord
    }
    
    # End episode
    [void] EndEpisode() {
        # Calculate total reward for this episode
        $totalReward = 0.0
        $startIndex = [Math]::Max(0, $this.AllCastles.Count - $this.MaxStepsPerEpisode)
        
        for ($i = $startIndex; $i -lt $this.AllCastles.Count; $i++) {
            $totalReward += [double]$this.AllCastles[$i].Reward
        }
        
        $this.EpisodeTotalRewards.Add($totalReward) | Out-Null
        
        # Calculate coordination score (how well agents cooperated)
        $coordScore = $this.CalculateCoordination()
        $this.CoordinationScores.Add($coordScore) | Out-Null
        
        # Decay epsilon for all agents
        $this.ClassicAgent.Brain.EndEpisode($totalReward / 3.0)
        $this.WhimsicalAgent.Brain.EndEpisode($totalReward / 3.0)
        $this.ModernAgent.Brain.EndEpisode($totalReward / 3.0)
        
        $this.Episode++
        $this.Step = 0
    }
    
    # Calculate how well agents coordinated
    [double] CalculateCoordination() {
        if ($this.AllCastles.Count -lt 10) { return 0.5 }
        
        # Look at variety in recent castles
        $recent = New-Object System.Collections.ArrayList
        $startIndex = [Math]::Max(0, $this.AllCastles.Count - 10)
        
        for ($i = $startIndex; $i -lt $this.AllCastles.Count; $i++) {
            $recent.Add($this.AllCastles[$i].Type) | Out-Null
        }
        
        # Count unique types
        $unique = @{}
        foreach ($type in $recent) {
            $unique[$type] = $true
        }
        
        # More variety = better coordination
        $varietyScore = $unique.Count / 8.0  # 8 total types
        
        # Check agent distribution
        $agentCounts = @{ "Classic" = 0; "Whimsical" = 0; "Modern" = 0 }
        for ($i = $startIndex; $i -lt $this.AllCastles.Count; $i++) {
            $agentName = $this.AllCastles[$i].Agent
            $agentCounts[$agentName]++
        }
        
        # Balanced distribution = good coordination
        $balanced = 1.0
        foreach ($count in $agentCounts.Values) {
            $ratio = $count / 10.0
            if ($ratio -lt 0.2 -or $ratio -gt 0.5) {
                $balanced -= 0.2
            }
        }
        $balanced = [Math]::Max(0.0, $balanced)
        
        return ($varietyScore + $balanced) / 2.0
    }
    
    # Get statistics
    [hashtable] GetStats() {
        return @{
            Episode = $this.Episode
            Step = $this.Step
            TotalCastles = $this.AllCastles.Count
            Classic = $this.ClassicAgent.GetStats()
            Whimsical = $this.WhimsicalAgent.GetStats()
            Modern = $this.ModernAgent.GetStats()
            EpisodeTotalRewards = $this.EpisodeTotalRewards
            CoordinationScores = $this.CoordinationScores
        }
    }
}

# ==================== VISUALIZATION ====================

$global:env = New-Object CompetitionEnvironment
$global:running = $false

function Draw-CompetitionDashboard {
    param($g, $width, $height)
    
    # Background
    $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 20))
    $g.FillRectangle($bgBrush, 0, 0, $width, $height)
    $bgBrush.Dispose()
    
    # Title
    $titleFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gold)
    $g.DrawString("CASTLE COMPETITION - Three Agents Battle for Aesthetic Space", $titleFont, $titleBrush, 10, 10)
    $titleFont.Dispose()
    $titleBrush.Dispose()
    
    # Stats
    $stats = $global:env.GetStats()
    $font = New-Object System.Drawing.Font("Consolas", 9)
    
    # Agent stats (top section)
    $y = 50
    
    # Classic Agent
    $classicBrush = New-Object System.Drawing.SolidBrush($global:env.ClassicAgent.Color)
    $text = "CLASSIC: Castles: $($stats.Classic.CastlesGenerated) | Avg: $([Math]::Round($stats.Classic.RecentAverage, 2)) | e: $([Math]::Round($stats.Classic.Epsilon, 3))"
    $g.DrawString($text, $font, $classicBrush, 10, $y)
    $classicBrush.Dispose()
    
    # Whimsical Agent
    $whimBrush = New-Object System.Drawing.SolidBrush($global:env.WhimsicalAgent.Color)
    $text = "WHIMSICAL: Castles: $($stats.Whimsical.CastlesGenerated) | Avg: $([Math]::Round($stats.Whimsical.RecentAverage, 2)) | e: $([Math]::Round($stats.Whimsical.Epsilon, 3))"
    $g.DrawString($text, $font, $whimBrush, 10, $y + 20)
    $whimBrush.Dispose()
    
    # Modern Agent
    $modernBrush = New-Object System.Drawing.SolidBrush($global:env.ModernAgent.Color)
    $text = "MODERN: Castles: $($stats.Modern.CastlesGenerated) | Avg: $([Math]::Round($stats.Modern.RecentAverage, 2)) | e: $([Math]::Round($stats.Modern.Epsilon, 3))"
    $g.DrawString($text, $font, $modernBrush, 10, $y + 40)
    $modernBrush.Dispose()
    
    # Episode info
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $text = "Episode: $($stats.Episode) | Step: $($stats.Step)/$($global:env.MaxStepsPerEpisode) | Total Castles: $($stats.TotalCastles)"
    $g.DrawString($text, $font, $whiteBrush, 10, $y + 70)
    
    # Recent castles parade (visual representation)
    $paradeY = 150
    $castleWidth = 40
    $castleHeight = 60
    $spacing = 5
    
    $labelFont = New-Object System.Drawing.Font("Arial", 7)
    $blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    
    $recentCount = [Math]::Min(30, $global:env.AllCastles.Count)
    $startIndex = [Math]::Max(0, $global:env.AllCastles.Count - $recentCount)
    
    for ($i = 0; $i -lt $recentCount; $i++) {
        $castle = $global:env.AllCastles[$startIndex + $i]
        $x = 10 + ($i * ($castleWidth + $spacing))
        
        # Draw castle rectangle with agent color
        $agentBrush = New-Object System.Drawing.SolidBrush($castle.Color)
        $g.FillRectangle($agentBrush, $x, $paradeY, $castleWidth, $castleHeight)
        $agentBrush.Dispose()
        
        # Border
        $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 1)
        $g.DrawRectangle($borderPen, $x, $paradeY, $castleWidth, $castleHeight)
        $borderPen.Dispose()
        
        # Type label
        $shortType = $castle.Type.Substring(0, [Math]::Min(4, $castle.Type.Length))
        $g.DrawString($shortType, $labelFont, $blackBrush, $x + 2, $paradeY + 5)
        
        # Reward indicator (height bar)
        $rewardHeight = [Math]::Min(50, $castle.Reward * 5)
        $rewardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Lime)
        $g.FillRectangle($rewardBrush, $x + 2, $paradeY + $castleHeight - $rewardHeight - 2, 8, $rewardHeight)
        $rewardBrush.Dispose()
    }
    
    $labelFont.Dispose()
    $blackBrush.Dispose()
    
    # Reward history graph
    if ($stats.EpisodeTotalRewards.Count -gt 1) {
        $graphY = 250
        $graphHeight = 150
        $graphWidth = $width - 40
        
        # Grid
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 40, 40))
        for ($i = 0; $i -le 5; $i++) {
            $gridY = $graphY + ($graphHeight * $i / 5)
            $g.DrawLine($gridPen, 20, $gridY, 20 + $graphWidth, $gridY)
        }
        $gridPen.Dispose()
        
        # Reward line
        $points = New-Object System.Collections.ArrayList
        $maxReward = ($stats.EpisodeTotalRewards | Measure-Object -Maximum).Maximum
        if ($maxReward -eq 0) { $maxReward = 1 }
        
        for ($i = 0; $i -lt $stats.EpisodeTotalRewards.Count; $i++) {
            $x = 20 + ($i / [Math]::Max(1, $stats.EpisodeTotalRewards.Count - 1)) * $graphWidth
            $y = $graphY + $graphHeight - (($stats.EpisodeTotalRewards[$i] / $maxReward) * $graphHeight)
            $point = New-Object System.Drawing.PointF($x, $y)
            $points.Add($point) | Out-Null
        }
        
        if ($points.Count -gt 1) {
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gold, 3)
            $g.DrawLines($pen, $points.ToArray([System.Drawing.PointF]))
            $pen.Dispose()
        }
        
        $g.DrawString("Episode Total Rewards (Learning Progress)", $font, $whiteBrush, 20, $graphY - 20)
    }
    
    # Coordination score graph
    if ($stats.CoordinationScores.Count -gt 1) {
        $graphY = 430
        $graphHeight = 100
        $graphWidth = $width - 40
        
        # Grid
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 40, 40))
        for ($i = 0; $i -le 4; $i++) {
            $gridY = $graphY + ($graphHeight * $i / 4)
            $g.DrawLine($gridPen, 20, $gridY, 20 + $graphWidth, $gridY)
        }
        $gridPen.Dispose()
        
        # Coordination line
        $points = New-Object System.Collections.ArrayList
        
        for ($i = 0; $i -lt $stats.CoordinationScores.Count; $i++) {
            $x = 20 + ($i / [Math]::Max(1, $stats.CoordinationScores.Count - 1)) * $graphWidth
            $y = $graphY + $graphHeight - (($stats.CoordinationScores[$i]) * $graphHeight)
            $point = New-Object System.Drawing.PointF($x, $y)
            $points.Add($point) | Out-Null
        }
        
        if ($points.Count -gt 1) {
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
            $g.DrawLines($pen, $points.ToArray([System.Drawing.PointF]))
            $pen.Dispose()
        }
        
        $g.DrawString("Coordination Score (Emergent Cooperation)", $font, $whiteBrush, 20, $graphY - 20)
    }
    
    $font.Dispose()
    $whiteBrush.Dispose()
}

# ==================== MAIN FORM ====================

Write-Host "`n      - oo00oo - " -ForegroundColor Yellow
Write-Host "CASTLE COMPETITION - WEEK 8 GRAND FINALE" -ForegroundColor Cyan
Write-Host "      - oo00oo - `n" -ForegroundColor Yellow
Write-Host "Three agents compete for aesthetic space:" -ForegroundColor Green
Write-Host "  • Classic Agent (Brown) - Prefers Gothic, Cathedral, Fortress" -ForegroundColor DarkYellow
Write-Host "  • Whimsical Agent (Pink) - Prefers FairyTale, Wizard, Palace" -ForegroundColor Magenta
Write-Host "  • Modern Agent (Cyan) - Prefers Oriental, Ruins, Fortress" -ForegroundColor Cyan
Write-Host "`nWatch them learn to coordinate!`n" -ForegroundColor Yellow

$form = New-Object System.Windows.Forms.Form
$form.Text = "VBAF Castle Competition - Multi-Agent RL Arena"
$form.Width = 1400
$form.Height = 650
$form.BackColor = [System.Drawing.Color]::Black
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.TopMost = $true

# Main panel
$mainPanel = New-Object System.Windows.Forms.Panel
$mainPanel.Left = 0
$mainPanel.Top = 50
$mainPanel.Width = 1400
$mainPanel.Height = 560
$mainPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$form.Controls.Add($mainPanel)

# Enable double buffering
$prop = $mainPanel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance,NonPublic")
$prop.SetValue($mainPanel, $true, $null)

$mainPanel.Add_Paint({
    param($sender, $e)
    Draw-CompetitionDashboard $e.Graphics $sender.Width $sender.Height
})

# Start button
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start Competition"
$startButton.Left = 10
$startButton.Top = 10
$startButton.Width = 160
$startButton.Height = 30
$startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 80)
$startButton.ForeColor = [System.Drawing.Color]::White
$startButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$startButton.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$startButton.Add_Click({
    if (-not $global:running) {
        $global:running = $true
        $startButton.Text = "Pause"
        $startButton.BackColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
    } else {
        $global:running = $false
        $startButton.Text = "Resume"
        $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 80)
    }
})
$form.Controls.Add($startButton)

# Reset button
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Text = "Reset"
$resetButton.Left = 180
$resetButton.Top = 10
$resetButton.Width = 100
$resetButton.Height = 30
$resetButton.BackColor = [System.Drawing.Color]::FromArgb(220, 50, 50)
$resetButton.ForeColor = [System.Drawing.Color]::White
$resetButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$resetButton.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$resetButton.Add_Click({
    $global:running = $false
    $global:env = New-Object CompetitionEnvironment
    $startButton.Text = "Start Competition"
    $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 80)
    $mainPanel.Invalidate()
})
$form.Controls.Add($resetButton)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready - Press Start to begin the competition!"
$statusLabel.Left = 300
$statusLabel.Top = 15
$statusLabel.Width = 1000
$statusLabel.ForeColor = [System.Drawing.Color]::Gold
$statusLabel.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($statusLabel)

# Update timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100  # 10 steps per second
$timer.Add_Tick({
    if ($global:running) {
        # Run one step
        $result = $global:env.RunStep()
        
        # Check if episode complete
        if ($global:env.Step -ge $global:env.MaxStepsPerEpisode) {
            $global:env.EndEpisode()
        }
        
        # Update status
        $stats = $global:env.GetStats()
        $statusLabel.Text = "Episode: $($stats.Episode) | Step: $($stats.Step) | Last: $($result.Agent) -($result.Type) (Reward: $([Math]::Round($result.Reward, 2)))"
    }
    
    # Redraw
    $mainPanel.Invalidate()
})
$timer.Start()

Write-Host "  Competition arena ready!" -ForegroundColor Green
Write-Host "      - oo00oo - `n" -ForegroundColor Yellow

$form.ShowDialog()
$timer.Stop()