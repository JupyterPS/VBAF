# ====================================================
# HQshowA.ps1 — Overview Dashboard v3
# Converted to Game Machine Architecture
# ====================================================

Write-Host "`n=> _____ HQshowA (Overview v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# ShowA - Inherits from BaseShow
# ============================================
class ShowA : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [System.Windows.Forms.Panel] $ChartsPanel
    hidden [System.Collections.ArrayList] $Charts
    
    # ========================================
    # Constructor
    # ========================================
    ShowA([System.Windows.Forms.Panel]$panel) : base("showA", $panel) {
        # Initialize collections
        $this.Charts = [System.Collections.ArrayList]::new()
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  📊 [ShowA] Initializing Overview Dashboard..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::White
        
        # Create charts panel
        $this.CreateChartsPanel()
        
        # Add example charts
        $this.AddExampleCharts()
        
        Write-Host "  ✅ [ShowA] Overview Dashboard ready with $($this.Charts.Count) charts" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM
    [void] OnUpdate() {
        # ShowA is static charts, no animation needed
        # But you could add dynamic updates here if needed:
        # - Update chart values from live data
        # - Animate chart transitions
        # - Refresh data periodically
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [ShowA] Cleaning up..." -ForegroundColor Yellow
        
        # Clear charts collection
        if ($this.Charts) {
            $this.Charts.Clear()
        }
        
        # Clear panels
        if ($this.ChartsPanel) {
            $this.ChartsPanel.Controls.Clear()
        }
        
        $this.Panel.Controls.Clear()
        
        Write-Host "  ✅ [ShowA] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Create charts panel container
    hidden [void] CreateChartsPanel() {
        $this.ChartsPanel = New-Object System.Windows.Forms.Panel
        $this.ChartsPanel.Location = New-Object System.Drawing.Point(0, 0)
        $this.ChartsPanel.Size = New-Object System.Drawing.Size(650, 400)
        $this.ChartsPanel.BackColor = [System.Drawing.Color]::White
        $this.Panel.Controls.Add($this.ChartsPanel)
    }
    
    # Add chart to panel
    hidden [void] AddChart([string]$title, [string[]]$labels, [int[]]$values, [int]$x, [int]$y) {
        # Create chart
        $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $chart.Size = New-Object System.Drawing.Size(300, 140)
        $chart.Location = New-Object System.Drawing.Point($x, $y)
        $chart.BackColor = [System.Drawing.Color]::White
        
        # Add to panel
        $this.ChartsPanel.Controls.Add($chart)
        
        # Force handle creation
        $null = $chart.Handle
        
        # Create chart area
        $area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $area.Name = "MainArea"
        $area.BackColor = [System.Drawing.Color]::White
        $chart.ChartAreas.Add($area)
        
        # Create series
        $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
        $series.Name = $title
        $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
        $series.ChartArea = "MainArea"
        
        # Add data points
        for ($i = 0; $i -lt $labels.Count; $i++) {
            $pointIndex = $series.Points.AddXY($labels[$i], $values[$i])
            
            # Color coding based on values (optional enhancement)
            if ($values[$i] -gt 25000) {
                $series.Points[$pointIndex].Color = [System.Drawing.Color]::FromArgb(46, 125, 50)  # Green
            }
            elseif ($values[$i] -gt 20000) {
                $series.Points[$pointIndex].Color = [System.Drawing.Color]::FromArgb(251, 140, 0)  # Orange
            }
            else {
                $series.Points[$pointIndex].Color = [System.Drawing.Color]::FromArgb(33, 150, 243) # Blue
            }
        }
        
        $chart.Series.Add($series)
        
        # Add title
        $titleObj = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $titleObj.Text = $title
        $titleObj.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $chart.Titles.Add($titleObj)
        
        # Store reference
        [void]$this.Charts.Add($chart)
        
        Write-Host "  📈 Chart added: $title ($($labels.Count) data points)" -ForegroundColor DarkCyan
    }
    
    # Add example charts (same as V1)
    hidden [void] AddExampleCharts() {
        # Sales chart
        $this.AddChart(
            "Sales",
            @("F", "M", "A", "M", "J", "J", "A", "S"),
            @(4500, 4800, 5100, 5800, 6200, 6000, 6700, 7500),
            0,
            0
        )
        
        # Expenses chart
        $this.AddChart(
            "Expenses",
            @("M", "P", "I", "J", "A", "O", "G", "O", "P"),
            @(16000, 23000, 18000, 20000, 22000, 25000, 26000, 29000, 31000),
            320,
            0
        )
        
        # Revenue chart
        $this.AddChart(
            "Revenue",
            @("Q1", "Q2", "Q3", "Q4"),
            @(15000, 20000, 25000, 30000),
            0,
            150
        )
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-ShowA {
    Write-Host "🛑 [ShowA] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("showA")) {
        $show = $Global:ShowManager.Shows["showA"]
        $show.Stop()
    }
    
    Write-Host "✅ [ShowA] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshowA class loaded (v3)" -ForegroundColor Green

<#

# ----------------------------
# showA (Overview) — Load HQshowA.ps1
# ----------------------------

function Load-showA {
    Write-Host "🌊 [ShowA] First time initialization..." -ForegroundColor Magenta
    $floorShows["showA"].Controls.Clear()
    $chartsPanel = New-Object System.Windows.Forms.Panel
    $chartsPanel.Location = New-Object System.Drawing.Point(0,0)
    $chartsPanel.Size = New-Object System.Drawing.Size(650,300)
    $floorShows["showA"].Controls.Add($chartsPanel)
    Set-Variable -Name chartsPanel -Value $chartsPanel -Scope Global
}

function Add-Chart($title,[string[]]$labels,[int[]]$values,[int]$x,[int]$y) {
    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Size = New-Object System.Drawing.Size(300,140)
    $chart.Location = New-Object System.Drawing.Point($x,$y)
    $chartsPanel.Controls.Add($chart)
    $null = $chart.Handle

    $area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
    $area.Name = "MainArea"
    $chart.ChartAreas.Add($area)

    $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $series.Name = $title
    $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
    $series.ChartArea = "MainArea"

    for ($i=0; $i -lt $labels.Count; $i++) {
        $series.Points.AddXY($labels[$i], $values[$i])
    }

    $chart.Series.Add($series)
    $chart.Titles.Add($title)
}

# Example charts
Add-Chart "Sales" @("F","M","A","M","J","J","A","S") @(4500,4800,5100,5800,6200,6000,6700,7500) 0 0
Add-Chart "Expenses" @("M","P","I","J","A","O","G","O","P") @(16000,23000,18000,20000,22000,25000,26000,29000,31000) 320 0
Add-Chart "Revenue" @("Q1","Q2","Q3","Q4") @(15000,20000,25000,30000) 0 150
Add-Chart "Profit" @("Q1","Q2","Q3","Q4") @(10000,15000,18000,27000) 320 150

#>

