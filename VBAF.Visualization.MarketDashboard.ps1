#Requires -Version 5.1
# VBAF.Visualization.MarketDashboard.ps1
# Dashboard 2 - WALL STREET EDITION
<#
.SYNOPSIS
    Wall Street-style market dashboard for multi-agent simulation
.DESCRIPTION
    Bloomberg Terminal aesthetic: Central profit graph surrounded by info panels.
    Shows market share, economic indicators, decisions, events, and learning stats.
.NOTES
    Part of VBAF (Visual Business Automation Framework)
    WALL STREET EDITION - Professional trading floor aesthetic
#>

class MarketDashboard {
    # Form and panels
    [System.Windows.Forms.Form]$Form
    
    # Info panels (surrounding the main graph)
    [System.Windows.Forms.Panel]$PanelMarketShare      # Top-left
    [System.Windows.Forms.Panel]$PanelQuarterInfo      # Top-center
    [System.Windows.Forms.Panel]$PanelEconomic         # Top-right
    [System.Windows.Forms.Panel]$PanelDecisions        # Middle-right
    [System.Windows.Forms.Panel]$PanelLearning         # Bottom-right
    [System.Windows.Forms.Panel]$PanelEvents           # Bottom-left
    
    # MAIN GRAPH (center stage)
    [System.Windows.Forms.Panel]$PanelMainGraph
    
    # Control panel
    [System.Windows.Forms.Panel]$ControlPanel
    
    # Controls
    [System.Windows.Forms.Button]$BtnPlay
    [System.Windows.Forms.TrackBar]$SpeedSlider
    [System.Windows.Forms.Label]$SpeedLabel
    
    # Data source
    $Market  # MarketEnvironment object
    
    # History tracking
    [System.Collections.ArrayList]$ProfitHistory
    [System.Collections.ArrayList]$MarketShareHistory
    [System.Collections.ArrayList]$EventLog
    [System.Collections.ArrayList]$DecisionHistory
    
    # Animation
    [System.Windows.Forms.Timer]$Timer
    [bool]$IsPlaying
    [int]$Speed  # 1-10
    
    # Colors (Wall Street neon palette)
    [hashtable]$CompanyColors
    
    # Constructor
    MarketDashboard($marketEnvironment) {
        $this.Market = $marketEnvironment
        $this.ProfitHistory = New-Object System.Collections.ArrayList
        $this.MarketShareHistory = New-Object System.Collections.ArrayList
        $this.EventLog = New-Object System.Collections.ArrayList
        $this.DecisionHistory = New-Object System.Collections.ArrayList
        $this.IsPlaying = $false
        $this.Speed = 1
        
        # Wall Street color palette
        $this.CompanyColors = @{
            0 = [System.Drawing.Color]::FromArgb(0, 255, 255)    # Cyan
            1 = [System.Drawing.Color]::FromArgb(255, 128, 0)    # Orange
            2 = [System.Drawing.Color]::FromArgb(0, 255, 128)    # Lime
            3 = [System.Drawing.Color]::FromArgb(255, 0, 255)    # Magenta
        }
        
        $this.InitializeForm()
        $this.InitializePanels()
        $this.InitializeControls()
        $this.InitializeTimer()
        
        $this.LogEvent("🔔 Dashboard initialized - Wall Street mode activated!")
    }
    
