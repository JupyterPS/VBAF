#Requires -Version 5.1
# VBAF.Visualization.MarketDashboard.ps1
# Dashboard 2
<#
.SYNOPSIS
    Real-time market dashboard for multi-agent simulation
.DESCRIPTION
    Visualizes 4 companies competing in a market environment.
    Shows market share, profit trends, economic indicators, and learning progress.
.NOTES
    Part of VBAF (Visual Business Automation Framework)
    COMPLETE VERSION: All features implemented + Speed button fixed
#>

class MarketDashboard {
    # Form and panels
    [System.Windows.Forms.Form]$Form
    [System.Windows.Forms.Panel]$TopPanel
    [System.Windows.Forms.Panel]$MiddleLeftPanel
    [System.Windows.Forms.Panel]$MiddleRightPanel
    [System.Windows.Forms.Panel]$BottomLeftPanel
    [System.Windows.Forms.Panel]$BottomRightPanel
    [System.Windows.Forms.Panel]$ControlPanel
    
    # Controls (store references for updates)
    [System.Windows.Forms.Button]$BtnPlay
    
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
    
    # Constructor
    MarketDashboard($marketEnvironment) {
        $this.Market = $marketEnvironment
        $this.ProfitHistory = New-Object System.Collections.ArrayList
        $this.MarketShareHistory = New-Object System.Collections.ArrayList
        $this.EventLog = New-Object System.Collections.ArrayList
        $this.DecisionHistory = New-Object System.Collections.ArrayList
        $this.IsPlaying = $false
        $this.Speed = 1
        
        $this.InitializeForm()
        $this.InitializePanels()
        $this.InitializeControls()
        $this.InitializeTimer()
        
        # Log startup
        $this.LogEvent("Dashboard initialized - Ready to simulate!")
    }
    
    [void] InitializeForm() {
        $this.Form = New-Object System.Windows.Forms.Form
        $this.Form.Width = 1600
        $this.Form.Height = 1050
        $this.Form.Text = "VBAF Market Dashboard - 4 Company Simulation"
        $this.Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $this.Form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    }
    
    [void] InitializePanels() {
        # Capture $this for event handlers
        $dashboard = $this
        
        # TOP PANEL
        $this.TopPanel = New-Object System.Windows.Forms.Panel
        $this.TopPanel.Location = New-Object System.Drawing.Point(10, 10)
        $this.TopPanel.Size = New-Object System.Drawing.Size(1560, 300)
        $this.TopPanel.BackColor = [System.Drawing.Color]::white
        $this.TopPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.TopPanel)
        $this.TopPanel.Add_Paint({ param($s, $e) $dashboard.DrawTopPanel($s, $e) })
        $this.Form.Controls.Add($this.TopPanel)
        
