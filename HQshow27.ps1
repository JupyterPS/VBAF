# ====================================================
# HQshow27.ps1 — Global Market Pulse v3
# Enhanced Risk Dashboard
# Converted to Game Machine Architecture
# ====================================================

# ============================================
# Show27 - Inherits from BaseShow
# ============================================
class Show27 : BaseShow {
    hidden [System.Windows.Forms.DataVisualization.Charting.Chart] $LineChart
    hidden [System.Windows.Forms.DataVisualization.Charting.Series] $LineSeries
    hidden [hashtable] $BarPanels
    hidden [System.Collections.ArrayList] $HeatCells
    hidden [System.Windows.Forms.Label] $LblHeroValue
    hidden [System.Windows.Forms.Timer] $UpdateTimer
    hidden [int] $TickCount
    hidden [System.Windows.Forms.TableLayoutPanel] $RootLayout

    Show27([System.Windows.Forms.Panel]$panel) : base("show27", $panel) {
        $this.TickCount = 0
        $this.BarPanels = @{}
        $this.HeatCells = [System.Collections.ArrayList]::new()
    }

    [void] OnStart() {
        Write-Host " 🌍 [Show27] Initializing Global Market Pulse..." -ForegroundColor Cyan
        
        $this.Panel.Controls.Clear()
        
        # Ticker messages
        $Show27Messages = @(
            "🌍 Welcome to SHOW27: Global Market Pulse",
            "📈 Real-time market indices simulated",
            "💡 Observe sector growth & market volatility",
            "🔵 Blue = Stability | 🔴 Red = Volatility",
            "✨ Interactive charts update continuously"
        )
        $global:messages = $Show27Messages
        Update-Ticker
        
        # Create layout and UI
        $this.CreateLayout()
        $this.SetupLineChart()
        $this.CreateBarPanels()
        $this.CreateHeatmap()
        $this.CreateHeroPanel()
        $this.SetupUpdateTimer()
        
        Write-Host " ✅ [Show27] Risk Dashboard ready" -ForegroundColor Green
    }

    [void] OnUpdate() {
        # Timer-based updates handled separately - no per-frame needed
    }

