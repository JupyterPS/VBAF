# ==============================================
# Show35 - HQ Dashboard (NO COLOR PROPERTIES)
# ==============================================

class Show35 : BaseShow {
    hidden [System.Windows.Forms.Panel] $ContainerPanel

    Show35([System.Windows.Forms.Panel]$panel) : base("show35", $panel) { }

    [void] OnStart() {
        Write-Host "📊 [Show35] HQ Dashboard initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::White
        
        $Show35Messages = @(
            "Here are news from show35 (HQ Dashboard)...",
            "💹 Sales growing steadily across months",
            "💸 Expenses under continuous monitoring",
            "📊 Revenue distribution: Product A, B, C",
            "📈 Profit margins show healthy upward trend",
            "⚖️ HQ balancing growth and costs in real-time"
        )
        $global:messages = $Show35Messages
        if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
        
        $this.ContainerPanel = New-Object System.Windows.Forms.Panel
        $this.ContainerPanel.Dock = 'Fill'
        $this.ContainerPanel.AutoScroll = $true
        $this.ContainerPanel.BackColor = [System.Drawing.Color]::White
        $this.Panel.Controls.Add($this.ContainerPanel)
        
        $this.CreateCharts()
        $this.SetupVisibleChanged()
        
        Write-Host "✅ [Show35] HQ Dashboard ready with 4 charts!" -ForegroundColor Green
    }

    [void] OnUpdate() { }

    [void] OnStop() {
        Write-Host "🛑 [Show35] HQ Dashboard cleanup..." -ForegroundColor Yellow
        
        if ($this.ContainerPanel) {
            $this.ContainerPanel.Controls.Clear()
            $this.Panel.Controls.Remove($this.ContainerPanel)
            $this.ContainerPanel.Dispose()
            $this.ContainerPanel = $null
        }
        
        Write-Host "✔️ [Show35] Cleanup complete!" -ForegroundColor Green
    }

    hidden [void] CreateCharts() {
        $chart1 = $this.CreateColumnChart("Sales Growth", (New-Object Drawing.Point(20, 20)), @(5000, 6000, 7000, 8000, 8500, 9000, 9500, 10000, 10500))
        $this.ContainerPanel.Controls.Add($chart1)

        $chart2 = $this.CreateLineChart("Expenses", (New-Object Drawing.Point(340, 20)), @(12000, 15000, 17000, 19000, 21000, 23000, 25000, 27000))
        $this.ContainerPanel.Controls.Add($chart2)

        $chart3 = $this.CreatePieChart("Revenue Distribution", (New-Object Drawing.Point(20, 220)), @(40000, 25000, 15000))
        $this.ContainerPanel.Controls.Add($chart3)

        $chart4 = $this.CreateLineChart("Profit Trend", (New-Object Drawing.Point(340, 220)), @(10000, 12000, 14000, 16000, 18000, 20000, 22000))
        $this.ContainerPanel.Controls.Add($chart4)
    }

    hidden [object] CreateColumnChart([string]$title, [Drawing.Point]$location, [array]$data) {
        return $this.CreateChart($title, "Column", $location, $data)
    }

    hidden [object] CreateLineChart([string]$title, [Drawing.Point]$location, [array]$data) {
        return $this.CreateChart($title, "Line", $location, $data)
    }

    hidden [object] CreatePieChart([string]$title, [Drawing.Point]$location, [array]$data) {
        return $this.CreateChart($title, "Pie", $location, $data)
    }

    hidden [object] CreateChart([string]$title, [string]$chartType, [Drawing.Point]$location, [array]$data) {
        $chart = New-Object Windows.Forms.DataVisualization.Charting.Chart
        $chart.Size = New-Object Drawing.Size(300, 180)
        $chart.Location = $location
        $chart.BackColor = [System.Drawing.Color]::White
        $chart.BorderlineColor = [System.Drawing.Color]::LightGray
        $chart.BorderlineWidth = 1

        $chartArea = New-Object Windows.Forms.DataVisualization.Charting.ChartArea
        $chartArea.BackColor = [System.Drawing.Color]::White
        $chart.ChartAreas.Add($chartArea)

        $series = New-Object Windows.Forms.DataVisualization.Charting.Series
        $series.Name = $title
        $series.ChartType = $chartType
        $series.BorderWidth = 2
        
        # FIXED: Use BorderColor ONLY - NEVER Color!
        $series.BorderColor = [System.Drawing.Color]::DarkBlue

        for ($i = 0; $i -lt $data.Length; $i++) {
            [void]$series.Points.AddXY(($i + 1), $data[$i])
        }

        $chart.Series.Add($series)

        $chartTitle = New-Object Windows.Forms.DataVisualization.Charting.Title
        $chartTitle.Text = $title
        $chartTitle.Font = (New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold))
        $chartTitle.ForeColor = [System.Drawing.Color]::DarkBlue
        $chartTitle.Alignment = [System.Drawing.ContentAlignment]::MiddleCenter
        $chart.Titles.Add($chartTitle)

        if ($chartType -ne "Pie") {
            $chartArea.AxisX.Title = 'Time'
            $chartArea.AxisY.Title = 'Value (thousands)'
            $chartArea.AxisY.Minimum = 0
        }

        return $chart
    }

    hidden [void] SetupVisibleChanged() {
        $self = $this
        $this.Panel.Add_VisibleChanged({
            param($s, $e)
            if ($self.Panel.Visible) {
                $Show35Messages = @(
                    "Here are news from show35 (HQ Dashboard)...",
                    "💹 Sales growing steadily across months",
                    "💸 Expenses under continuous monitoring",
                    "📊 Revenue distribution: Product A, B, C",
                    "📈 Profit margins show healthy upward trend",
                    "⚖️ HQ balancing growth and costs in real-time"
                )
                $global:messages = $Show35Messages
                if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
            }
        }.GetNewClosure())
    }
}

# Legacy compatibility
function Stop-Show35 {
    Write-Host "🛑 [Show35] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show35")) {
        $Global:ShowManager.Shows["show35"].Stop()
    }
}

Write-Host "✅ Show35 - BorderColor ONLY = WORKS!" -ForegroundColor Green
Write-Host "📊 TreeView → Show35 → 4 BEAUTIFUL CHARTS!" -ForegroundColor Cyan

