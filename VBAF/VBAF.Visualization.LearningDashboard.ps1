#Requires -Version 5.1
# Dashboard 1
<#
.SYNOPSIS
    Learning Dashboard for visualizing ML/RL training
.DESCRIPTION
    Real-time visualization of neural network and RL agent training.
    Shows learning curves, Q-values, statistics, and more.
.NOTES
    Part of VBAF (Visual Business Automation Framework)
    FIXED VERSION - Completely isolated arithmetic
#>

# Set base path
$basePath = $PSScriptRoot

# Load dependencies
. "$basePath\VBAF.Visualization.MetricsCollector.ps1"
. "$basePath\VBAF.Visualization.GraphRenderer.ps1"

class LearningDashboard {
    # Properties
    [System.Windows.Forms.Form]$Form
    [System.Windows.Forms.Panel]$MainPanel
    [MetricsCollector]$Metrics
    [hashtable]$Config
    [System.Windows.Forms.Timer]$UpdateTimer
    [bool]$AutoUpdate
    
    # Constructor
    LearningDashboard([string]$title, [int]$width, [int]$height) {
        $this.Metrics = New-Object MetricsCollector
        $this.AutoUpdate = $true
        
        # Default config
        $this.Config = @{
            Width = $width
            Height = $height
            Title = $title
            UpdateInterval = 100  # ms
            MovingAverageWindow = 10
            ShowGrid = $true
        }
        
        $this.InitializeForm()
    }
    
    # Simplified constructor
    LearningDashboard([string]$title) {
        $this.Metrics = New-Object MetricsCollector
        $this.AutoUpdate = $true
        
        $this.Config = @{
            Width = 1400
            Height = 800
            Title = $title
            UpdateInterval = 100
            MovingAverageWindow = 10
            ShowGrid = $true
        }
        
        $this.InitializeForm()
    }
    
    # Initialize WinForms UI
    [void] InitializeForm() {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        # Create form
        $this.Form = New-Object System.Windows.Forms.Form
        $this.Form.Text = $this.Config.Title
        $this.Form.Width = $this.Config.Width
        $this.Form.Height = $this.Config.Height
        $this.Form.StartPosition = 'CenterScreen'
        $this.Form.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)
        