    [void] OnStop() {
        Write-Host " 🛑 [Show27] Cleaning up Risk Dashboard..." -ForegroundColor Yellow
        
        if ($this.UpdateTimer) {
            $this.UpdateTimer.Stop()
            $this.UpdateTimer.Dispose()
            $this.UpdateTimer = $null
        }
        
        $this.Panel.Controls.Clear()
        $this.BarPanels.Clear()
        $this.HeatCells.Clear()
        $this.TickCount = 0
        
        Write-Host " ✅ [Show27] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] CreateLayout() {
        $this.RootLayout = New-Object System.Windows.Forms.TableLayoutPanel
        $this.RootLayout.Dock = 'Fill'
        $this.RootLayout.ColumnCount = 2
        $this.RootLayout.RowCount = 2
        $this.RootLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 60)))
        $this.RootLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 40)))
        $this.RootLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 60)))
        $this.RootLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', 40)))
        $this.Panel.Controls.Add($this.RootLayout)
    }

    hidden [void] SetupLineChart() {
        $this.LineChart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $this.LineChart.Dock = 'Fill'
        $this.RootLayout.Controls.Add($this.LineChart, 0, 0)

        $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $chartArea.AxisX.Title = "Time (beats)"
        $chartArea.AxisY.Title = "Risk Signal"
        $chartArea.AxisX.Interval = 1
        $this.LineChart.ChartAreas.Add($chartArea)

        $this.LineSeries = New-Object System.Windows.Forms.DataVisualization.Charting.Series
        $this.LineSeries.Name = "RiskTrace"
        $this.LineSeries.ChartType = 'Line'
        $this.LineSeries.BorderWidth = 3
        $this.LineSeries.Color = [System.Drawing.Color]::DarkRed
        $this.LineChart.Series.Add($this.LineSeries)

        # Initialize points
        for ($i = 0; $i -lt 8; $i++) {
            [void]$this.LineSeries.Points.AddXY($i, 50 + (Get-Random -Minimum -8 -Maximum 9))
        }
    }

    hidden [void] CreateBarPanels() {
        $panelBars = New-Object System.Windows.Forms.Panel
        $panelBars.Dock = 'Fill'
        $this.RootLayout.Controls.Add($panelBars, 1, 0)

        $lblBarsTitle = New-Object System.Windows.Forms.Label
        $lblBarsTitle.Text = "Audit Coverage & Resource Allocation"
        $lblBarsTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $lblBarsTitle.AutoSize = $true
        $lblBarsTitle.Location = [System.Drawing.Point]::new(6,6)
        $panelBars.Controls.Add($lblBarsTitle)

        $resources = @("Policy","Infra","Ops","QA")
        $y = 40
        
        foreach ($res in $resources) {
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = $res
            $lbl.Location = [System.Drawing.Point]::new(6,$y)
            $lbl.Width = 80
            $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $panelBars.Controls.Add($lbl)

            $container = New-Object System.Windows.Forms.Panel
            $container.Location = [System.Drawing.Point]::new(90,$y)
            $container.Size = [System.Drawing.Size]::new(300,24)
            $container.BackColor = [System.Drawing.Color]::LightGray
            $panelBars.Controls.Add($container)

            $filled = New-Object System.Windows.Forms.Panel
            $filled.Size = [System.Drawing.Size]::new(0,24)
            $filled.BackColor = [System.Drawing.Color]::FromArgb(60,149,49)
            $container.Controls.Add($filled)

            $lblValue = New-Object System.Windows.Forms.Label
            $lblValue.Location = [System.Drawing.Point]::new(400, $y)
            $lblValue.Width = 60
            $lblValue.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $panelBars.Controls.Add($lblValue)

            $this.BarPanels[$res] = @{
                container = $container
                filled = $filled
                label = $lblValue
                value = (Get-Random -Minimum 20 -Maximum 80)
            }
            $y += 36
        }
    }

    hidden [void] CreateHeatmap() {
        $heatPanel = New-Object System.Windows.Forms.Panel
        $heatPanel.Dock = 'Fill'
        $this.RootLayout.Controls.Add($heatPanel, 0, 1)

        $rows = 5; $cols = 6
        $grid = New-Object System.Windows.Forms.TableLayoutPanel
        $grid.Dock = 'Left'
        $grid.ColumnCount = $cols
        $grid.RowCount = $rows
        $grid.Width = 300

        for ($c = 0; $c -lt $cols; $c++) {
            $grid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', (100/$cols))))
        }
        for ($r = 0; $r -lt $rows; $r++) {
            $grid.RowStyles.Add((New-Object System.Windows.Forms.RowStyle('Percent', (100/$rows))))
        }
        $heatPanel.Controls.Add($grid)

        for ($r = 0; $r -lt $rows; $r++) {
            for ($c = 0; $c -lt $cols; $c++) {
                $cell = New-Object System.Windows.Forms.Panel
                $cell.Dock = 'Fill'
                $cell.Margin = [System.Windows.Forms.Padding]::new(4)
                $cell.BorderStyle = 'FixedSingle'
                $cell.Tag = Get-Random -Minimum 0 -Maximum 100
                $grid.Controls.Add($cell, $c, $r)
                [void]$this.HeatCells.Add($cell)
            }
        }
    }

    hidden [void] CreateHeroPanel() {
        $heroPanel = New-Object System.Windows.Forms.Panel
        $heroPanel.Dock = 'Fill'
        $this.RootLayout.Controls.Add($heroPanel, 1, 1)

        $lblHeroTitle = New-Object System.Windows.Forms.Label
        $lblHeroTitle.Text = "✨ GLOBAL RISK SCORE"
        $lblHeroTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $lblHeroTitle.AutoSize = $true
        $lblHeroTitle.Location = [System.Drawing.Point]::new(12,12)
        $heroPanel.Controls.Add($lblHeroTitle)

        $this.LblHeroValue = New-Object System.Windows.Forms.Label
        $this.LblHeroValue.Text = "0"
        $this.LblHeroValue.Font = New-Object System.Drawing.Font("Segoe UI", 34, [System.Drawing.FontStyle]::Bold)
        $this.LblHeroValue.AutoSize = $true
        $this.LblHeroValue.Location = [System.Drawing.Point]::new(12,50)
        $heroPanel.Controls.Add($this.LblHeroValue)
    }

    hidden [void] SetupUpdateTimer() {
        $self = $this
        $this.UpdateTimer = New-Object System.Windows.Forms.Timer
        $this.UpdateTimer.Interval = 600
        $this.UpdateTimer.Add_Tick({
            $self.TickCount++
            
            # Line chart update
            $x = $self.LineSeries.Points.Count
            $newY = [math]::Round(50 + (Get-Random -Minimum -18 -Maximum 22) + (12 * [math]::Sin($self.TickCount/2)), 0)
            [void]$self.LineSeries.Points.AddXY($x, $newY)

            if ($self.LineSeries.Points.Count -gt 30) {
                $self.LineSeries.Points.RemoveAt(0)
            }

            try {
                $self.LineChart.ChartAreas[0].AxisX.Minimum = $self.LineSeries.Points[0].XValue
                $self.LineChart.ChartAreas[0].AxisX.Maximum = $self.LineSeries.Points[-1].XValue
                $self.LineChart.ChartAreas[0].RecalculateAxesScale()
            } catch {}

            $recentVals = ($self.LineSeries.Points | Select-Object -Last 8 | ForEach-Object { $_.YValues[0] })
            $volatility = [math]::Round(($recentVals | Measure-Object -Maximum).Maximum - ($recentVals | Measure-Object -Minimum).Minimum, 0)

            if ($volatility -gt 25) {
                $self.LineSeries.Color = [System.Drawing.Color]::Crimson
            } elseif ($volatility -gt 12) {
                $self.LineSeries.Color = [System.Drawing.Color]::OrangeRed
            } else {
                $self.LineSeries.Color = [System.Drawing.Color]::DarkRed
            }

            # Bars update
            foreach ($k in $self.BarPanels.Keys) {
                $entry = $self.BarPanels[$k]
                $target = $entry.value + (Get-Random -Minimum -6 -Maximum 10)
                $target = [math]::Max(2, [math]::Min(98, $target))
                $entry.value = $target
                $fillW = [math]::Round(($entry.container.Width * $entry.value) / 100)
                $entry.filled.Width = $fillW
                $entry.label.Text = "$($entry.value)%"

                if ($entry.value -lt 40) {
                    $entry.filled.BackColor = [System.Drawing.Color]::FromArgb(60,149,49)
                    $entry.label.ForeColor = [System.Drawing.Color]::Green
                } elseif ($entry.value -lt 70) {
                    $entry.filled.BackColor = [System.Drawing.Color]::Goldenrod
                    $entry.label.ForeColor = [System.Drawing.Color]::Goldenrod
                } else {
                    $entry.filled.BackColor = [System.Drawing.Color]::Crimson
                    $entry.label.ForeColor = [System.Drawing.Color]::Red
                }
            }

            # Heatmap update
            $totalRisk = 0
            foreach ($cell in $self.HeatCells) {
                $current = [int]$cell.Tag
                $delta = Get-Random -Minimum -6 -Maximum 10
                $new = [math]::Max(0, [math]::Min(100, $current + $delta))
                $cell.Tag = $new

                if ($new -lt 40) {
                    $cell.BackColor = [System.Drawing.Color]::FromArgb(220,255,220)
                } elseif ($new -lt 65) {
                    $cell.BackColor = [System.Drawing.Color]::FromArgb(255,250,200)
                } elseif ($new -lt 85) {
                    $cell.BackColor = [System.Drawing.Color]::FromArgb(255, 200, 160)
                } else {
                    $cell.BackColor = [System.Drawing.Color]::FromArgb(255, 160, 160)
                }
                $totalRisk += $new
            }

            $avgRisk = [math]::Round($totalRisk / $self.HeatCells.Count, 0)
            $self.LblHeroValue.Text = $avgRisk.ToString()

            if ($avgRisk -lt 40) {
                $self.LblHeroValue.ForeColor = [System.Drawing.Color]::Green
            } elseif ($avgRisk -lt 70) {
                $self.LblHeroValue.ForeColor = [System.Drawing.Color]::Goldenrod
            } else {
                $self.LblHeroValue.ForeColor = [System.Drawing.Color]::Red
            }
        }.GetNewClosure())
        
        $this.UpdateTimer.Start()
    }
}

# Legacy compatibility
function Stop-Show27 {
    Write-Host "🛑 [Show27] Stop called (v3)" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show27")) {
        $Global:ShowManager.Shows["show27"].Stop()
    }
}

Write-Host "✅ COMPLETE Show27 v3 - Copy/Paste READY for ISE!" -ForegroundColor Green