    [void] InitializeForm() {
        $this.Form = New-Object System.Windows.Forms.Form
        $this.Form.Width = 1600
        $this.Form.Height = 1000
        $this.Form.Text = "VBAF Market Dashboard - Wall Street Edition"
        $this.Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $this.Form.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 10)  # Pure black
        $this.Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $this.Form.MaximizeBox = $false
    }
    
    [void] InitializePanels() {
        $dashboard = $this
        
        # === TOP ROW (3 info panels) ===
        
        # Market Share (top-left)
        $this.PanelMarketShare = New-Object System.Windows.Forms.Panel
        $this.PanelMarketShare.Location = New-Object System.Drawing.Point(10, 10)
        $this.PanelMarketShare.Size = New-Object System.Drawing.Size(380, 180)
        $this.PanelMarketShare.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25)
        $this.PanelMarketShare.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.PanelMarketShare)
        $this.PanelMarketShare.Add_Paint({ param($s, $e) $dashboard.DrawMarketSharePanel($s, $e) })
        $this.Form.Controls.Add($this.PanelMarketShare)
        
        # Quarter Info (top-center)
        $this.PanelQuarterInfo = New-Object System.Windows.Forms.Panel
        $this.PanelQuarterInfo.Location = New-Object System.Drawing.Point(400, 10)
        $this.PanelQuarterInfo.Size = New-Object System.Drawing.Size(380, 180)
        $this.PanelQuarterInfo.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25)
        $this.PanelQuarterInfo.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.PanelQuarterInfo)
        $this.PanelQuarterInfo.Add_Paint({ param($s, $e) $dashboard.DrawQuarterInfoPanel($s, $e) })
        $this.Form.Controls.Add($this.PanelQuarterInfo)
        
        # Economic Indicators (top-right)
        $this.PanelEconomic = New-Object System.Windows.Forms.Panel
        $this.PanelEconomic.Location = New-Object System.Drawing.Point(790, 10)
        $this.PanelEconomic.Size = New-Object System.Drawing.Size(380, 180)
        $this.PanelEconomic.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25)
        $this.PanelEconomic.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.PanelEconomic)
        $this.PanelEconomic.Add_Paint({ param($s, $e) $dashboard.DrawEconomicPanel($s, $e) })
        $this.Form.Controls.Add($this.PanelEconomic)
        
        # === MAIN GRAPH (center stage) ===
        
        $this.PanelMainGraph = New-Object System.Windows.Forms.Panel
        $this.PanelMainGraph.Location = New-Object System.Drawing.Point(10, 200)
        $this.PanelMainGraph.Size = New-Object System.Drawing.Size(1160, 520)
        $this.PanelMainGraph.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 20)
        $this.PanelMainGraph.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.PanelMainGraph)
        $this.PanelMainGraph.Add_Paint({ param($s, $e) $dashboard.DrawMainGraph($s, $e) })
        $this.Form.Controls.Add($this.PanelMainGraph)
        
        # === RIGHT COLUMN (2 info panels) ===
        
        # Recent Decisions (middle-right)
        $this.PanelDecisions = New-Object System.Windows.Forms.Panel
        $this.PanelDecisions.Location = New-Object System.Drawing.Point(1180, 200)
        $this.PanelDecisions.Size = New-Object System.Drawing.Size(390, 260)
        $this.PanelDecisions.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25)
        $this.PanelDecisions.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.PanelDecisions)
        $this.PanelDecisions.Add_Paint({ param($s, $e) $dashboard.DrawDecisionsPanel($s, $e) })
        $this.Form.Controls.Add($this.PanelDecisions)
        
        # Learning Stats (bottom-right)
        $this.PanelLearning = New-Object System.Windows.Forms.Panel
        $this.PanelLearning.Location = New-Object System.Drawing.Point(1180, 470)
        $this.PanelLearning.Size = New-Object System.Drawing.Size(390, 250)
        $this.PanelLearning.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25)
        $this.PanelLearning.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.PanelLearning)
        $this.PanelLearning.Add_Paint({ param($s, $e) $dashboard.DrawLearningPanel($s, $e) })
        $this.Form.Controls.Add($this.PanelLearning)
        
        # === BOTTOM (Event Log) ===
        
        $this.PanelEvents = New-Object System.Windows.Forms.Panel
        $this.PanelEvents.Location = New-Object System.Drawing.Point(10, 730)
        $this.PanelEvents.Size = New-Object System.Drawing.Size(1560, 160)
        $this.PanelEvents.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25)
        $this.PanelEvents.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.PanelEvents)
        $this.PanelEvents.Add_Paint({ param($s, $e) $dashboard.DrawEventsPanel($s, $e) })
        $this.Form.Controls.Add($this.PanelEvents)
        
        # === CONTROL PANEL ===
        
        $this.ControlPanel = New-Object System.Windows.Forms.Panel
        $this.ControlPanel.Location = New-Object System.Drawing.Point(10, 900)
        $this.ControlPanel.Size = New-Object System.Drawing.Size(1560, 50)
        $this.ControlPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
        $this.ControlPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.Form.Controls.Add($this.ControlPanel)
    }
    
    [void] EnableDoubleBuffering($panel) {
        $prop = $panel.GetType().GetProperty("DoubleBuffered", 
            [System.Reflection.BindingFlags]"Instance,NonPublic")
        $prop.SetValue($panel, $true, $null)
    }
    
    [void] InitializeControls() {
        $dashboard = $this
        
        # Play/Pause Button
        $this.BtnPlay = New-Object System.Windows.Forms.Button
        $this.BtnPlay.Location = New-Object System.Drawing.Point(20, 10)
        $this.BtnPlay.Size = New-Object System.Drawing.Size(100, 30)
        $this.BtnPlay.Text = "▶ PLAY"
        $this.BtnPlay.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
        $this.BtnPlay.ForeColor = [System.Drawing.Color]::White
        $this.BtnPlay.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $this.BtnPlay.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $this.BtnPlay.Add_Click({ $dashboard.TogglePlay() })
        $this.ControlPanel.Controls.Add($this.BtnPlay)
        
        # Step Button
        $btnStep = New-Object System.Windows.Forms.Button
        $btnStep.Location = New-Object System.Drawing.Point(130, 10)
        $btnStep.Size = New-Object System.Drawing.Size(100, 30)
        $btnStep.Text = "⏭ STEP"
        $btnStep.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 100)
        $btnStep.ForeColor = [System.Drawing.Color]::White
        $btnStep.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnStep.Font = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $btnStep.Add_Click({ $dashboard.StepQuarter() })
        $this.ControlPanel.Controls.Add($btnStep)
        
        # Reset Button
        $btnReset = New-Object System.Windows.Forms.Button
        $btnReset.Location = New-Object System.Drawing.Point(240, 10)
        $btnReset.Size = New-Object System.Drawing.Size(100, 30)
        $btnReset.Text = "🔄 RESET"
        $btnReset.BackColor = [System.Drawing.Color]::FromArgb(180, 0, 0)
        $btnReset.ForeColor = [System.Drawing.Color]::White
        $btnReset.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnReset.Font = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $btnReset.Add_Click({ $dashboard.ResetSimulation() })
        $this.ControlPanel.Controls.Add($btnReset)
        
        # Speed Label
        $this.SpeedLabel = New-Object System.Windows.Forms.Label
        $this.SpeedLabel.Location = New-Object System.Drawing.Point(370, 15)
        $this.SpeedLabel.Size = New-Object System.Drawing.Size(100, 20)
        $this.SpeedLabel.Text = "SPEED: 1x"
        $this.SpeedLabel.ForeColor = [System.Drawing.Color]::Cyan
        $this.SpeedLabel.Font = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $this.ControlPanel.Controls.Add($this.SpeedLabel)
        
        # Speed Slider
        $this.SpeedSlider = New-Object System.Windows.Forms.TrackBar
        $this.SpeedSlider.Location = New-Object System.Drawing.Point(480, 5)
        $this.SpeedSlider.Size = New-Object System.Drawing.Size(250, 40)
        $this.SpeedSlider.Minimum = 1
        $this.SpeedSlider.Maximum = 10
        $this.SpeedSlider.Value = 1
        $this.SpeedSlider.TickFrequency = 1
        $this.SpeedSlider.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
        $this.SpeedSlider.Add_ValueChanged({ 
            $dashboard.Speed = $dashboard.SpeedSlider.Value
            $dashboard.SpeedLabel.Text = "SPEED: $($dashboard.Speed)x"
            if ($dashboard.IsPlaying) {
                $dashboard.Timer.Interval = [Math]::Max(100, (1000 / $dashboard.Speed))
            }
        })
        $this.ControlPanel.Controls.Add($this.SpeedSlider)
        
        # Export Button
        $btnExport = New-Object System.Windows.Forms.Button
        $btnExport.Location = New-Object System.Drawing.Point(1430, 10)
        $btnExport.Size = New-Object System.Drawing.Size(100, 30)
        $btnExport.Text = "💾 EXPORT"
        $btnExport.BackColor = [System.Drawing.Color]::FromArgb(100, 100, 120)
        $btnExport.ForeColor = [System.Drawing.Color]::White
        $btnExport.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnExport.Font = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $btnExport.Add_Click({ $dashboard.ExportData() })
        $this.ControlPanel.Controls.Add($btnExport)
    }
    
    [void] InitializeTimer() {
        $dashboard = $this
        
        $this.Timer = New-Object System.Windows.Forms.Timer
        $this.Timer.Interval = 1000
        $this.Timer.Add_Tick({ 
            if ($dashboard.IsPlaying) {
                $dashboard.StepQuarter()
            }
        })
    }
    
    # ==================== CONTROL METHODS ====================
    
    [void] TogglePlay() {
        $this.IsPlaying = -not $this.IsPlaying
        
        if ($this.IsPlaying) {
            $this.BtnPlay.Text = "⏸ PAUSE"
            $this.BtnPlay.BackColor = [System.Drawing.Color]::FromArgb(255, 140, 0)
            $this.Timer.Interval = [Math]::Max(100, (1000 / $this.Speed))
            $this.Timer.Start()
            $this.LogEvent("▶ AUTO-PLAY started at $($this.Speed)x speed")
        } else {
            $this.BtnPlay.Text = "▶ PLAY"
            $this.BtnPlay.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
            $this.Timer.Stop()
            $this.LogEvent("⏸ AUTO-PLAY paused")
        }
    }
    
    [void] StepQuarter() {
        # Simulate one quarter
        $this.Market.SimulateQuarter()
        
        # Capture data
        $this.CaptureSnapshot()
        
        # Check for major events
        $this.CheckForMajorEvents()
        
        # Refresh all panels
        $this.RefreshAll()
    }
    
    [void] ResetSimulation() {
        # Stop playback
        $this.IsPlaying = $false
        $this.Timer.Stop()
        $this.BtnPlay.Text = "▶ PLAY"
        $this.BtnPlay.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 0)
        
        # Reset market
        if ($this.Market.PSObject.Methods['Reset']) {
            $this.Market.Reset()
        } else {
            $this.Market.CurrentQuarter = 1
        }
        
        # Clear history
        $this.ProfitHistory.Clear()
        $this.MarketShareHistory.Clear()
        $this.EventLog.Clear()
        $this.DecisionHistory.Clear()
        
        # Log reset
        $this.LogEvent("🔄 SYSTEM RESET - Starting fresh simulation")
        
        # Refresh all panels
        $this.RefreshAll()
    }
    
    [void] RefreshAll() {
        $this.PanelMarketShare.Invalidate()
        $this.PanelQuarterInfo.Invalidate()
        $this.PanelEconomic.Invalidate()
        $this.PanelMainGraph.Invalidate()
        $this.PanelDecisions.Invalidate()
        $this.PanelLearning.Invalidate()
        $this.PanelEvents.Invalidate()
    }
    
    # ==================== DATA CAPTURE ====================
    
    [void] CaptureSnapshot() {
        $snapshot = @{
            Quarter = $this.Market.CurrentQuarter
            Profits = @{}
            MarketShares = @{}
            Decisions = @{}
        }
        
        foreach ($company in $this.Market.Companies) {
            $snapshot.Profits[$company.Name] = [double]$company.State.Profit
            $snapshot.MarketShares[$company.Name] = [double]$company.State.MarketShare
            
            if ($company.PSObject.Properties['LastAction'] -and $null -ne $company.LastAction) {
                $snapshot.Decisions[$company.Name] = $company.LastAction.Name
            } else {
                $snapshot.Decisions[$company.Name] = "Hold"
            }
        }
        
        [void]$this.ProfitHistory.Add($snapshot)
        [void]$this.DecisionHistory.Add($snapshot)
    }
    
    [void] CheckForMajorEvents() {
        if ($this.ProfitHistory.Count -lt 2) { return }
        
        $current = $this.ProfitHistory[-1]
        $previous = $this.ProfitHistory[-2]
        
        foreach ($company in $this.Market.Companies) {
            $name = $company.Name
            $currProfit = $current.Profits[$name]
            $prevProfit = $previous.Profits[$name]
            
            # Big profit changes
            if ($prevProfit -gt 0) {
                $change = (($currProfit - $prevProfit) / $prevProfit) * 100
                if ($change -gt 50) {
                    $this.LogEvent("📈 $name SURGE: Profit +$([Math]::Round($change, 1))%!")
                }
                if ($change -lt -30) {
                    $this.LogEvent("📉 $name DROP: Profit $([Math]::Round($change, 1))%")
                }
            }
            
            # Market share milestones
            $share = $current.MarketShares[$name] * 100
            if ($share -gt 30 -and ($previous.MarketShares[$name] * 100) -le 30) {
                $this.LogEvent("🏆 $name dominates: 30% market share!")
            }
        }
    }
    
    [void] LogEvent([string]$message) {
        $timestamp = "Q$($this.Market.CurrentQuarter)"
        $entry = "[$timestamp] $message"
        [void]$this.EventLog.Add($entry)
        
        # Keep only last 100 events
        if ($this.EventLog.Count -gt 100) {
            $this.EventLog.RemoveAt(0)
        }
    }
    
    # ==================== DRAWING METHODS ====================
    
    [void] DrawMarketSharePanel($sender, $e) {
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 25))
        $g.FillRectangle($bgBrush, 0, 0, $sender.Width, $sender.Height)
        $bgBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("MARKET SHARE", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Draw pie chart with INSIDE labels
        if ($this.Market.Companies.Count -eq 0) { return }
        
        $diameter = 140
        $x = ($sender.Width - $diameter) / 2
        $y = 35
        
        $startAngle = 0.0
        $totalShare = 0.0
        
        foreach ($company in $this.Market.Companies) {
            $totalShare += $company.State.MarketShare
        }
        if ($totalShare -eq 0) { $totalShare = 1.0 }
        
        # Draw pie slices
        for ($i = 0; $i -lt $this.Market.Companies.Count; $i++) {
            $company = $this.Market.Companies[$i]
            $share = [double]$company.State.MarketShare
            $sweepAngle = ($share / $totalShare) * 360.0
            
            $color = $this.CompanyColors[$i]
            $brush = New-Object System.Drawing.SolidBrush($color)
            $rect = New-Object System.Drawing.Rectangle([int]$x, [int]$y, [int]$diameter, [int]$diameter)
            $g.FillPie($brush, $rect, [float]$startAngle, [float]$sweepAngle)
            $brush.Dispose()
            
            # Draw percentage INSIDE the slice
            $pct = [Math]::Round(($share * 100), 1)
            $labelAngle = $startAngle + ($sweepAngle / 2.0)
            $radians = $labelAngle * [Math]::PI / 180.0
            $halfDiam = $diameter / 2.0
            
            # Position label 60% from center (inside the slice)
            $labelDistance = $halfDiam * 0.6
            $labelX = $x + $halfDiam + ([Math]::Cos($radians) * $labelDistance) - 15
            $labelY = $y + $halfDiam + ([Math]::Sin($radians) * $labelDistance) - 7
            
            # Draw percentage with white text and black outline for visibility
            $labelFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
            $labelText = "$pct%"
            
            # Black outline (draw multiple times slightly offset)
            $blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
            for ($dx = -1; $dx -le 1; $dx++) {
                for ($dy = -1; $dy -le 1; $dy++) {
                    if ($dx -ne 0 -or $dy -ne 0) {
                        $g.DrawString($labelText, $labelFont, $blackBrush, $labelX + $dx, $labelY + $dy)
                    }
                }
            }
            $blackBrush.Dispose()
            
            # White text on top
            $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString($labelText, $labelFont, $whiteBrush, $labelX, $labelY)
            $whiteBrush.Dispose()
            $labelFont.Dispose()
            
            $startAngle += $sweepAngle
        }
        
        # Company names below pie chart
        $font = New-Object System.Drawing.Font("Consolas", 8)
        $yLegend = $y + $diameter + 5
        
        for ($i = 0; $i -lt $this.Market.Companies.Count; $i++) {
            $company = $this.Market.Companies[$i]
            $color = $this.CompanyColors[$i]
            
            # Color box
            $brush = New-Object System.Drawing.SolidBrush($color)
            $g.FillRectangle($brush, 10, $yLegend, 12, 12)
            $brush.Dispose()
            
            # Company name
            $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $text = $company.Name
            $g.DrawString($text, $font, $textBrush, 28, $yLegend)
            $textBrush.Dispose()
            
            $yLegend += 14
        }
        
        $font.Dispose()
    }
    
    [void] DrawQuarterInfoPanel($sender, $e) {
        $g = $e.Graphics
        
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 25))
        $g.FillRectangle($bgBrush, 0, 0, $sender.Width, $sender.Height)
        $bgBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("SIMULATION STATUS", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Info
        $font = New-Object System.Drawing.Font("Consolas", 10)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        
        $qtr = if ($this.Market.PSObject.Properties['CurrentQuarter']) { $this.Market.CurrentQuarter } else { 1 }
        $g.DrawString("Quarter: $qtr", $font, $brush, 20, 50)
        
        $statusText = if ($this.IsPlaying) { "RUNNING" } else { "PAUSED" }
        $statusColor = if ($this.IsPlaying) { 
            [System.Drawing.Color]::LimeGreen 
        } else { 
            [System.Drawing.Color]::Orange 
        }
        $statusBrush = New-Object System.Drawing.SolidBrush($statusColor)
        $g.DrawString("Status: $statusText", $font, $statusBrush, 20, 80)
        $statusBrush.Dispose()
        
        $g.DrawString("Speed: $($this.Speed)x", $font, $brush, 20, 110)
        
        $dataPoints = $this.ProfitHistory.Count
        $g.DrawString("Data Points: $dataPoints", $font, $brush, 20, 140)
        
        $font.Dispose()
        $brush.Dispose()
    }
    
    [void] DrawEconomicPanel($sender, $e) {
        $g = $e.Graphics
        
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 25))
        $g.FillRectangle($bgBrush, 0, 0, $sender.Width, $sender.Height)
        $bgBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("ECONOMIC INDICATORS", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Indicators
        $font = New-Object System.Drawing.Font("Consolas", 10)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        
        $gdp = if ($this.Market.PSObject.Properties['EconomyGrowth']) { 
            [double]$this.Market.EconomyGrowth 
        } else { 0.02 }
        $gdpPct = [Math]::Round(($gdp * 100), 2)
        $g.DrawString("GDP Growth: $gdpPct%", $font, $brush, 20, 50)
        
        $interest = if ($this.Market.PSObject.Properties['InterestRate']) {
            [double]$this.Market.InterestRate
        } else { 0.05 }
        $intPct = [Math]::Round(($interest * 100), 2)
        $g.DrawString("Interest Rate: $intPct%", $font, $brush, 20, 80)
        
        $condition = if ($this.Market.PSObject.Properties['MarketCondition']) {
            $this.Market.MarketCondition
        } else { "Neutral" }
        $condColor = switch ($condition) {
            "Bull" { [System.Drawing.Color]::LimeGreen }
            "Bear" { [System.Drawing.Color]::Red }
            default { [System.Drawing.Color]::Yellow }
        }
        $condBrush = New-Object System.Drawing.SolidBrush($condColor)
        $g.DrawString("Market: $condition", $font, $condBrush, 20, 110)
        $condBrush.Dispose()
        
        $font.Dispose()
        $brush.Dispose()
    }
    
    [void] DrawMainGraph($sender, $e) {
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 15, 20))
        $g.FillRectangle($bgBrush, 0, 0, $sender.Width, $sender.Height)
        $bgBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 255, 255))
        $title = "PROFIT PERFORMANCE - REAL-TIME"
        $titleSize = $g.MeasureString($title, $titleFont)
        $titleX = ($sender.Width - $titleSize.Width) / 2
        $g.DrawString($title, $titleFont, $titleBrush, $titleX, 15)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        if ($this.ProfitHistory.Count -lt 2) {
            $msgFont = New-Object System.Drawing.Font("Consolas", 14)
            $msgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
            $msg = "Press STEP or PLAY to start simulation..."
            $msgSize = $g.MeasureString($msg, $msgFont)
            $msgX = ($sender.Width - $msgSize.Width) / 2
            $msgY = ($sender.Height - $msgSize.Height) / 2
            $g.DrawString($msg, $msgFont, $msgBrush, $msgX, $msgY)
            $msgFont.Dispose()
            $msgBrush.Dispose()
            return
        }
        
        # Graph area
        $marginLeft = 60
        $marginRight = 40
        $marginTop = 60
        $marginBottom = 90  # Increased to make room for legend below
        
        $graphWidth = $sender.Width - $marginLeft - $marginRight
        $graphHeight = $sender.Height - $marginTop - $marginBottom
        
        # Find max profit for scaling
        $maxProfit = 1.0
        foreach ($snapshot in $this.ProfitHistory) {
            foreach ($profitValue in $snapshot.Profits.Values) {
                $profVal = [double]$profitValue
                if ($profVal -gt $maxProfit) { $maxProfit = $profVal }
            }
        }
        
        # Draw grid lines
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 40, 50), 1)
        for ($i = 0; $i -le 5; $i++) {
            $y = $marginTop + ($graphHeight * $i / 5)
            $g.DrawLine($gridPen, $marginLeft, $y, $marginLeft + $graphWidth, $y)
        }
        for ($i = 0; $i -le 10; $i++) {
            $x = $marginLeft + ($graphWidth * $i / 10)
            $g.DrawLine($gridPen, $x, $marginTop, $x, $marginTop + $graphHeight)
        }
        $gridPen.Dispose()
        
        # Draw axes
        $axisPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 80, 100), 2)
        $axisBottomY = $marginTop + $graphHeight
        $axisRightX = $marginLeft + $graphWidth
        $g.DrawLine($axisPen, $marginLeft, $axisBottomY, $axisRightX, $axisBottomY)
        $g.DrawLine($axisPen, $marginLeft, $marginTop, $marginLeft, $axisBottomY)
        $axisPen.Dispose()
        
        # Draw profit lines for each company
        $historyCount = $this.ProfitHistory.Count
        
        for ($compIdx = 0; $compIdx -lt $this.Market.Companies.Count; $compIdx++) {
            $company = $this.Market.Companies[$compIdx]
            $points = New-Object System.Collections.ArrayList
            
            for ($i = 0; $i -lt $historyCount; $i++) {
                $snapshot = $this.ProfitHistory[$i]
                $profit = [double]$snapshot.Profits[$company.Name]
                
                $divisor = $historyCount - 1
                if ($divisor -le 0) { $divisor = 1 }
                $xFraction = [double]$i / [double]$divisor
                $xPos = $marginLeft + ($xFraction * $graphWidth)
                
                $yFraction = $profit / $maxProfit
                $yOffset = $yFraction * $graphHeight
                $yPos = ($marginTop + $graphHeight) - $yOffset
                
                $point = New-Object System.Drawing.PointF($xPos, $yPos)
                [void]$points.Add($point)
            }
            
            if ($points.Count -gt 1) {
                $color = $this.CompanyColors[$compIdx]
                $pen = New-Object System.Drawing.Pen($color, 3)
                $g.DrawLines($pen, $points.ToArray([System.Drawing.PointF]))
                $pen.Dispose()
            }
        }
        
        # Y-axis labels
        $labelFont = New-Object System.Drawing.Font("Consolas", 9)
        $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
        
        for ($i = 0; $i -le 5; $i++) {
            $value = $maxProfit * (1 - ($i / 5.0))
            $label = [Math]::Round($value, 1)
            $y = $marginTop + ($graphHeight * $i / 5) - 7
            $g.DrawString("$label", $labelFont, $labelBrush, 10, $y)
        }
        
        $labelFont.Dispose()
        $labelBrush.Dispose()
        
        # Legend (moved to LEFT to avoid overlap with graph)
        $this.DrawGraphLegend($g, 70, $marginTop + $graphHeight + 10)
    }
    
    [void] DrawGraphLegend($g, $x, $y) {
        $font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
        $yOffset = 0
        
        for ($i = 0; $i -lt $this.Market.Companies.Count; $i++) {
            $company = $this.Market.Companies[$i]
            $color = $this.CompanyColors[$i]
            
            # Color box
            $brush = New-Object System.Drawing.SolidBrush($color)
            $g.FillRectangle($brush, $x, $y + $yOffset, 15, 15)
            $brush.Dispose()
            
            # Company name + profit
            $profit = [Math]::Round([double]$company.State.Profit, 1)
            $text = "$($company.Name): `$$profit M"
            $textBrush = New-Object System.Drawing.SolidBrush($color)
            $g.DrawString($text, $font, $textBrush, $x + 20, $y + $yOffset)
            $textBrush.Dispose()
            
            $yOffset += 20
        }
        
        $font.Dispose()
    }
    
    [void] DrawDecisionsPanel($sender, $e) {
        $g = $e.Graphics
        
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 25))
        $g.FillRectangle($bgBrush, 0, 0, $sender.Width, $sender.Height)
        $bgBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("RECENT DECISIONS", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        if ($this.DecisionHistory.Count -eq 0) { return }
        
        $font = New-Object System.Drawing.Font("Consolas", 9)
        $yPos = 45
        
        # Show last 8 quarters
        $recentDecisions = $this.DecisionHistory | Select-Object -Last 8
        
        foreach ($snapshot in $recentDecisions) {
            $qtr = $snapshot.Quarter
            
            # Quarter label
            $qBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
            $g.DrawString("Q$qtr", $font, $qBrush, 10, $yPos)
            $qBrush.Dispose()
            
            # Decisions
            $xPos = 50
            foreach ($compName in $snapshot.Decisions.Keys) {
                $decision = $snapshot.Decisions[$compName]
                
                # Color-code by decision type
                $decColor = switch ($decision) {
                    "Invest" { [System.Drawing.Color]::LimeGreen }
                    "Cut" { [System.Drawing.Color]::Red }
                    "Expand" { [System.Drawing.Color]::Cyan }
                    default { [System.Drawing.Color]::Gray }
                }
                
                $decBrush = New-Object System.Drawing.SolidBrush($decColor)
                $g.DrawString($decision.Substring(0, [Math]::Min(3, $decision.Length)), $font, $decBrush, $xPos, $yPos)
                $decBrush.Dispose()
                
                $xPos += 90
            }
            
            $yPos += 18
        }
        
        $font.Dispose()
    }
    
    [void] DrawLearningPanel($sender, $e) {
        $g = $e.Graphics
        
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 25))
        $g.FillRectangle($bgBrush, 0, 0, $sender.Width, $sender.Height)
        $bgBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("LEARNING STATS", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Agent performance
        $font = New-Object System.Drawing.Font("Consolas", 9)
        $yPos = 45
        
        foreach ($company in $this.Market.Companies) {
            $totalReward = if ($company.PSObject.Properties['TotalReward']) {
                [Math]::Round($company.TotalReward, 1)
            } else { 0 }
            
            $epsilon = if ($company.PSObject.Properties['Agent'] -and 
                          $company.Agent.PSObject.Properties['Epsilon']) {
                [Math]::Round($company.Agent.Epsilon, 3)
            } else { 0 }
            
            # Company name
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString("$($company.Name):", $font, $brush, 10, $yPos)
            $brush.Dispose()
            
            # Reward on first line (green)
            $rewardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::LimeGreen)
            $g.DrawString("R: $totalReward", $font, $rewardBrush, 100, $yPos)
            $rewardBrush.Dispose()
            
            # Move to next line for epsilon
            $yPos += 15
            
            # Epsilon on second line (yellow)
            $epsBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            $g.DrawString("ε: $epsilon", $font, $epsBrush, 100, $yPos)
            $epsBrush.Dispose()
            
            # Space before next company
            $yPos += 20
        }
        
        $font.Dispose()
    }
    
    [void] DrawEventsPanel($sender, $e) {
        $g = $e.Graphics
        
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 25))
        $g.FillRectangle($bgBrush, 0, 0, $sender.Width, $sender.Height)
        $bgBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("EVENT LOG - LIVE FEED", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Events
        $font = New-Object System.Drawing.Font("Consolas", 10)
        $yPos = 50
        
        if ($this.EventLog.Count -gt 0) {
            # Show last 6 events
            $lastEvents = $this.EventLog | Select-Object -Last 6
            
            foreach ($event in $lastEvents) {
                # Color-code by event type
                $eventColor = [System.Drawing.Color]::White
                if ($event -match "SURGE|dominates") {
                    $eventColor = [System.Drawing.Color]::LimeGreen
                } elseif ($event -match "DROP|declined") {
                    $eventColor = [System.Drawing.Color]::Red
                } elseif ($event -match "RESET|initialized") {
                    $eventColor = [System.Drawing.Color]::Cyan
                }
                
                $brush = New-Object System.Drawing.SolidBrush($eventColor)
                $g.DrawString($event, $font, $brush, 10, $yPos)
                $brush.Dispose()
                
                $yPos += 18
            }
        } else {
            $msgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
            $g.DrawString("No events yet - start simulation to see live updates", $font, $msgBrush, 10, $yPos)
            $msgBrush.Dispose()
        }
        
        $font.Dispose()
    }
    
    # ==================== EXPORT ====================
    
    [void] ExportData() {
        try {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $filename = "market_data_$timestamp.csv"
            
            $csv = "Quarter,Company,Profit,MarketShare`n"
            
            foreach ($snapshot in $this.ProfitHistory) {
                $qtr = $snapshot.Quarter
                foreach ($name in $snapshot.Profits.Keys) {
                    $profit = $snapshot.Profits[$name]
                    $share = $snapshot.MarketShares[$name]
                    $csv += "$qtr,$name,$profit,$share`n"
                }
            }
            
            $csv | Out-File -FilePath $filename -Encoding UTF8
            
            [System.Windows.Forms.MessageBox]::Show(
                "Data exported successfully!`n`nFile: $filename`nRows: $($this.ProfitHistory.Count * 4)", 
                "Export Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
            Write-Host "💾 Data exported to: $filename" -ForegroundColor Green
            
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Export failed: $_", 
                "Export Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
    
    # ==================== SHOW ====================
    
    [void] Show() {
        $this.Form.ShowDialog()
    }
}