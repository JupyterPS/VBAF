# ====================================================
# HQshowC.ps1 — Live Simulation Dashboard v3
# Converted to Game Machine Architecture
# ====================================================

Write-Host "`n=> _____ HQshowC (Simulation v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# ShowC - Inherits from BaseShow
# ============================================
class ShowC : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [array] $Companies
    hidden [System.Windows.Forms.DataVisualization.Charting.Chart] $Chart
    hidden [System.Windows.Forms.DataGridView] $Grid
    hidden [System.Windows.Forms.ComboBox] $IntensityControl
    hidden [System.Windows.Forms.Button] $BtnStart
    hidden [System.Windows.Forms.Button] $BtnStop
    hidden [bool] $IsSimulationRunning
    hidden [int] $TickCounter
    
    # ========================================
    # Constructor
    # ========================================
    ShowC([System.Windows.Forms.Panel]$panel) : base("showC", $panel) {
        # Initialize state
        $this.State = @{
            Intensity = "Medium"
            LastUpdate = [DateTime]::Now
        }
        
        $this.IsSimulationRunning = $false
        $this.TickCounter = 0
        
        # Initialize company data
        $this.InitializeCompanies()
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  ⚡ [ShowC] Initializing Simulation Dashboard..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::White
        
        # Update ticker messages
        $ShowCMessages = @(
            "Here are news from ShowC...",
            "⚡ Market shock hits Commerce Bank",
            "💊 Pharma boom for Novo Nordisk",
            "🍷 Wine Company expands exports",
            "🤖 AI Company secures new funding"
        )
        $Global:messages = $ShowCMessages
        
        # Create UI
        $this.CreateLayout()
        
        # Initial render
        $this.RenderChart()
        $this.UpdateGrid()
        
        Write-Host "  ✅ [ShowC] Simulation Dashboard ready with $($this.Companies.Count) companies" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM (~50ms)
    [void] OnUpdate() {
        # Only update if simulation is running
        if ($this.IsSimulationRunning) {
            $this.TickCounter++
            
            # Update every 40 ticks (2 seconds at 50ms interval = 2000ms)
            if ($this.TickCounter -ge 40) {
                $this.TickCounter = 0
                $this.PulseSimulation()
            }
        }
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [ShowC] Cleaning up..." -ForegroundColor Yellow
        
        # Stop simulation
        $this.IsSimulationRunning = $false
        
        # Remove event handlers
        if ($this.BtnStart) { $this.BtnStart.Remove_Click($null) }
        if ($this.BtnStop) { $this.BtnStop.Remove_Click($null) }
        
        # Clear controls
        if ($this.Chart) {
            $this.Chart.Series.Clear()
            $this.Chart.Dispose()
        }
        if ($this.Grid) {
            $this.Grid.Rows.Clear()
            $this.Grid.Dispose()
        }
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.TickCounter = 0
        
        Write-Host "  ✅ [ShowC] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Initialize company data
    hidden [void] InitializeCompanies() {
        $this.Companies = @(
            [PSCustomObject]@{
                Name = "Novo Nordisk"
                Industry = "Pharma"
                Employees = 48000
                Revenue = 20000000000
            },
            [PSCustomObject]@{
                Name = "Wine Company"
                Industry = "Beverage"
                Employees = 250
                Revenue = 5000000
            },
            [PSCustomObject]@{
                Name = "Commerce Bank"
                Industry = "Finance"
                Employees = 12000
                Revenue = 1500000000
            },
            [PSCustomObject]@{
                Name = "AI Company"
                Industry = "Tech"
                Employees = 300
                Revenue = 75000000
            }
        )
    }
    
    # Create UI layout
    hidden [void] CreateLayout() {
        # Main table layout
        $panel = New-Object System.Windows.Forms.TableLayoutPanel
        $panel.Dock = "Fill"
        $panel.ColumnCount = 2
        $panel.RowCount = 2
        $panel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 60)))
        $panel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 40)))
        $panel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 70)))
        $panel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 30)))
        $this.Panel.Controls.Add($panel)
        
        # Create chart
        $this.CreateChart($panel)
        
        # Create grid
        $this.CreateGrid($panel)
        
        # Create controls
        $this.CreateControls($panel)
    }
    
    # Create chart
    hidden [void] CreateChart([System.Windows.Forms.TableLayoutPanel]$panel) {
        $this.Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $this.Chart.Dock = "Fill"
        
        $ca = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $ca.BackColor = [System.Drawing.Color]::FromArgb(240, 248, 255)
        $this.Chart.ChartAreas.Add($ca)
        
        $panel.Controls.Add($this.Chart, 0, 0)
        $panel.SetRowSpan($this.Chart, 2)
    }
    
    # Create grid
    hidden [void] CreateGrid([System.Windows.Forms.TableLayoutPanel]$panel) {
        $this.Grid = New-Object System.Windows.Forms.DataGridView
        $this.Grid.BackgroundColor = [System.Drawing.Color]::WhiteSmoke
        $this.Grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::WhiteSmoke
        $this.Grid.Dock = "Fill"
        $this.Grid.ReadOnly = $true
        $this.Grid.AutoSizeColumnsMode = "Fill"
        $this.Grid.ColumnCount = 3
        $this.Grid.Columns[0].Name = "Name"
        $this.Grid.Columns[1].Name = "Employees"
        $this.Grid.Columns[2].Name = "Revenue"
        
        $panel.Controls.Add($this.Grid, 1, 0)
    }
    
    # Create control buttons
    hidden [void] CreateControls([System.Windows.Forms.TableLayoutPanel]$panel) {
        $ctrlPanel = New-Object System.Windows.Forms.FlowLayoutPanel
        $ctrlPanel.Dock = "Fill"
        $panel.Controls.Add($ctrlPanel, 1, 1)
        
        # Start button
        $this.BtnStart = New-Object System.Windows.Forms.Button
        $this.BtnStart.Text = "▶ Start"
        $this.BtnStart.Width = 80
        $ctrlPanel.Controls.Add($this.BtnStart)
        
        # Stop button
        $this.BtnStop = New-Object System.Windows.Forms.Button
        $this.BtnStop.Text = "⏸ Stop"
        $this.BtnStop.Width = 80
        $ctrlPanel.Controls.Add($this.BtnStop)
        
        # Intensity label
        $lblInt = New-Object System.Windows.Forms.Label
        $lblInt.Text = "Intensity:"
        $lblInt.AutoSize = $true
        $lblInt.Margin = New-Object System.Windows.Forms.Padding(10, 5, 0, 0)
        $ctrlPanel.Controls.Add($lblInt)
        
        # Intensity combo
        $this.IntensityControl = New-Object System.Windows.Forms.ComboBox
        $this.IntensityControl.DropDownStyle = "DropDownList"
        $this.IntensityControl.Items.AddRange(@("Low", "Medium", "High"))
        $this.IntensityControl.SelectedIndex = 1
        $this.IntensityControl.Width = 100
        $ctrlPanel.Controls.Add($this.IntensityControl)
        
        # Attach event handlers
        $this.AttachEventHandlers()
    }
    
    # Attach event handlers
    hidden [void] AttachEventHandlers() {
        # CRITICAL: Capture $this as $self
        $self = $this
        
        $this.BtnStart.Add_Click({
            param($sender, $args)
            $self.IsSimulationRunning = $true
            Write-Host "  ▶ [ShowC] Simulation started" -ForegroundColor Green
        }.GetNewClosure())
        
        $this.BtnStop.Add_Click({
            param($sender, $args)
            $self.IsSimulationRunning = $false
            Write-Host "  ⏸ [ShowC] Simulation stopped" -ForegroundColor Yellow
        }.GetNewClosure())
        
        $this.IntensityControl.Add_SelectedIndexChanged({
            param($sender, $args)
            $self.State['Intensity'] = $sender.SelectedItem.ToString()
            Write-Host "  ⚙️ [ShowC] Intensity changed to: $($self.State.Intensity)" -ForegroundColor Cyan
        }.GetNewClosure())
    }
    
    # Pulse simulation (update company values)
    hidden [void] PulseSimulation() {
        # Get intensity multiplier
        $intensity = switch ($this.State.Intensity) {
            "Low"    { 0.01 }
            "Medium" { 0.05 }
            "High"   { 0.10 }
            default  { 0.05 }
        }
        
        # Update each company
        foreach ($c in $this.Companies) {
            # Revenue variance
            $revVar = Get-Random -Minimum (-$intensity) -Maximum $intensity
            $c.Revenue = [math]::Max(1.0, [math]::Round($c.Revenue * (1 + $revVar), 2))
            
            # Employee variance (smaller changes)
            $empVar = Get-Random -Minimum -0.02 -Maximum 0.02
            $c.Employees = [math]::Max(1, [math]::Round($c.Employees * (1 + $empVar), 0))
        }
        
        # Render updates
        $this.RenderChart()
        $this.UpdateGrid()
    }
    
    # Format money for display
    hidden [string] FormatMoney([double]$value) {
        if ($value -ge 1e9) {
            return "{0:N1} B" -f ($value / 1e9)
        }
        elseif ($value -ge 1e6) {
            return "{0:N1} M" -f ($value / 1e6)
        }
        else {
            return "{0:N0}" -f $value
        }
    }
    
    # Render chart
    hidden [void] RenderChart() {
        if (-not $this.Chart) { return }
        
        $this.Chart.Series.Clear()
        
        # Revenue series (columns)
        $seriesR = New-Object System.Windows.Forms.DataVisualization.Charting.Series("Revenue")
        $seriesR.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
        $seriesR.Color = [System.Drawing.Color]::RoyalBlue
        
        # Employees series (line)
        $seriesE = New-Object System.Windows.Forms.DataVisualization.Charting.Series("Employees")
        $seriesE.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
        $seriesE.Color = [System.Drawing.Color]::OrangeRed
        $seriesE.BorderWidth = 3
        
        # Add data points
        foreach ($c in $this.Companies) {
            # Revenue point
            $dpR = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint
            $dpR.AxisLabel = $c.Name
            $dpR.Label = $this.FormatMoney($c.Revenue)
            $dpR.YValues = @($c.Revenue / 1e9)
            $seriesR.Points.Add($dpR)
            
            # Employees point
            $dpE = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint
            $dpE.AxisLabel = $c.Name
            $dpE.Label = "$($c.Employees)"
            $dpE.YValues = @($c.Employees)
            $seriesE.Points.Add($dpE)
        }
        
        # Add series to chart
        $this.Chart.Series.Add($seriesR)
        $this.Chart.Series.Add($seriesE)
        
        # Set title
        $this.Chart.Titles.Clear()
        $this.Chart.Titles.Add("Live Simulation: Revenue (B) & Employees")
        
        # Configure axis
        $this.Chart.ChartAreas[0].AxisX.Interval = 1
        
        $this.Chart.Invalidate()
    }
    
    # Update grid
    hidden [void] UpdateGrid() {
        if (-not $this.Grid) { return }
        
        $this.Grid.Rows.Clear()
        
        foreach ($c in $this.Companies) {
            $this.Grid.Rows.Add(
                $c.Name,
                $c.Employees,
                $this.FormatMoney($c.Revenue)
            )
        }
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-ShowC {
    Write-Host "🛑 [ShowC] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("showC")) {
        $show = $Global:ShowManager.Shows["showC"]
        $show.Stop()
    }
    
    Write-Host "✅ [ShowC] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshowC class loaded (v3)" -ForegroundColor Green