        # Main panel
        $this.MainPanel = New-Object System.Windows.Forms.Panel
        $this.MainPanel.Dock = 'Fill'
        $this.MainPanel.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 30)
        $this.Form.Controls.Add($this.MainPanel)
        
        # Enable double buffering
        $prop = $this.MainPanel.GetType().GetProperty("DoubleBuffered", 
            [System.Reflection.BindingFlags]"Instance,NonPublic")
        $prop.SetValue($this.MainPanel, $true, $null)
        
        # Paint event
        $self = $this
        $this.MainPanel.Add_Paint({
            param($sender, $e)
            try {
                # CRITICAL FIX: Extract scalar values from sender properties
                $w = $sender.Width
                $h = $sender.Height
                
                # Force to int in case they're wrapped
                if ($w -is [array]) { $w = [int]$w[0] } else { $w = [int]$w }
                if ($h -is [array]) { $h = [int]$h[0] } else { $h = [int]$h }
                
                $self.RenderDashboard($e.Graphics, $w, $h)
            } catch {
                Write-Host "Paint error: $_" -ForegroundColor Red
                Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
            }
        }.GetNewClosure())
        
        # Update timer
        $this.UpdateTimer = New-Object System.Windows.Forms.Timer
        $this.UpdateTimer.Interval = $this.Config.UpdateInterval
        $this.UpdateTimer.Add_Tick({
            if ($self.AutoUpdate) {
                $self.MainPanel.Invalidate()
            }
        }.GetNewClosure())
        
        # Keyboard shortcuts
        $this.Form.KeyPreview = $true
        $this.Form.Add_KeyDown({
            param($sender, $e)
            
            if ($e.KeyCode -eq 'Space') {
                $self.AutoUpdate = -not $self.AutoUpdate
                $self.MainPanel.Invalidate()
            }
            elseif ($e.KeyCode -eq 'R') {
                $self.Metrics.Reset()
                $self.MainPanel.Invalidate()
            }
        }.GetNewClosure())
    }
    
    # Render the complete dashboard
    [void] RenderDashboard([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        # Force scalar values
        if ($width -is [array]) { 
            $w = [int]$width[0] 
        } else { 
            $w = [int]$width 
        }
        
        if ($height -is [array]) { 
            $h = [int]$height[0] 
        } else { 
            $h = [int]$height 
        }
        
        # Clear background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 30))
        $g.FillRectangle($bgBrush, 0, 0, $w, $h)
        $bgBrush.Dispose()
        
        # Calculate layout using Math.Floor to avoid any operator issues
        $halfWidth = [Math]::Floor($w / 2.0)
        $halfHeight = [Math]::Floor($h / 2.0)
        
        # Top-left: Error/Loss graph
        $bounds1 = New-Object System.Drawing.Rectangle(10, 10, ($halfWidth - 20), ($halfHeight - 20))
        if ($this.Metrics.ErrorHistory.Count -gt 0) {
            [GraphRenderer]::DrawLineGraph($g, $bounds1, $this.Metrics.ErrorHistory, 
                "Training Error/Loss", [System.Drawing.Color]::Red)
        } else {
            [GraphRenderer]::DrawLineGraph($g, $bounds1, $this.Metrics.LossHistory, 
                "Training Loss", [System.Drawing.Color]::OrangeRed)
        }
        
        # Top-right: Reward graph
        $bounds2 = New-Object System.Drawing.Rectangle(($halfWidth + 10), 10, ($halfWidth - 20), ($halfHeight - 20))
        [GraphRenderer]::DrawLineGraph($g, $bounds2, $this.Metrics.RewardHistory, 
            "Episode Rewards", [System.Drawing.Color]::LimeGreen)
        
        # Bottom-left: Epsilon/Exploration graph
        $bounds3 = New-Object System.Drawing.Rectangle(10, ($halfHeight + 10), ($halfWidth - 20), ($halfHeight - 20))
        [GraphRenderer]::DrawLineGraph($g, $bounds3, $this.Metrics.EpsilonHistory, 
            "Epsilon (Exploration Rate)", [System.Drawing.Color]::Yellow)
        
        # Bottom-right: Statistics summary
        $bounds4 = New-Object System.Drawing.Rectangle(($halfWidth + 10), ($halfHeight + 10), 
            ($halfWidth - 20), ($halfHeight - 20))
        $this.RenderStatistics($g, $bounds4)
        
        # Header
        $this.RenderHeader($g, $w)
        
        # Footer
        $this.RenderFooter($g, $w, $h)
    }
    
    # Render header
    [void] RenderHeader([System.Drawing.Graphics]$g, [int]$width) {
        $headerFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $headerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
         
        $title = "                                                                                                                                                 VBAF LEARNING DASHBOARD"
        $titleSize = $g.MeasureString($title, $headerFont)
        $titleX = ($width - $titleSize.Width) / 2
        
        $g.DrawString($title, $headerFont, $headerBrush, $titleX, 10)
        
        $headerFont.Dispose()
        $headerBrush.Dispose()
        
        # Auto-update indicator
        $statusFont = New-Object System.Drawing.Font("Consolas", 9)
        $statusBrush = New-Object System.Drawing.SolidBrush(
            $(if ($this.AutoUpdate) { [System.Drawing.Color]::LimeGreen } else { [System.Drawing.Color]::Red })
        )
        $statusText = if ($this.AutoUpdate) { "? LIVE" } else { "? PAUSED" }
        $g.DrawString($statusText, $statusFont, $statusBrush, $width - 100, 15)
        $statusFont.Dispose()
        $statusBrush.Dispose()
    }
    
    # Render footer with controls help
    [void] RenderFooter([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $footerFont = New-Object System.Drawing.Font("Consolas", 9)
        $footerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
        
        $helpText = "Controls: [SPACE] Pause/Resume  |  [R] Reset"
        $textSize = $g.MeasureString($helpText, $footerFont)
        $textX = ($width - $textSize.Width) / 2
        
        $g.DrawString($helpText, $footerFont, $footerBrush, $textX, $height - 25)
        
        $footerFont.Dispose()
        $footerBrush.Dispose()
    }
    
    # Render statistics panel
    [void] RenderStatistics([System.Drawing.Graphics]$g, [System.Drawing.Rectangle]$bounds) {
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 40))
        $g.FillRectangle($bgBrush, $bounds)
        $bgBrush.Dispose()
        
        # Border
        $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 60, 80), 1)
        $g.DrawRectangle($borderPen, $bounds)
        $borderPen.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("STATISTICS SUMMARY", $titleFont, $titleBrush, $bounds.X + 10, $bounds.Y + 5)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Get summary
        $summary = $this.Metrics.GetSummary()
        
        # Render stats
        $font = New-Object System.Drawing.Font("Consolas", 10)
        $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::LightGray)
        $valueBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        
        $y = $bounds.Y + 35
        $lineHeight = 25
        
        try {
            # Error stats
            if ($summary.Error.Count -gt 0) {
                $g.DrawString("Error:", $font, $labelBrush, $bounds.X + 20, $y)
                $errorText = "Min: $($summary.Error.Min.ToString('F4'))  Max: $($summary.Error.Max.ToString('F4'))  Avg: $($summary.Error.Mean.ToString('F4'))"
                $g.DrawString($errorText, $font, $valueBrush, $bounds.X + 120, $y)
                $y += $lineHeight
            }
            
            # Reward stats
            if ($summary.Reward.Count -gt 0) {
                $g.DrawString("Reward:", $font, $labelBrush, $bounds.X + 20, $y)
                $rewardText = "Min: $($summary.Reward.Min.ToString('F2'))  Max: $($summary.Reward.Max.ToString('F2'))  Avg: $($summary.Reward.Mean.ToString('F2'))"
                $g.DrawString($rewardText, $font, $valueBrush, $bounds.X + 120, $y)
                $y += $lineHeight
            }
            
            # Epsilon stats
            if ($summary.Epsilon.Count -gt 0) {
                $g.DrawString("Epsilon:", $font, $labelBrush, $bounds.X + 20, $y)
                $epsilonText = "Current: $($summary.Epsilon.Latest.ToString('F4'))  (Exploration Rate)"
                $g.DrawString($epsilonText, $font, $valueBrush, $bounds.X + 120, $y)
                $y += $lineHeight
            }
            
            # Data points
            $y += 10
            $g.DrawString("Total Data Points:", $font, $labelBrush, $bounds.X + 20, $y)
            $g.DrawString($summary.TotalDataPoints.ToString(), $font, $valueBrush, $bounds.X + 220, $y)
            $y += $lineHeight
            
            # Trend analysis - Using Measure-Object for safety
            if ($this.Metrics.RewardHistory.Count -gt 20) {
                # Get last 10 values
                $recentStart = $this.Metrics.RewardHistory.Count - 10
                $recentValues = @()
                for ($i = $recentStart; $i -lt $this.Metrics.RewardHistory.Count; $i++) {
                    $recentValues += [double]$this.Metrics.RewardHistory[$i]
                }
                $recentStats = $recentValues | Measure-Object -Average
                $recentAvg = $recentStats.Average
                
                # Get first 10 values
                $oldValues = @()
                for ($i = 0; $i -lt 10; $i++) {
                    $oldValues += [double]$this.Metrics.RewardHistory[$i]
                }
                $oldStats = $oldValues | Measure-Object -Average
                $oldAvg = $oldStats.Average
                
                # Calculate improvement
                if ([Math]::Abs($oldAvg) -gt 0.0001) {
                    $improvement = (($recentAvg - $oldAvg) / [Math]::Abs($oldAvg)) * 100.0
                    
                    $y += 10
                    $g.DrawString("Trend:", $font, $labelBrush, $bounds.X + 20, $y)
                    
                    $trendColor = if ($improvement -gt 0) { 
                        [System.Drawing.Color]::LimeGreen 
                    } else { 
                        [System.Drawing.Color]::Red 
                    }
                    $trendBrush = New-Object System.Drawing.SolidBrush($trendColor)
                    
                    $trendText = if ($improvement -gt 0) {
                        "? IMPROVING (+$($improvement.ToString('F1'))%)"
                    } else {
                        "? Declining ($($improvement.ToString('F1'))%)"
                    }
                    
                    $g.DrawString($trendText, $font, $trendBrush, $bounds.X + 120, $y)
                    $trendBrush.Dispose()
                }
            }
        } catch {
            $errorBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
            $errorMsg = "Stats error: $($_.Exception.Message)"
            $g.DrawString($errorMsg, $font, $errorBrush, $bounds.X + 20, $y)
            $errorBrush.Dispose()
            Write-Host "Stats rendering error: $_" -ForegroundColor Red
        }
        
        $font.Dispose()
        $labelBrush.Dispose()
        $valueBrush.Dispose()
    }
    
    # Add data from neural network training
    [void] UpdateFromNeuralNetwork([hashtable]$trainingData) {
        if ($trainingData.ContainsKey('Error')) {
            $this.Metrics.RecordError($trainingData.Error)
        }
        if ($trainingData.ContainsKey('Loss')) {
            $this.Metrics.RecordLoss($trainingData.Loss)
        }
        if ($trainingData.ContainsKey('Accuracy')) {
            $this.Metrics.RecordAccuracy($trainingData.Accuracy)
        }
    }
    
    # Add data from RL agent
    [void] UpdateFromRLAgent([hashtable]$agentStats) {
        if ($agentStats.ContainsKey('Reward')) {
            $this.Metrics.RecordReward($agentStats.Reward)
        }
        if ($agentStats.ContainsKey('Epsilon')) {
            $this.Metrics.RecordEpsilon($agentStats.Epsilon)
        }
    }
    
    # Start the dashboard
    [void] Show() {
        $this.UpdateTimer.Start()
        $this.Form.ShowDialog()
    }
    
    # Show non-blocking
    [void] ShowNonBlocking() {
        $this.UpdateTimer.Start()
        $this.Form.Show()
    }
    
    # Stop updates
    [void] Stop() {
        $this.UpdateTimer.Stop()
    }
    
    # Force refresh
    [void] Refresh() {
        $this.MainPanel.Invalidate()
    }

}

