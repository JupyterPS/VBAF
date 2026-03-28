# ====================================================
# HQshow26.ps1 — Stock Ticker Wall v3
# Trading Floor Command Center
# Converted to Game Machine Architecture
# ====================================================

# ============================================
# Show26 - Inherits from BaseShow
# ============================================
class Show26 : BaseShow {
    hidden [System.Collections.ArrayList] $Screens
    hidden [System.Collections.ArrayList] $DataRain
    hidden [System.Collections.ArrayList] $NewsFlashes
    hidden [hashtable] $State

    Show26([System.Windows.Forms.Panel]$panel) : base("show26", $panel) {
        $this.State = @{
            TickCount = 0
            LastNewsTime = 0
        }
        $this.Screens = [System.Collections.ArrayList]::new()
        $this.DataRain = [System.Collections.ArrayList]::new()
        $this.NewsFlashes = [System.Collections.ArrayList]::new()
    }

    [void] OnStart() {
        Write-Host " 📺 [Show26] Initializing Stock Ticker Wall..." -ForegroundColor Cyan
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 10, 15)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Ticker messages
        $Show26Messages = @(
            "STOCK TICKER WALL - Real-time Market Command Center",
            "Multiple sectors monitored simultaneously",
            "Live data streams from global markets",
            "Breaking news alerts as they happen",
            "Your window into the financial world"
        )
        $global:messages = $Show26Messages
        Update-Ticker
        
        # Initialize content
        $this.InitializeScreens()
        $this.InitializeDataRain()
        $this.SetupPaintEvent()
        
        Write-Host " ✅ [Show26] Stock Ticker Wall ready" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        # Update data rain
        foreach ($drop in $this.DataRain) {
            $drop.Y += $drop.Speed
            $drop.Life -= 1
            
            if ($drop.Y -gt 450 -or $drop.Life -le 0) {
                $drop.Y = -20
                $drop.X = Get-Random -Minimum 0 -Maximum 650
                $drop.Speed = 2 + (Get-Random -Minimum 0 -Maximum 5)
                $drop.Character = [char](Get-Random -Minimum 48 -Maximum 90)
                $drop.Life = 100
            }
        }
        
        # Update screens
        foreach ($screen in $this.Screens) {
            if ($tick % 5 -eq 0) {
                $oldPrice = $screen.CurrentPrice
                $change = (Get-Random -Minimum -50 -Maximum 50) / 10.0
                $screen.CurrentPrice = [math]::Max($screen.BasePrice * 0.8, [math]::Min($screen.BasePrice * 1.2, $screen.CurrentPrice + $change))
                
                $screen.ChangePercent = (($screen.CurrentPrice - $oldPrice) / $oldPrice) * 100
                
                [void]$screen.PriceHistory.Add($screen.CurrentPrice)
                if ($screen.PriceHistory.Count -gt 20) {
                    $screen.PriceHistory.RemoveAt(0)
                }
                
                $screen.Activity = [math]::Min(1, [math]::Abs($screen.ChangePercent) / 2)
            }
            
            $screen.Activity *= 0.9
            
            if ($tick % 10 -eq 0) {
                $screen.Volume = Get-Random -Minimum 1000 -Maximum 9999
            }
            
            $screen.Pulse = [math]::Abs([math]::Sin($tick * 0.1 + $screen.X))
        }
        
        # Spawn news flashes
        if ($tick - $this.State.LastNewsTime -gt 50) {
            $newsItems = @(
                "Tech sector rallies on AI breakthrough",
                "Energy stocks surge on demand spike",
                "Healthcare announces major merger",
                "Finance sector shows strong earnings",
                "Consumer confidence reaches new high",
                "Industrial output exceeds forecasts"
            )
            
            [void]$this.NewsFlashes.Add(@{
                Text = $newsItems | Get-Random
                Life = 80
            })
            
            $this.State.LastNewsTime = $tick
        }
        
        # Update news life
        $aliveNews = [System.Collections.ArrayList]::new()
        foreach ($news in $this.NewsFlashes) {
            $news.Life -= 1
            if ($news.Life -gt 0) {
                [void]$aliveNews.Add($news)
            }
        }
        $this.NewsFlashes = $aliveNews
        
        # Repaint
        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host " 🛑 [Show26] Cleaning up Stock Ticker..." -ForegroundColor Yellow
        
        $this.Screens.Clear()
        $this.DataRain.Clear()
        $this.NewsFlashes.Clear()
        
        if ($this.Panel) {
            $this.Panel.Remove_Paint($null)
        }
        $this.Panel.Controls.Clear()
        
