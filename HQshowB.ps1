# ====================================================
# HQshowB.ps1 — Company Analytics Dashboard v3
# Converted to Game Machine Architecture
# ====================================================

Write-Host "`n=> _____ HQshowB (Analytics v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# ShowB - Inherits from BaseShow
# ============================================
class ShowB : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [System.Windows.Forms.TabControl] $TabControl
    hidden [System.Windows.Forms.DataGridView] $Grid
    hidden [System.Windows.Forms.DataVisualization.Charting.Chart] $ChartBar
    hidden [System.Windows.Forms.DataVisualization.Charting.Chart] $ChartPie
    hidden [System.Windows.Forms.DataVisualization.Charting.Chart] $ChartLine
    hidden [System.Data.DataTable] $DataTable
    hidden [array] $Companies
    
    # ========================================
    # Constructor
    # ========================================
    ShowB([System.Windows.Forms.Panel]$panel) : base("showB", $panel) {
        # Initialize company data
        $this.InitializeCompanies()
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  📊 [ShowB] Initializing Analytics Dashboard..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::White
        
        # Update ticker messages
        $ShowBMessages = @(
            "Here are news from SHOWB (Company Insights)...",
            "🏢 Compare industries side by side in real-time",
            "📊 Employee counts tower across major firms",
            "💰 Revenue share shows Pharma vs Energy vs Finance",
            "📈 Growth rates highlight Tech leading the way",
            "🗂️ Tab between Company Grid and Insightful Charts",
            "🔍 Drill into trends that shape tomorrow's strategy"
        )
        $Global:messages = $ShowBMessages
        
        # Create UI
        $this.CreateTabControl()
        $this.CreateGridTab()
        $this.CreateChartsTab()
        
        # Build data table
        $this.BuildDataTable()
        
        # Bind grid
        $this.Grid.DataSource = $this.DataTable
        
        # Render charts
        $this.RenderAllCharts()
        
        Write-Host "  ✅ [ShowB] Analytics Dashboard ready with $($this.Companies.Count) companies" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM
    [void] OnUpdate() {
        # ShowB is mostly static, but you could add:
        # - Live data updates
        # - Animated chart transitions
        # - Real-time ticker updates
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [ShowB] Cleaning up..." -ForegroundColor Yellow
        
        # Clear data table
        if ($this.DataTable) {
            $this.DataTable.Clear()
            $this.DataTable.Dispose()
        }
        
        # Clear charts
        if ($this.ChartBar) { $this.ChartBar.Series.Clear(); $this.ChartBar.Dispose() }
        if ($this.ChartPie) { $this.ChartPie.Series.Clear(); $this.ChartPie.Dispose() }
        if ($this.ChartLine) { $this.ChartLine.Series.Clear(); $this.ChartLine.Dispose() }
        
        # Clear grid
        if ($this.Grid) {
            $this.Grid.DataSource = $null
            $this.Grid.Dispose()
        }
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        Write-Host "  ✅ [ShowB] Cleanup complete" -ForegroundColor Green
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
                AvgSalary = 95000
                Revenue = 20000000000
                GrowthRate = 0.05
                Color = [System.Drawing.Color]::Gold
            },
            [PSCustomObject]@{ 
                Name = "Wine Company"
                Industry = "Beverage"
                Employees = 250
                AvgSalary = 22000
                Revenue = 5000000
                GrowthRate = 0.02
                Color = [System.Drawing.Color]::MediumSeaGreen
            },
            [PSCustomObject]@{ 
                Name = "Commerce Bank"
                Industry = "Finance"
                Employees = 12000
                AvgSalary = 75000
                Revenue = 1500000000
                GrowthRate = 0.03
                Color = [System.Drawing.Color]::Yellow
            },
            [PSCustomObject]@{ 
                Name = "AI Company"
                Industry = "Tech"
                Employees = 300
                AvgSalary = 85000
                Revenue = 75000000
                GrowthRate = 0.12
                Color = [System.Drawing.Color]::Orange
            },
            [PSCustomObject]@{ 
                Name = "Maersk"
                Industry = "Shipping"
                Employees = 83000
                AvgSalary = 65000
                Revenue = 350000000
                GrowthRate = 0.02
                Color = [System.Drawing.Color]::LightBlue
            },
            [PSCustomObject]@{ 
                Name = "Carlsberg"
                Industry = "Beverage"
                Employees = 40000
                AvgSalary = 46000
                Revenue = 70000000
                GrowthRate = 0.01
                Color = [System.Drawing.Color]::LightCoral
            },
            [PSCustomObject]@{ 
                Name = "Vestas"
                Industry = "Energy"
                Employees = 29000
                AvgSalary = 70000
                Revenue = 120000000
                GrowthRate = 0.04
                Color = [System.Drawing.Color]::LightSteelBlue
            }
        )
    }
    
    # Create tab control
    hidden [void] CreateTabControl() {
        $this.TabControl = New-Object System.Windows.Forms.TabControl
        $this.TabControl.Dock = 'Fill'
        $this.Panel.Controls.Add($this.TabControl)
    }
    
    # Create grid tab
    hidden [void] CreateGridTab() {
        $tabGrid = New-Object System.Windows.Forms.TabPage("Companies")
        $this.TabControl.TabPages.Add($tabGrid)
        
        $this.Grid = New-Object System.Windows.Forms.DataGridView
        $this.Grid.Dock = 'Fill'
        $this.Grid.ReadOnly = $true
        $this.Grid.AllowUserToAddRows = $false
        $this.Grid.AllowUserToDeleteRows = $false
        
        # Set styling
        $this.Grid.BackgroundColor = [System.Drawing.Color]::White
        $this.Grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::White
        $this.Grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::Black
        $this.Grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::WhiteSmoke
        $this.Grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::Black
        $this.Grid.EnableHeadersVisualStyles = $false
        
        $tabGrid.Controls.Add($this.Grid)
    }
    
    # Create charts tab
    hidden [void] CreateChartsTab() {
        $tabCharts = New-Object System.Windows.Forms.TabPage("Charts")
        $this.TabControl.TabPages.Add($tabCharts)
        
        # Main table layout
        $tableAll = New-Object System.Windows.Forms.TableLayoutPanel
        $tableAll.Dock = 'Fill'
        $tableAll.RowCount = 2
        $tableAll.ColumnCount = 1
        $tableAll.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 50)))
        $tableAll.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 50)))
        $tabCharts.Controls.Add($tableAll)
        
        # Top split (bar and pie)
        $topSplit = New-Object System.Windows.Forms.TableLayoutPanel
        $topSplit.Dock = 'Fill'
        $topSplit.RowCount = 1
        $topSplit.ColumnCount = 2
        $topSplit.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
        $topSplit.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 50)))
        $tableAll.Controls.Add($topSplit, 0, 0)
        
        # Create charts
        $this.ChartBar = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $this.ChartBar.Dock = 'Fill'
        $topSplit.Controls.Add($this.ChartBar, 0, 0)
        
        $this.ChartPie = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $this.ChartPie.Dock = 'Fill'
        $topSplit.Controls.Add($this.ChartPie, 1, 0)
        
        $this.ChartLine = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $this.ChartLine.Dock = 'Fill'
        $tableAll.Controls.Add($this.ChartLine, 0, 1)
    }
    
    # Build data table for grid
    hidden [void] BuildDataTable() {
        $this.DataTable = New-Object System.Data.DataTable
        
        # Add columns
        @("Name", "Industry", "Employees", "AvgSalary", "Revenue", "GrowthRate") | ForEach-Object {
            [void]$this.DataTable.Columns.Add($_)
        }
        
        # Add rows
        foreach ($c in $this.Companies) {
            $row = $this.DataTable.NewRow()
            $row.Name = $c.Name
            $row.Industry = $c.Industry
            $row.Employees = $c.Employees
            $row.AvgSalary = $c.AvgSalary
            $row.Revenue = $c.Revenue
            $row.GrowthRate = $c.GrowthRate
            [void]$this.DataTable.Rows.Add($row)
        }
        
        $this.DataTable.AcceptChanges()
    }
    
    # Render all charts
    hidden [void] RenderAllCharts() {
        $this.RenderBarChart()
        $this.RenderPieChart()
        $this.RenderLineChart()
    }
    
    # Render bar chart (employees)
    hidden [void] RenderBarChart() {
        $this.ChartBar.Series.Clear()
        $this.ChartBar.Titles.Clear()
        $this.ChartBar.ChartAreas.Clear()
        
        $this.ChartBar.Titles.Add("Employees per Company")
        $ca = $this.ChartBar.ChartAreas.Add("CA")
        $ca.BackColor = [System.Drawing.Color]::White
        $ca.AxisX.MajorGrid.Enabled = $false
        $ca.AxisY.MajorGrid.Enabled = $false
        $ca.AxisY.Minimum = 0
        
        $maxEmp = ($this.Companies | ForEach-Object { $_.Employees } | Measure-Object -Maximum).Maximum
        $ca.AxisY.Maximum = $maxEmp * 1.2
        
        $series = $this.ChartBar.Series.Add("Employees")
        $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Column
        
        foreach ($c in $this.Companies) {
            $pt = $series.Points.AddXY($c.Name, $c.Employees)
            $series.Points[$pt].Color = [System.Drawing.Color]::LightBlue
        }
    }
    
    # Render pie chart (revenue)
    hidden [void] RenderPieChart() {
        $this.ChartPie.Series.Clear()
        $this.ChartPie.Titles.Clear()
        $this.ChartPie.ChartAreas.Clear()
        
        $this.ChartPie.Titles.Add("Revenue Share")
        $ca = $this.ChartPie.ChartAreas.Add("CA")
        $ca.BackColor = [System.Drawing.Color]::White
        
        $series = $this.ChartPie.Series.Add("Revenue")
        $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
        $this.ChartPie.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::None
        
        foreach ($c in $this.Companies) {
            $ptIndex = $series.Points.AddXY($c.Name, $c.Revenue)
            $series.Points[$ptIndex].Color = $c.Color
            $series.Points[$ptIndex].ToolTip = "$($c.Name): $([math]::Round($c.Revenue/1e9, 2)) B"
        }
        
        $this.ChartPie.Refresh()
    }
    
    # Render line chart (growth rate)
    hidden [void] RenderLineChart() {
        $this.ChartLine.Series.Clear()
        $this.ChartLine.Titles.Clear()
        $this.ChartLine.ChartAreas.Clear()
        
        $this.ChartLine.Titles.Add("Growth Rate Trend")
        $ca = $this.ChartLine.ChartAreas.Add("CA")
        $ca.BackColor = [System.Drawing.Color]::White
        $ca.AxisX.MajorGrid.Enabled = $false
        $ca.AxisY.MajorGrid.Enabled = $false
        
        $series = $this.ChartLine.Series.Add("GrowthRate")
        $series.ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Line
        $series.IsValueShownAsLabel = $true
        $series.Palette = [System.Windows.Forms.DataVisualization.Charting.ChartColorPalette]::Excel
        
        foreach ($c in $this.Companies) {
            [void]$series.Points.AddXY($c.Name, $c.GrowthRate)
        }
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-ShowB {
    Write-Host "🛑 [ShowB] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("showB")) {
        $show = $Global:ShowManager.Shows["showB"]
        $show.Stop()
    }
    
    Write-Host "✅ [ShowB] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshowB class loaded (v3)" -ForegroundColor Green
