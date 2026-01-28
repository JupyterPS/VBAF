#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

class MarketDashboard {

    # ------------------ FIELDS ------------------
    [System.Windows.Forms.Form]$Form
    [System.Windows.Forms.Panel]$TopPanel
    [System.Windows.Forms.Panel]$MiddleLeftPanel
    [System.Windows.Forms.Panel]$MiddleRightPanel
    [System.Windows.Forms.Panel]$BottomLeftPanel
    [System.Windows.Forms.Panel]$BottomRightPanel
    [System.Windows.Forms.Panel]$ControlPanel

    [System.Windows.Forms.Button]$BtnPlay
    [System.Windows.Forms.Timer]$Timer
    [bool]$IsPlaying
    [int]$Speed

    $Market
    [System.Collections.ArrayList]$ProfitHistory
    [System.Collections.ArrayList]$MarketShareHistory
    [System.Collections.ArrayList]$EventLog
    [System.Collections.ArrayList]$DecisionHistory

    # ------------------ METHODS REQUIRED BY CONSTRUCTOR ------------------
    [void] LogEvent([string]$message) {
        $timestamp = "Q$($this.Market.CurrentQuarter)"
        $entry = "[$timestamp] $message"
        if (-not $this.EventLog) { $this.EventLog = New-Object System.Collections.ArrayList }
        [void]$this.EventLog.Add($entry)
        if ($this.EventLog.Count -gt 50) { $this.EventLog.RemoveAt(0) }
    }

    [void] EnableDoubleBuffering($panel) {
        $prop = $panel.GetType().GetProperty("DoubleBuffered",[System.Reflection.BindingFlags]"Instance,NonPublic")
        $prop.SetValue($panel,$true,$null)
    }

    # ------------------ CONSTRUCTOR ------------------
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