        $this.State.TickCount = 0
        $this.State.LastNewsTime = 0
        
        Write-Host " ✅ [Show26] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderFrame($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }

    hidden [void] InitializeScreens() {
        $sectors = @(
            @{Name="TECHNOLOGY"; Symbol="TECH"; Color=[System.Drawing.Color]::FromArgb(0, 150, 255); BasePrice=2500},
            @{Name="FINANCE"; Symbol="FIN"; Color=[System.Drawing.Color]::FromArgb(255, 200, 0); BasePrice=1800},
            @{Name="ENERGY"; Symbol="ENRG"; Color=[System.Drawing.Color]::FromArgb(0, 255, 100); BasePrice=1200},
            @{Name="HEALTHCARE"; Symbol="HLTH"; Color=[System.Drawing.Color]::FromArgb(255, 100, 200); BasePrice=2200},
            @{Name="CONSUMER"; Symbol="CONS"; Color=[System.Drawing.Color]::FromArgb(255, 150, 50); BasePrice=1500},
            @{Name="INDUSTRIAL"; Symbol="IND"; Color=[System.Drawing.Color]::FromArgb(150, 150, 255); BasePrice=1600}
        )
        
        $cols = 3; $rows = 2
        $screenWidth = 200; $screenHeight = 140
        $marginX = 20; $marginY = 60
        $spacingX = 210; $spacingY = 150
        
        $idx = 0
        for ($r = 0; $r -lt $rows; $r++) {
            for ($c = 0; $c -lt $cols; $c++) {
                if ($idx -ge $sectors.Count) { break }
                
                $sector = $sectors[$idx]
                $x = $marginX + ($c * $spacingX)
                $y = $marginY + ($r * $spacingY)
                
                $priceHistory = [System.Collections.ArrayList]::new()
                for ($i = 0; $i -lt 20; $i++) {
                    [void]$priceHistory.Add($sector.BasePrice)
                }
                
                [void]$this.Screens.Add(@{
                    X = $x; Y = $y; Width = $screenWidth; Height = $screenHeight
                    Name = $sector.Name; Symbol = $sector.Symbol; Color = $sector.Color
                    BasePrice = $sector.BasePrice; CurrentPrice = $sector.BasePrice
                    PriceHistory = $priceHistory; ChangePercent = 0; Volume = Get-Random -Minimum 1000 -Maximum 9999
                    Pulse = 0; Activity = 0
                })
                $idx++
            }
        }
    }

    hidden [void] InitializeDataRain() {
        for ($i = 0; $i -lt 30; $i++) {
            [void]$this.DataRain.Add(@{
                X = Get-Random -Minimum 0 -Maximum 650
                Y = Get-Random -Minimum -400 -Maximum 0
                Speed = 2 + (Get-Random -Minimum 0 -Maximum 5)
                Character = [char](Get-Random -Minimum 48 -Maximum 90)
                Life = 100
            })
        }
    }

    hidden [void] RenderFrame([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(5, 10, 15), [System.Drawing.Color]::FromArgb(15, 20, 30)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Data rain
        foreach ($drop in $this.DataRain) {
            $alpha = [math]::Min(255, $drop.Life * 2)
            $color = [System.Drawing.Color]::FromArgb($alpha, 0, 255, 100)
            $font = New-Object System.Drawing.Font("Consolas", 10)
            $brush = New-Object System.Drawing.SolidBrush($color)
            $g.DrawString($drop.Character, $font, $brush, $drop.X, $drop.Y)
            $brush.Dispose(); $font.Dispose()
        }
        
        # Screens
        foreach ($screen in $this.Screens) {
            $x = $screen.X; $y = $screen.Y; $w = $screen.Width; $h = $screen.Height
            
            # Glow
            if ($screen.Activity -gt 0.3) {
                $glowAlpha = [int]($screen.Activity * 100)
                $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($glowAlpha, $screen.Color.R, $screen.Color.G, $screen.Color.B))
                $g.FillRectangle($glowBrush, $x - 5, $y - 5, $w + 10, $h + 10)
                $glowBrush.Dispose()
            }
            
            # Screen background
            $screenBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 25, 35))
            $g.FillRectangle($screenBg, $x, $y, $w, $h)
            $screenBg.Dispose()
            
            # Border
            $borderPen = New-Object System.Drawing.Pen($screen.Color, 2)
            $g.DrawRectangle($borderPen, $x, $y, $w, $h)
            $borderPen.Dispose()
            
            # Header
            $headerFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $headerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString($screen.Name, $headerFont, $headerBrush, $x + 5, $y + 5)
            $headerFont.Dispose(); $headerBrush.Dispose()
            
