# VBAF.Business.CompanyPanel.ps1

class CompanyPanel {
    [System.Windows.Forms.Form]$Form
    $Company  # Reference to CompanyAgent
    
    CompanyPanel($company) {
        $this.Company = $company
        $this.InitializeForm()
    }
    
    [void] InitializeForm() {
        $this.Form = New-Object System.Windows.Forms.Form
        $this.Form.Width = 600
        $this.Form.Height = 800
        $this.Form.Text = "Company Details: $($this.Company.CompanyName)"
        $this.Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        
        # Create detail panel
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
        $panel.BackColor = [System.Drawing.Color]::White
        
        # Enable double buffering
        $prop = $panel.GetType().GetProperty("DoubleBuffered", 
            [System.Reflection.BindingFlags]"Instance,NonPublic")
        $prop.SetValue($panel, $true, $null)
        
        $panel.Add_Paint({ param($s, $e) $this.DrawCompanyDetails($s, $e) })
        $this.Form.Controls.Add($panel)
    }
    
    [void] DrawCompanyDetails($sender, $e) {
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $font = New-Object System.Drawing.Font("Arial", 11)
        $titleFont = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        
        # Title
        $g.DrawString($this.Company.CompanyName, $titleFont, $brush, 20, 20)
        $g.DrawString("Industry: $($this.Company.Industry)", $font, $brush, 20, 60)
        
        # Financial metrics
        $y = 100
        $state = $this.Company.State
        
        $g.DrawString("Financial Metrics:", $titleFont, $brush, 20, $y)
        $y += 40
        $g.DrawString("Cash: $([Math]::Round($state.Cash, 2))M", $font, $brush, 40, $y)
        $y += 25
        $g.DrawString("Revenue: $([Math]::Round($state.Revenue, 2))M", $font, $brush, 40, $y)
        $y += 25
        $g.DrawString("Profit: $([Math]::Round($state.Profit, 2))M", $font, $brush, 40, $y)
        $y += 25
        $g.DrawString("Profit Margin: $([Math]::Round($state.ProfitMargin * 100, 1))%", $font, $brush, 40, $y)
        
        # Market metrics
        $y += 50
        $g.DrawString("Market Metrics:", $titleFont, $brush, 20, $y)
        $y += 40
        $g.DrawString("Market Share: $([Math]::Round($state.MarketShare * 100, 1))%", $font, $brush, 40, $y)
        $y += 25
        $g.DrawString("Brand Value: $([Math]::Round($state.BrandValue, 2))", $font, $brush, 40, $y)
        
        # Operational metrics
        $y += 50
        $g.DrawString("Operations:", $titleFont, $brush, 20, $y)
        $y += 40
        $g.DrawString("Employees: $($state.Employees)", $font, $brush, 40, $y)
        $y += 25
        $g.DrawString("Production Capacity: $([Math]::Round($state.ProductionCapacity, 0))", $font, $brush, 40, $y)
        $y += 25
        $g.DrawString("R&D Investment: $([Math]::Round($state.RDInvestment, 2))M", $font, $brush, 40, $y)
        
        $font.Dispose()
        $titleFont.Dispose()
        $brush.Dispose()
    }
    
    [void] Show() {
        $this.Form.ShowDialog()
    }
}