        $this.LogEvent("Dashboard initialized - Ready to simulate!")
    }

    # ------------------ FORM & PANELS ------------------
    [void] InitializeForm() {
        $this.Form = New-Object System.Windows.Forms.Form
        $this.Form.Width = 1600
        $this.Form.Height = 1050
        $this.Form.Text = "VBAF Market Dashboard - 4 Company Simulation"
        $this.Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $this.Form.BackColor = [System.Drawing.Color]::Black
    }

    [void] InitializePanels() {
        $dashboard = $this

        # Top Panel
        $this.TopPanel = New-Object System.Windows.Forms.Panel
        $this.TopPanel.Location = New-Object System.Drawing.Point(10,10)
        $this.TopPanel.Size = New-Object System.Drawing.Size(1560,300)
        $this.TopPanel.BackColor = [System.Drawing.Color]::Black
        $this.TopPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.TopPanel)
        $this.TopPanel.Add_Paint({ param($s,$e) $dashboard.DrawTopPanel($s,$e) })
        $this.Form.Controls.Add($this.TopPanel)

        # Middle Left Panel
        $this.MiddleLeftPanel = New-Object System.Windows.Forms.Panel
        $this.MiddleLeftPanel.Location = New-Object System.Drawing.Point(10,320)
        $this.MiddleLeftPanel.Size = New-Object System.Drawing.Size(940,500)
        $this.MiddleLeftPanel.BackColor = [System.Drawing.Color]::Black
        $this.MiddleLeftPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.MiddleLeftPanel)
        $this.MiddleLeftPanel.Add_Paint({ param($s,$e) $dashboard.DrawProfitTrends($s,$e) })
        $this.Form.Controls.Add($this.MiddleLeftPanel)

        # Middle Right Panel
        $this.MiddleRightPanel = New-Object System.Windows.Forms.Panel
        $this.MiddleRightPanel.Location = New-Object System.Drawing.Point(960,320)
        $this.MiddleRightPanel.Size = New-Object System.Drawing.Size(610,500)
        $this.MiddleRightPanel.BackColor = [System.Drawing.Color]::Black
        $this.MiddleRightPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.MiddleRightPanel)
        $this.MiddleRightPanel.Add_Paint({ param($s,$e) $dashboard.DrawDecisionHeatmap($s,$e) })
        $this.Form.Controls.Add($this.MiddleRightPanel)

        # Bottom Left Panel
        $this.BottomLeftPanel = New-Object System.Windows.Forms.Panel
        $this.BottomLeftPanel.Location = New-Object System.Drawing.Point(10,830)
        $this.BottomLeftPanel.Size = New-Object System.Drawing.Size(940,80)
        $this.BottomLeftPanel.BackColor = [System.Drawing.Color]::Black
        $this.BottomLeftPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.BottomLeftPanel)
        $this.BottomLeftPanel.Add_Paint({ param($s,$e) $dashboard.DrawEventLog($s,$e) })
        $this.Form.Controls.Add($this.BottomLeftPanel)

        # Bottom Right Panel
        $this.BottomRightPanel = New-Object System.Windows.Forms.Panel
        $this.BottomRightPanel.Location = New-Object System.Drawing.Point(960,830)
        $this.BottomRightPanel.Size = New-Object System.Drawing.Size(610,80)
        $this.BottomRightPanel.BackColor = [System.Drawing.Color]::Black
        $this.BottomRightPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.EnableDoubleBuffering($this.BottomRightPanel)
        $this.BottomRightPanel.Add_Paint({ param($s,$e) $dashboard.DrawLearningCurves($s,$e) })
        $this.Form.Controls.Add($this.BottomRightPanel)

        # Control Panel
        $this.ControlPanel = New-Object System.Windows.Forms.Panel
        $this.ControlPanel.Location = New-Object System.Drawing.Point(10,920)
        $this.ControlPanel.Size = New-Object System.Drawing.Size(1560,60)
        $this.ControlPanel.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
        $this.ControlPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $this.Form.Controls.Add($this.ControlPanel)
    }

    # ------------------ CONTROLS ------------------
    [void] InitializeControls() {
        $dashboard = $this

        # Play Button
        $this.BtnPlay = New-Object System.Windows.Forms.Button
        $this.BtnPlay.Location = New-Object System.Drawing.Point(10,15)
        $this.BtnPlay.Size = New-Object System.Drawing.Size(80,30)
        $this.BtnPlay.Text = "▶ Play"
        $this.BtnPlay.BackColor = [System.Drawing.Color]::DarkGray
        $this.BtnPlay.ForeColor = [System.Drawing.Color]::White
        $this.BtnPlay.Add_Click({ $dashboard.TogglePlay() })
        $this.ControlPanel.Controls.Add($this.BtnPlay)

        # Step Button
        $btnStep = New-Object System.Windows.Forms.Button
        $btnStep.Location = New-Object System.Drawing.Point(100,15)
        $btnStep.Size = New-Object System.Drawing.Size(80,30)
        $btnStep.Text = "⏭ Step"
        $btnStep.BackColor = [System.Drawing.Color]::DarkGray
        $btnStep.ForeColor = [System.Drawing.Color]::White
        $btnStep.Add_Click({ $dashboard.StepQuarter() })
        $this.ControlPanel.Controls.Add($btnStep)

        # Reset Button
        $btnReset = New-Object System.Windows.Forms.Button
        $btnReset.Location = New-Object System.Drawing.Point(190,15)
        $btnReset.Size = New-Object System.Drawing.Size(80,30)
        $btnReset.Text = "🔄 Reset"
        $btnReset.BackColor = [System.Drawing.Color]::DarkGray
        $btnReset.ForeColor = [System.Drawing.Color]::White
        $btnReset.Add_Click({ $dashboard.ResetSimulation() })
        $this.ControlPanel.Controls.Add($btnReset)

        # Speed Slider
        $trackSpeed = New-Object System.Windows.Forms.TrackBar
        $trackSpeed.Location = New-Object System.Drawing.Point(300,10)
        $trackSpeed.Size = New-Object System.Drawing.Size(200,40)
        $trackSpeed.Minimum = 1
        $trackSpeed.Maximum = 10
        $trackSpeed.Value = 1
        $trackSpeed.TickFrequency = 1
        $trackSpeed.Add_ValueChanged({ 
            $dashboard.Speed = $trackSpeed.Value
            if ($dashboard.IsPlaying) {
                $dashboard.Timer.Interval = [Math]::Max(100, (1000 / $trackSpeed.Value))
            }
        })
        $this.ControlPanel.Controls.Add($trackSpeed)
    }

    # ------------------ TIMER & PLAY ------------------
    [void] InitializeTimer() {
        $dashboard = $this
        $this.Timer = New-Object System.Windows.Forms.Timer
        $this.Timer.Interval = 1000
        $this.Timer.Add_Tick({ if ($dashboard.IsPlaying) { $dashboard.StepQuarter() } })
    }

    [void] TogglePlay() {
        $this.IsPlaying = -not $this.IsPlaying
        if ($this.IsPlaying) {
            $this.BtnPlay.Text = "⏸ Pause"
            $this.Timer.Interval = [Math]::Max(100,(1000 / $this.Speed))
            $this.Timer.Start()
            $this.LogEvent("▶ AUTO-PLAY started ($($this.Speed)x speed)")
        } else {
            $this.BtnPlay.Text = "▶ Play"
            $this.Timer.Stop()
            $this.LogEvent("⏸ AUTO-PLAY paused")
        }
    }

    [void] StepQuarter() {
        $this.Market.SimulateQuarter()
        $this.CaptureSnapshot()
        $this.CheckForMajorEvents()
        $this.TopPanel.Invalidate()
        $this.MiddleLeftPanel.Invalidate()
        $this.MiddleRightPanel.Invalidate()
        $this.BottomLeftPanel.Invalidate()
        $this.BottomRightPanel.Invalidate()
    }

    [void] ResetSimulation() {
        $this.IsPlaying = $false
        $this.Timer.Stop()
        $this.BtnPlay.Text = "▶ Play"
        if ($this.Market.PSObject.Methods['Reset']) { $this.Market.Reset() }
        $this.ProfitHistory.Clear()
        $this.MarketShareHistory.Clear()
        $this.EventLog.Clear()
        $this.DecisionHistory.Clear()
        $this.LogEvent("🔄 SIMULATION RESET")
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
            $snapshot.Decisions[$company.Name] = if ($company.PSObject.Properties['LastAction']) { $company.LastAction.Name } else { "Hold" }
        }
        [void]$this.ProfitHistory.Add($snapshot)
        [void]$this.DecisionHistory.Add($snapshot)
    }

    [void] CheckForMajorEvents() { }

    # ------------------ DRAW METHODS ------------------
    [void] DrawTopPanel($s,$e) {
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear([System.Drawing.Color]::Black)
        # You can add Market Share Pie, Economic Indicators with bright colors here
    }

    [void] DrawProfitTrends($s,$e) {
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear([System.Drawing.Color]::Black)
        # Draw 4 bright lines for profits
    }

    [void] DrawDecisionHeatmap($s,$e) { $e.Graphics.Clear([System.Drawing.Color]::Black) }
    [void] DrawEventLog($s,$e) { $e.Graphics.Clear([System.Drawing.Color]::Black) }
    [void] DrawLearningCurves($s,$e) { $e.Graphics.Clear([System.Drawing.Color]::Black) }

    # ------------------ SHOW ------------------
    [void] Show() {
        $this.Form.ShowDialog()
    }
}

# ------------------ Example Usage ------------------
# $market = <your MarketEnvironment object here>
# $dashboard = [MarketDashboard]::new($market)
# $dashboard.Show()