            # Symbol
            $symbolFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
            $symbolBrush = New-Object System.Drawing.SolidBrush($screen.Color)
            $g.DrawString($screen.Symbol, $symbolFont, $symbolBrush, $x + 5, $y + 25)
            $symbolFont.Dispose(); $symbolBrush.Dispose()
            
            # Price
            $priceColor = if ($screen.ChangePercent -gt 0) { 
                [System.Drawing.Color]::LimeGreen 
            } elseif ($screen.ChangePercent -lt 0) { 
                [System.Drawing.Color]::Red 
            } else { 
                [System.Drawing.Color]::White 
            }
            $priceFont = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
            $priceBrush = New-Object System.Drawing.SolidBrush($priceColor)
            $priceText = "$([math]::Round($screen.CurrentPrice, 2))"
            $g.DrawString($priceText, $priceFont, $priceBrush, $x + $w - 70, $y + 5)
            $priceFont.Dispose(); $priceBrush.Dispose()
            
            # Change %
            $changeFont = New-Object System.Drawing.Font("Consolas", 9)
            $changeBrush = New-Object System.Drawing.SolidBrush($priceColor)
            $changeText = if ($screen.ChangePercent -ge 0) { 
                "+$([math]::Round($screen.ChangePercent, 2))%" 
            } else { 
                "$([math]::Round($screen.ChangePercent, 2))%" 
            }
            $g.DrawString($changeText, $changeFont, $changeBrush, $x + $w - 70, $y + 25)
            $changeFont.Dispose(); $changeBrush.Dispose()
            
            # Mini chart
            $chartY = $y + 50; $chartH = $h - 70; $chartW = $w - 10
            
            if ($screen.PriceHistory.Count -gt 1) {
                $minPrice = ($screen.PriceHistory | Measure-Object -Minimum).Minimum
                $maxPrice = ($screen.PriceHistory | Measure-Object -Maximum).Maximum
                $priceRange = $maxPrice - $minPrice
                if ($priceRange -eq 0) { $priceRange = 1 }
                
                $pointSpacing = $chartW / ($screen.PriceHistory.Count - 1)
                
                for ($i = 1; $i -lt $screen.PriceHistory.Count; $i++) {
                    $price1 = $screen.PriceHistory[$i - 1]
                    $price2 = $screen.PriceHistory[$i]
                    
                    $x1 = $x + 5 + (($i - 1) * $pointSpacing)
                    $y1 = $chartY + $chartH - ((($price1 - $minPrice) / $priceRange) * $chartH)
                    
                    $x2 = $x + 5 + ($i * $pointSpacing)
                    $y2 = $chartY + $chartH - ((($price2 - $minPrice) / $priceRange) * $chartH)
                    
                    $chartPen = New-Object System.Drawing.Pen($screen.Color, 2)
                    $g.DrawLine($chartPen, $x1, $y1, $x2, $y2)
                    $chartPen.Dispose()
                }
            }
            
            # Volume
            $volFont = New-Object System.Drawing.Font("Consolas", 8)
            $volBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 200, 200, 200))
            $volText = "Vol: $($screen.Volume)K"
            $g.DrawString($volText, $volFont, $volBrush, $x + 5, $y + $h - 18)
            $volFont.Dispose(); $volBrush.Dispose()
        }
        
        # News flashes
        $newsY = 10
        foreach ($news in $this.NewsFlashes) {
            if ($news.Life -gt 0) {
                $alpha = [math]::Min(255, $news.Life * 3)
                $newsColor = [System.Drawing.Color]::FromArgb($alpha, 255, 200, 0)
                $newsFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $newsBrush = New-Object System.Drawing.SolidBrush($newsColor)
                $g.DrawString("⚡ $($news.Text)", $newsFont, $newsBrush, 10, $newsY)
                $newsBrush.Dispose(); $newsFont.Dispose()
                $newsY += 25
            }
        }
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 255, 255))
        $title = "✨ MARKET COMMAND CENTER"
        $titleSize = $g.MeasureString($title, $titleFont)
        $g.DrawString($title, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, $height - 35)
        $titleFont.Dispose(); $titleBrush.Dispose()
    }
}

# Legacy compatibility
function Stop-Show26 {
    Write-Host "🛑 [Show26] Stop called (v3)" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show26")) {
        $Global:ShowManager.Shows["show26"].Stop()
    }
}

Write-Host "✅ COMPLETE Show26 v3 - Copy/Paste READY for ISE!" -ForegroundColor Green