        # MIDDLE LEFT PANEL
        $this.MiddleLeftPanel = New-Object System.Windows.Forms.Panel
        $this.MiddleLeftPanel.Location = New-Object System.Drawing.Point(10, 320)
        $this.MiddleLeftPanel.Size = New-Object System.Drawing.Size(940, 500)
        $this.MiddleLeftPanel.BackColor = [System.Drawing.Color]::white
        $this.MiddleLeftPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.MiddleLeftPanel)
        $this.MiddleLeftPanel.Add_Paint({ param($s, $e) $dashboard.DrawProfitTrends($s, $e) })
        $this.Form.Controls.Add($this.MiddleLeftPanel)
        
        # MIDDLE RIGHT PANEL
        $this.MiddleRightPanel = New-Object System.Windows.Forms.Panel
        $this.MiddleRightPanel.Location = New-Object System.Drawing.Point(960, 320)
        $this.MiddleRightPanel.Size = New-Object System.Drawing.Size(610, 500)
        $this.MiddleRightPanel.BackColor = [System.Drawing.Color]::white
        $this.MiddleRightPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.MiddleRightPanel)
        $this.MiddleRightPanel.Add_Paint({ param($s, $e) $dashboard.DrawDecisionHeatmap($s, $e) })
        $this.Form.Controls.Add($this.MiddleRightPanel)
        
        # BOTTOM LEFT PANEL
        $this.BottomLeftPanel = New-Object System.Windows.Forms.Panel
        $this.BottomLeftPanel.Location = New-Object System.Drawing.Point(10, 830)
        $this.BottomLeftPanel.Size = New-Object System.Drawing.Size(940, 80)
        $this.BottomLeftPanel.BackColor = [System.Drawing.Color]::white
        $this.BottomLeftPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.BottomLeftPanel)
        $this.BottomLeftPanel.Add_Paint({ param($s, $e) $dashboard.DrawEventLog($s, $e) })
        $this.Form.Controls.Add($this.BottomLeftPanel)
        
        # BOTTOM RIGHT PANEL
        $this.BottomRightPanel = New-Object System.Windows.Forms.Panel
        $this.BottomRightPanel.Location = New-Object System.Drawing.Point(960, 830)
        $this.BottomRightPanel.Size = New-Object System.Drawing.Size(610, 80)
        $this.BottomRightPanel.BackColor = [System.Drawing.Color]::white
        $this.BottomRightPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.BottomRightPanel)
        $this.BottomRightPanel.Add_Paint({ param($s, $e) $dashboard.DrawLearningCurves($s, $e) })
        $this.Form.Controls.Add($this.BottomRightPanel)
        
        # CONTROL PANEL
        $this.ControlPanel = New-Object System.Windows.Forms.Panel
        $this.ControlPanel.Location = New-Object System.Drawing.Point(10, 920)
        $this.ControlPanel.Size = New-Object System.Drawing.Size(1560, 60)
        $this.ControlPanel.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $this.ControlPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.Form.Controls.Add($this.ControlPanel)
    }
    
    [void] EnableDoubleBuffering($panel) {
        $prop = $panel.GetType().GetProperty("DoubleBuffered", 
            [System.Reflection.BindingFlags]"Instance,NonPublic")
        $prop.SetValue($panel, $true, $null)
    }
    
    [void] InitializeControls() {
        # Capture $this for event handlers
        $dashboard = $this
        
        # Play Button
        $this.BtnPlay = New-Object System.Windows.Forms.Button
        $this.BtnPlay.Location = New-Object System.Drawing.Point(10, 15)
        $this.BtnPlay.Size = New-Object System.Drawing.Size(80, 30)
        $this.BtnPlay.Text = "▶ Play"
        $this.BtnPlay.Add_Click({ $dashboard.TogglePlay() })
        $this.ControlPanel.Controls.Add($this.BtnPlay)
        
        # Step Button
        $btnStep = New-Object System.Windows.Forms.Button
        $btnStep.Location = New-Object System.Drawing.Point(100, 15)
        $btnStep.Size = New-Object System.Drawing.Size(80, 30)
        $btnStep.Text = "⏭ Step"
        $btnStep.Add_Click({ $dashboard.StepQuarter() })
        $this.ControlPanel.Controls.Add($btnStep)
        
        # Reset Button
        $btnReset = New-Object System.Windows.Forms.Button
        $btnReset.Location = New-Object System.Drawing.Point(190, 15)
        $btnReset.Size = New-Object System.Drawing.Size(80, 30)
        $btnReset.Text = "🔄 Reset"
        $btnReset.Add_Click({ $dashboard.ResetSimulation() })
        $this.ControlPanel.Controls.Add($btnReset)
        
        # Speed Label
        $lblSpeed = New-Object System.Windows.Forms.Label
        $lblSpeed.Location = New-Object System.Drawing.Point(300, 20)
        $lblSpeed.Size = New-Object System.Drawing.Size(120, 20)
        $lblSpeed.Text = "Speed: 1x-10x"
        $this.ControlPanel.Controls.Add($lblSpeed)
        
        # Speed Slider - SIMPLIFIED: No label update, just changes speed
        $trackSpeed = New-Object System.Windows.Forms.TrackBar
        $trackSpeed.Location = New-Object System.Drawing.Point(420, 10)
        $trackSpeed.Size = New-Object System.Drawing.Size(200, 40)
        $trackSpeed.Minimum = 1
        $trackSpeed.Maximum = 10
        $trackSpeed.Value = 1
        $trackSpeed.TickFrequency = 1
        $trackSpeed.Add_ValueChanged({ 
            $dashboard.Speed = $trackSpeed.Value
            if ($dashboard.IsPlaying) {
                $dashboard.Timer.Interval = [Math]::Max(100, (1000 / $trackSpeed.Value))
            }
            Write-Host "Speed changed to $($trackSpeed.Value)x" -ForegroundColor Cyan
        })
        $this.ControlPanel.Controls.Add($trackSpeed)
        
        # Export Button
        $btnExport = New-Object System.Windows.Forms.Button
        $btnExport.Location = New-Object System.Drawing.Point(1450, 15)
        $btnExport.Size = New-Object System.Drawing.Size(100, 30)
        $btnExport.Text = "💾 Export"
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
    
    [void] TogglePlay() {
        $this.IsPlaying = -not $this.IsPlaying
        
        if ($this.IsPlaying) {
            $this.BtnPlay.Text = "⏸ Pause"
            $this.Timer.Interval = [Math]::Max(100, (1000 / $this.Speed))
            $this.Timer.Start()
            $this.LogEvent("▶ AUTO-PLAY started ($($this.Speed)x speed)")
            Write-Host "▶ PLAY - Auto-simulation started at $($this.Speed)x speed" -ForegroundColor Green
        } else {
            $this.BtnPlay.Text = "▶ Play"
            $this.Timer.Stop()
            $this.LogEvent("⏸ AUTO-PLAY paused")
            Write-Host "⏸ PAUSE - Auto-simulation stopped" -ForegroundColor Yellow
        }
    }
    
    [void] StepQuarter() {
        # Simulate one quarter
        $this.Market.SimulateQuarter()
        
        # Capture data
        $this.CaptureSnapshot()
        
        # Log major events
        $this.CheckForMajorEvents()
        
        # Refresh all panels
        $this.TopPanel.Invalidate()
        $this.MiddleLeftPanel.Invalidate()
        $this.MiddleRightPanel.Invalidate()
        $this.BottomLeftPanel.Invalidate()
        $this.BottomRightPanel.Invalidate()
    }
    
    [void] ResetSimulation() {
        # Stop playback
        $this.IsPlaying = $false
        $this.Timer.Stop()
        $this.BtnPlay.Text = "▶ Play"
        
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
        $this.LogEvent("🔄 SIMULATION RESET - Starting fresh!")
        Write-Host "🔄 RESET - Simulation reset to start" -ForegroundColor Cyan
        
        # Refresh all panels
        $this.TopPanel.Invalidate()
        $this.MiddleLeftPanel.Invalidate()
        $this.MiddleRightPanel.Invalidate()
        $this.BottomLeftPanel.Invalidate()
        $this.BottomRightPanel.Invalidate()
    }
    
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
            
            # Track last action if available
            if ($company.PSObject.Properties['LastAction'] -and $null -ne $company.LastAction) {
                $snapshot.Decisions[$company.Name] = $company.LastAction.Name
            } else {
                $snapshot.Decisions[$company.Name] = "Hold"
            }
        }
        
        [void]$this.ProfitHistory.Add($snapshot)
        [void]$this.DecisionHistory.Add($snapshot)
        
        # Debug output
        Write-Host "📊 Q$($this.Market.CurrentQuarter): " -NoNewline -ForegroundColor DarkGray
        foreach ($name in $snapshot.Profits.Keys) {
            $profit = [Math]::Round($snapshot.Profits[$name], 1)
            $share = [Math]::Round(($snapshot.MarketShares[$name] * 100), 1)
            Write-Host "$name(P:$profit MS:$share%) " -NoNewline -ForegroundColor DarkGray
        }
        Write-Host ""
    }
    
    [void] CheckForMajorEvents() {
        if ($this.ProfitHistory.Count -lt 2) { return }
        
        $current = $this.ProfitHistory[-1]
        $previous = $this.ProfitHistory[-2]
        
        foreach ($company in $this.Market.Companies) {
            $name = $company.Name
            $currProfit = $current.Profits[$name]
            $prevProfit = $previous.Profits[$name]
            
            # Big profit jump
            if ($prevProfit -gt 0) {
                $change = (($currProfit - $prevProfit) / $prevProfit) * 100
                if ($change -gt 50) {
                    $this.LogEvent("📈 $name profit surged by $([Math]::Round($change, 1))%!")
                }
                if ($change -lt -30) {
                    $this.LogEvent("📉 $name profit dropped by $([Math]::Round([Math]::Abs($change), 1))%")
                }
            }
            
            # Market share milestones
            $share = $current.MarketShares[$name] * 100
            if ($share -gt 30 -and ($previous.MarketShares[$name] * 100) -le 30) {
                $this.LogEvent("🏆 $name captured 30% market share!")
            }
        }
    }
    
    [void] LogEvent([string]$message) {
        $timestamp = "Q$($this.Market.CurrentQuarter)"
        $entry = "[$timestamp] $message"
        [void]$this.EventLog.Add($entry)
        
        # Keep only last 50 events
        if ($this.EventLog.Count -gt 50) {
            $this.EventLog.RemoveAt(0)
        }
    }
    
    [void] DrawTopPanel($sender, $e) {
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Gradient background
        $gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, 300),
            [System.Drawing.Color]::FromArgb(245, 250, 255),
            [System.Drawing.Color]::FromArgb(230, 240, 250)
        )
        $g.FillRectangle($gradBrush, 0, 0, $sender.Width, $sender.Height)
        $gradBrush.Dispose()
        
        $this.DrawMarketSharePie($g, 50, 50, 200)
        $this.DrawEconomicIndicators($g, 800, 50)
    }
    
    [void] DrawMarketSharePie($g, $x, $y, $diameter) {
        $companies = $this.Market.Companies
        if ($companies.Count -eq 0) { return }
        
        $colors = @(
            [System.Drawing.Color]::FromArgb(70, 130, 180),
            [System.Drawing.Color]::FromArgb(139, 69, 19),
            [System.Drawing.Color]::FromArgb(34, 139, 34),
            [System.Drawing.Color]::FromArgb(148, 0, 211)
        )
        
        $startAngle = 0.0
        $totalShare = 0.0
        
        foreach ($company in $companies) {
            $totalShare += $company.State.MarketShare
        }
        if ($totalShare -eq 0) { $totalShare = 1.0 }
        
        for ($i = 0; $i -lt $companies.Count; $i++) {
            $company = $companies[$i]
            $share = [double]$company.State.MarketShare
            $sweepAngle = ($share / $totalShare) * 360.0
            
            $brush = New-Object System.Drawing.SolidBrush($colors[$i])
            $rect = New-Object System.Drawing.Rectangle([int]$x, [int]$y, [int]$diameter, [int]$diameter)
            $g.FillPie($brush, $rect, [float]$startAngle, [float]$sweepAngle)
            $brush.Dispose()
            
            $labelAngle = $startAngle + ($sweepAngle / 2.0)
            $radians = $labelAngle * [Math]::PI / 180.0
            $halfDiam = $diameter / 2.0
            $offset = $halfDiam + 20.0
            
            $labelX = $x + $halfDiam + ([Math]::Cos($radians) * $offset)
            $labelY = $y + $halfDiam + ([Math]::Sin($radians) * $offset)
            
            $font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
            $pct = [Math]::Round(($share * 100), 1)
            $text = "$($company.Name): $pct%"
            $g.DrawString($text, $font, $brush, $labelX, $labelY)
            $font.Dispose()
            $brush.Dispose()
            
            $startAngle += $sweepAngle
        }
        
        $titleFont = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        $g.DrawString("Market Share Distribution", $titleFont, $titleBrush, $x, ($y - 30))
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
    
    [void] DrawEconomicIndicators($g, $x, $y) {
        $font = New-Object System.Drawing.Font("Arial", 12)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        
        $titleFont = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
        $g.DrawString("Economic Indicators", $titleFont, $brush, $x, ($y - 30))
        $titleFont.Dispose()
        
        $qtr = if ($this.Market.PSObject.Properties['CurrentQuarter']) { $this.Market.CurrentQuarter } else { 1 }
        $g.DrawString("Quarter: $qtr", $font, $brush, $x, $y)
        
        $gdp = if ($this.Market.PSObject.Properties['EconomyGrowth']) { 
            [double]$this.Market.EconomyGrowth 
        } else { 0.02 }
        $gdpPct = [Math]::Round(($gdp * 100), 2)
        $g.DrawString("GDP Growth: $gdpPct%", $font, $brush, $x, ($y + 30))
        
        $interest = if ($this.Market.PSObject.Properties['InterestRate']) {
            [double]$this.Market.InterestRate
        } else { 0.05 }
        $intPct = [Math]::Round(($interest * 100), 2)
        $g.DrawString("Interest Rate: $intPct%", $font, $brush, $x, ($y + 60))
        
        $condition = if ($this.Market.PSObject.Properties['MarketCondition']) {
            $this.Market.MarketCondition
        } else { "Neutral" }
        $g.DrawString("Market: $condition", $font, $brush, $x, ($y + 90))
        
        $font.Dispose()
        $brush.Dispose()
    }
    
    [void] DrawProfitTrends($sender, $e) {
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, 500),
            [System.Drawing.Color]::FromArgb(250, 252, 255),
            [System.Drawing.Color]::FromArgb(240, 245, 250)
        )
        $g.FillRectangle($gradBrush, 0, 0, $sender.Width, $sender.Height)
        $gradBrush.Dispose()
        
        $titleFont = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 60, 100))
        $g.DrawString("Company Profit Trends", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        if ($this.ProfitHistory.Count -lt 2) { 
            $msgFont = New-Object System.Drawing.Font("Arial", 11)
            $msgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
            $g.DrawString("Press 'Step' or 'Play' to start simulation...", $msgFont, $msgBrush, 50, 250)
            $msgFont.Dispose()
            $msgBrush.Dispose()
            return
        }
        
        $panelWidth = $sender.Width
        $panelHeight = $sender.Height
        $width = $panelWidth - 80
        $height = $panelHeight - 120
        $marginLeft = 60
        $marginTop = 60
        
        $maxProfit = 1.0
        foreach ($snapshot in $this.ProfitHistory) {
            foreach ($profitValue in $snapshot.Profits.Values) {
                $profVal = [double]$profitValue
                if ($profVal -gt $maxProfit) { $maxProfit = $profVal }
            }
        }
        
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 200, 200), 1)
        $axisBottomY = $marginTop + $height
        $axisRightX = $marginLeft + $width
        $g.DrawLine($pen, $marginLeft, $axisBottomY, $axisRightX, $axisBottomY)
        $g.DrawLine($pen, $marginLeft, $marginTop, $marginLeft, $axisBottomY)
        $pen.Dispose()
        
        $colors = @(
            [System.Drawing.Color]::FromArgb(70, 130, 180),
            [System.Drawing.Color]::FromArgb(139, 69, 19),
            [System.Drawing.Color]::FromArgb(34, 139, 34),
            [System.Drawing.Color]::FromArgb(148, 0, 211)
        )
        
        $companyIndex = 0
        $historyCount = $this.ProfitHistory.Count
        
        foreach ($company in $this.Market.Companies) {
            $points = New-Object System.Collections.ArrayList
            
            for ($i = 0; $i -lt $historyCount; $i++) {
                $snapshot = $this.ProfitHistory[$i]
                $profit = [double]$snapshot.Profits[$company.Name]
                
                $divisor = $historyCount - 1
                if ($divisor -le 0) { $divisor = 1 }
                $xFraction = [double]$i / [double]$divisor
                $xPos = $marginLeft + ($xFraction * $width)
                
                $yFraction = $profit / $maxProfit
                $yOffset = $yFraction * $height
                $yPos = ($marginTop + $height) - $yOffset
                
                $point = New-Object System.Drawing.PointF($xPos, $yPos)
                [void]$points.Add($point)
            }
            
            if ($points.Count -gt 1) {
                $pen = New-Object System.Drawing.Pen($colors[$companyIndex], 3)
                $g.DrawLines($pen, $points.ToArray([System.Drawing.PointF]))
                $pen.Dispose()
            }
            
            $companyIndex++
        }
        
        $this.DrawLegend($g, ($width - 180), 70, $colors)
    }
    
    [void] DrawLegend($g, $x, $y, $colors) {
        $font = New-Object System.Drawing.Font("Arial", 10)
        $yOffset = 0
        
        for ($i = 0; $i -lt $this.Market.Companies.Count; $i++) {
            $company = $this.Market.Companies[$i]
            
            $brush = New-Object System.Drawing.SolidBrush($colors[$i])
            $boxY = $y + $yOffset
            $g.FillRectangle($brush, $x, $boxY, 15, 15)
            $brush.Dispose()
            
            $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
            $profit = [Math]::Round([double]$company.State.Profit, 2)
            $text = "$($company.Name): `$${profit}M"
            $textX = $x + 20
            $textY = $y + $yOffset
            $g.DrawString($text, $font, $textBrush, $textX, $textY)
            $textBrush.Dispose()
            
            $yOffset += 25
        }
        
        $font.Dispose()
    }
    
    [void] DrawDecisionHeatmap($sender, $e) {
        $g = $e.Graphics
        
        $titleFont = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        $g.DrawString("Recent Decisions", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        if ($this.DecisionHistory.Count -eq 0) { return }
        
        $font = New-Object System.Drawing.Font("Arial", 9)
        $yPos = 40
        
        # Show last 5 quarters of decisions
        $recentDecisions = $this.DecisionHistory | Select-Object -Last 5
        
        foreach ($snapshot in $recentDecisions) {
            $qtr = $snapshot.Quarter
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 60, 60))
            $qtrText = "Q" + $qtr + ":"
            $g.DrawString($qtrText, $font, $brush, 10, $yPos)
            $brush.Dispose()
            
            $xPos = 50
            foreach ($compName in $snapshot.Decisions.Keys) {
                $decision = $snapshot.Decisions[$compName]
                $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 100, 100))
                $g.DrawString("$compName=$decision", $font, $brush, $xPos, $yPos)
                $brush.Dispose()
                $xPos += 140
            }
            
            $yPos += 20
        }
        
        $font.Dispose()
    }
    
    [void] DrawEventLog($sender, $e) {
        $g = $e.Graphics
        
        $titleFont = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        $g.DrawString("Event Log", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        $font = New-Object System.Drawing.Font("Arial", 9)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::DarkGray)
        
        $yPos = 35
        if ($this.EventLog.Count -gt 0) {
            $lastEvents = $this.EventLog | Select-Object -Last 2
            foreach ($event in $lastEvents) {
                $g.DrawString($event, $font, $brush, 10, $yPos)
                $yPos += 18
            }
        } else {
            $g.DrawString("No events yet - press Step or Play to begin", $font, $brush, 10, $yPos)
        }
        
        $font.Dispose()
        $brush.Dispose()
    }
    
    [void] DrawLearningCurves($sender, $e) {
        $g = $e.Graphics
        
        $titleFont = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        $g.DrawString("Reward Trends", $titleFont, $titleBrush, 10, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        if ($this.ProfitHistory.Count -lt 2) { return }
        
        # Show reward as profit growth trend
        $font = New-Object System.Drawing.Font("Arial", 9)
        $yPos = 35
        
        foreach ($company in $this.Market.Companies) {
            $totalReward = if ($company.PSObject.Properties['TotalReward']) {
                [Math]::Round($company.TotalReward, 1)
            } else { 0 }
            
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 80, 80))
            $g.DrawString("$($company.Name): Reward=$totalReward", $font, $brush, 10, $yPos)
            $brush.Dispose()
            $yPos += 16
        }
        
        $font.Dispose()
    }
    
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
    
    [void] Show() {
        $this.Form.ShowDialog()
    }
}