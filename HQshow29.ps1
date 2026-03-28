# ====================================================
# HQshow29.ps1 — Trading Floor FRENZY v3 (COMPLETE FIXED)
# Commerce Bank: Live Market Activity - 100% WORKING
# ====================================================

# ============================================
# Show29 - Inherits from BaseShow (FULLY FIXED)
# ============================================
class Show29 : BaseShow {
    hidden [System.Collections.ArrayList] $Stocks = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $Orders = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $PriceCandles = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $NewsFlashes = [System.Collections.ArrayList]::new()
    hidden [hashtable] $State = @{
        TickerPosition = 0
        TickCount = 0
        BullScore = 50.0
        BearScore = 50.0
        Volatility = 0.0
    }
    hidden [System.Windows.Forms.Panel] $Canvas

    Show29([System.Windows.Forms.Panel]$panel) : base("show29", $panel) {}

    [void] OnStart() {
        Write-Host " 📈 [Show29] Initializing Trading Floor Frenzy..." -ForegroundColor Green
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::Black
        
        $Show29Messages = @(
            "📈 TRADING FLOOR FRENZY - Live Market Action!",
            "💹 Watch buy/sell orders collide in real-time",
            "🐂🐻 Bull vs Bear battle for market control",
            "📊 Commerce Bank Trading - Where Money Moves Fast"
        )
        $global:messages = $Show29Messages
        Update-Ticker
        
        $this.Canvas = New-Object System.Windows.Forms.Panel
        $this.Canvas.Dock = "Fill"
        $this.Canvas.BackColor = [System.Drawing.Color]::Black
        $prop = $this.Canvas.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Canvas, $true, $null) }
        $this.Panel.Controls.Add($this.Canvas)
        
        $this.InitializeMarketData()
        $this.SetupPaintEvent()
        
        Write-Host " ✅ [Show29] Trading Floor ready" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        # Scroll ticker
        $this.State.TickerPosition -= 2
        if ($this.State.TickerPosition -lt -800) {
            $this.State.TickerPosition = 0
        }
        
        # Update stock prices
        if ($tick % 20 -eq 0) {
            foreach ($stock in $this.Stocks) {
                $oldPrice = $stock.Price
                $change = (Get-Random -Minimum -10 -Maximum 10) / 2.0
                $stock.Price = [math]::Max(10, $stock.Price + $change)
                $stock.Change = $stock.Price - $oldPrice
                $stock.ChangePercent = ($stock.Change / $oldPrice) * 100
                
                $stock.High = [math]::Max($stock.High, $stock.Price)
                $stock.Low = [math]::Min($stock.Low, $stock.Price)
                $stock.Trend = if ($stock.Change -gt 0) { "Up" } elseif ($stock.Change -lt 0) { "Down" } else { "Neutral" }
            }
        }
        
        # Update price candles
        if ($tick % 30 -eq 0) {
            foreach ($candle in $this.PriceCandles) {
                $candle.X -= 15
            }
            
            $toRemove = [System.Collections.ArrayList]::new()
            for ($i = 0; $i -lt $this.PriceCandles.Count; $i++) {
                if ($this.PriceCandles[$i].X -lt 0) {
                    [void]$toRemove.Add($i)
                }
            }
            for ($i = $toRemove.Count - 1; $i -ge 0; $i--) {
                $this.PriceCandles.RemoveAt($toRemove[$i])
            }
            
            if ($this.PriceCandles.Count -gt 0) {
                $lastCandle = $this.PriceCandles[-1]
                $newOpen = $lastCandle.Close
                $newClose = $newOpen + (Get-Random -Minimum -20 -Maximum 20)
                
                [void]$this.PriceCandles.Add(@{
                    X = 500
                    Open = $newOpen
                    Close = $newClose
                    High = [math]::Max($newOpen, $newClose) + (Get-Random -Minimum 5 -Maximum 15)
                    Low = [math]::Min($newOpen, $newClose) - (Get-Random -Minimum 5 -Maximum 15)
                    Color = if ($newClose -gt $newOpen) { [System.Drawing.Color]::LimeGreen } else { [System.Drawing.Color]::Red }
                })
            }
        }
        
        # Spawn buy/sell orders
        if ($tick % 10 -eq 0) {
            $orderType = if ((Get-Random -Minimum 0 -Maximum 2) -eq 0) { "Buy" } else { "Sell" }
            
            [void]$this.Orders.Add(@{
                X = Get-Random -Minimum 50 -Maximum 550
                Y = Get-Random -Minimum 80 -Maximum 220
                VX = (Get-Random -Minimum -3 -Maximum 3)
                VY = (Get-Random -Minimum -2 -Maximum 2)
                Size = Get-Random -Minimum 5 -Maximum 10
                Life = 100
                Type = $orderType
            })
            
            if ($orderType -eq "Buy") {
                $this.State.BullScore = [math]::Min(100, $this.State.BullScore + 2)
                $this.State.BearScore = [math]::Max(0, $this.State.BearScore - 1)
            } else {
                $this.State.BearScore = [math]::Min(100, $this.State.BearScore + 2)
                $this.State.BullScore = [math]::Max(0, $this.State.BullScore - 1)
            }
        }
        
        # Update orders
        $toRemove = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $this.Orders.Count; $i++) {
            $order = $this.Orders[$i]
            $order.X += $order.VX
            $order.Y += $order.VY
            $order.Life -= 1
            
            if ($order.Life -le 0) {
                [void]$toRemove.Add($i)
            }
        }
        for ($i = $toRemove.Count - 1; $i -ge 0; $i--) {
            $this.Orders.RemoveAt($toRemove[$i])
        }
        
        while ($this.Orders.Count -gt 80) {
            $this.Orders.RemoveAt(0)
        }
        
        # Update volatility
        $avgChange = 0
        if ($this.Stocks.Count -gt 0) {
            foreach ($stock in $this.Stocks) {
                $avgChange += [math]::Abs($stock.ChangePercent)
            }
            $avgChange = $avgChange / $this.Stocks.Count
            $this.State.Volatility = [math]::Min(100, $avgChange * 10)
        }
        
        # News flashes
        if ($tick % 100 -eq 0) {
            $newsItems = @(
                "Market rallies on strong earnings!",
                "Breaking: Major merger announced!",
                "Fed signals rate change ahead",
                "Tech stocks surge to new highs!",
                "Warning: Volatility spike detected!"
            )
            [void]$this.NewsFlashes.Add(@{
                Text = $newsItems | Get-Random
                Life = 50
            })
        }
        
        foreach ($news in $this.NewsFlashes) {
            $news.Life -= 1
        }
        $toRemoveNews = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $this.NewsFlashes.Count; $i++) {
            if ($this.NewsFlashes[$i].Life -le 0) {
                [void]$toRemoveNews.Add($i)
            }
        }
        for ($i = $toRemoveNews.Count - 1; $i -ge 0; $i--) {
            $this.NewsFlashes.RemoveAt($toRemoveNews[$i])
        }
        
        $this.Canvas.Invalidate()
    }

    [void] OnStop() {
        Write-Host " 🛑 [Show29] Cleaning up Trading Floor..." -ForegroundColor Yellow
        
        $this.Stocks.Clear()
        $this.Orders.Clear()
        $this.PriceCandles.Clear()
        $this.NewsFlashes.Clear()
        
        if ($this.Canvas) {
            $this.Canvas.Remove_Paint($null)
            $this.Canvas.Dispose()
            $this.Canvas = $null
        }
        $this.Panel.Controls.Clear()
        
        $this.State.TickerPosition = 0
        $this.State.TickCount = 0
        $this.State.BullScore = 50.0
        $this.State.BearScore = 50.0
        $this.State.Volatility = 0.0
        
        Write-Host " ✅ [Show29] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Canvas.Add_Paint({
            param($sender, $e)
            $self.RenderFrame($e.Graphics, $sender.Width, $sender.Height)
        }.GetNewClosure())
    }

    hidden [void] InitializeMarketData() {
        $this.Stocks.Clear()
        $stockSymbols = @("CMRC", "TECH", "FINX", "ENRG", "HLTH", "AUTO", "RETL", "INDX")
        
        foreach ($symbol in $stockSymbols) {
            [void]$this.Stocks.Add(@{
                Symbol = $symbol
                Price = [double](Get-Random -Minimum 50 -Maximum 500)
                Change = 0.0
                ChangePercent = 0.0
                Volume = [int](Get-Random -Minimum 1000 -Maximum 9999)
                High = 0.0
                Low = 9999.0
                Trend = "Neutral"
                Color = [System.Drawing.Color]::White
            })
        }
        
        foreach ($stock in $this.Stocks) {
            $stock.High = $stock.Price
            $stock.Low = $stock.Price
        }
        
        $this.PriceCandles.Clear()
        for ($i = 0; $i -lt 30; $i++) {
            [void]$this.PriceCandles.Add(@{
                X = 50 + ($i * 15)
                Open = [double](Get-Random -Minimum 100 -Maximum 200)
                Close = [double](Get-Random -Minimum 100 -Maximum 200)
                High = 0.0
                Low = 0.0
                Color = [System.Drawing.Color]::Green
            })
        }
        
        foreach ($candle in $this.PriceCandles) {
            $candle.High = [math]::Max($candle.Open, $candle.Close) + (Get-Random -Minimum 5 -Maximum 20)
            $candle.Low = [math]::Min($candle.Open, $candle.Close) - (Get-Random -Minimum 5 -Maximum 20)
            $candle.Color = if ($candle.Close -gt $candle.Open) { 
                [System.Drawing.Color]::LimeGreen 
            } else { 
                [System.Drawing.Color]::Red 
            }
        }
    }

    hidden [void] RenderFrame([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Ticker tape
        $tickerBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 30, 30))
        $g.FillRectangle($tickerBg, 0, 0, $width, 40)
        $tickerBg.Dispose()
        
        $tickerFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $xPos = $this.State.TickerPosition
        
        foreach ($stock in $this.Stocks) {
            $priceText = [math]::Round($stock.Price, 2)
            $changeTextValue = [math]::Round($stock.Change, 2)
            $text = "$($stock.Symbol) `$$priceText "
            $changeText = if ($stock.Change -ge 0) { "+$changeTextValue" } else { "$changeTextValue" }
            
            $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString($text, $tickerFont, $textBrush, $xPos, 12)
            $textSize = $g.MeasureString($text, $tickerFont)
            $textBrush.Dispose()
            
            $changeColor = if ($stock.Change -ge 0) { [System.Drawing.Color]::LimeGreen } else { [System.Drawing.Color]::Red }
            $changeBrush = New-Object System.Drawing.SolidBrush($changeColor)
            $g.DrawString($changeText, $tickerFont, $changeBrush, $xPos + $textSize.Width, 12)
            $changeSize = $g.MeasureString($changeText, $tickerFont)
            $changeBrush.Dispose()
            
            $xPos += $textSize.Width + $changeSize.Width + 40
        }
        $tickerFont.Dispose()
        
        # Price chart
        $chartY = 60
        $chartHeight = 180
        
        $chartBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 15, 15))
        $g.FillRectangle($chartBg, 0, $chartY, $width, $chartHeight)
        $chartBg.Dispose()
        
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 40, 40), 1)
        for ($i = 0; $i -le 5; $i++) {
            $y = $chartY + ($i * $chartHeight / 5)
            $g.DrawLine($gridPen, 0, $y, $width, $y)
        }
        $gridPen.Dispose()
        
        foreach ($candle in $this.PriceCandles) {
            if ($candle.X -gt 0 -and $candle.X -lt $width) {
                $priceRange = 150
                $priceBase = 50
                
                $openY = $chartY + $chartHeight - (($candle.Open - $priceBase) / $priceRange * $chartHeight)
                $closeY = $chartY + $chartHeight - (($candle.Close - $priceBase) / $priceRange * $chartHeight)
                $highY = $chartY + $chartHeight - (($candle.High - $priceBase) / $priceRange * $chartHeight)
                $lowY = $chartY + $chartHeight - (($candle.Low - $priceBase) / $priceRange * $chartHeight)
                
                $wickPen = New-Object System.Drawing.Pen($candle.Color, 1)
                $g.DrawLine($wickPen, $candle.X, $highY, $candle.X, $lowY)
                $wickPen.Dispose()
                
                $bodyHeight = [math]::Abs($closeY - $openY)
                if ($bodyHeight -lt 2) { $bodyHeight = 2 }
                $bodyY = [math]::Min($openY, $closeY)
                
                $bodyBrush = New-Object System.Drawing.SolidBrush($candle.Color)
                $g.FillRectangle($bodyBrush, $candle.X - 4, $bodyY, 8, $bodyHeight)
                $bodyBrush.Dispose()
            }
        }
        
        # Buy/sell orders (particles)
        foreach ($order in $this.Orders) {
            $alpha = [math]::Min(255, $order.Life * 3)
            $size = $order.Size
            
            $glowColor = if ($order.Type -eq "Buy") { 
                [System.Drawing.Color]::FromArgb([int]($alpha/4), 0, 255, 0)
            } else { 
                [System.Drawing.Color]::FromArgb([int]($alpha/4), 255, 0, 0)
            }
            $glowBrush = New-Object System.Drawing.SolidBrush($glowColor)
            $g.FillEllipse($glowBrush, $order.X - $size*1.5, $order.Y - $size*1.5, $size*3, $size*3)
            $glowBrush.Dispose()
            
            $orderColor = if ($order.Type -eq "Buy") { 
                [System.Drawing.Color]::FromArgb($alpha, 0, 255, 0)
            } else { 
                [System.Drawing.Color]::FromArgb($alpha, 255, 0, 0)
            }
            $orderBrush = New-Object System.Drawing.SolidBrush($orderColor)
            $g.FillEllipse($orderBrush, $order.X - $size, $order.Y - $size, $size*2, $size*2)
            $orderBrush.Dispose()
        }
        
# Bull vs Bear battle (bottom)
        $battleY = 260
        $battleBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 20, 20))
        $g.FillRectangle($battleBg, 0, $battleY, $width, 80)
        $battleBg.Dispose()
        
        $barY = $battleY + 20
        $barHeight = 30
        $maxWidth = $width - 200
        
        $bullWidth = ($this.State.BullScore / 100.0) * $maxWidth
        $bearWidth = ($this.State.BearScore / 100.0) * $maxWidth
        
        $bullBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 0, 200, 0))
        $g.FillRectangle($bullBrush, 100, $barY, $bullWidth, $barHeight)
        $bullBrush.Dispose()
        
        $bearBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 200, 0, 0))
        $g.FillRectangle($bearBrush, 100, $barY + $barHeight + 5, $bearWidth, $barHeight)
        $bearBrush.Dispose()
        
        $labelFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $bullBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::LimeGreen)
        $g.DrawString("✨ BULL: $($this.State.BullScore)%", $labelFont, $bullBrush2, 8, $barY + 5)
        $bullBrush2.Dispose()
        
        $bearBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
        $g.DrawString("✨ BEAR: $($this.State.BearScore)%", $labelFont, $bearBrush2, 8, $barY + $barHeight + 8)
        $bearBrush2.Dispose()
        $labelFont.Dispose()
        
        # Volatility meter
        $volY = $battleY + 20
        $volX = $width - 150
        
        $volFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $volColor = if ($this.State.Volatility -gt 70) { 
            [System.Drawing.Color]::Red 
        } elseif ($this.State.Volatility -gt 40) { 
            [System.Drawing.Color]::Yellow 
        } else { 
            [System.Drawing.Color]::LimeGreen 
        }
        
        $volBrush = New-Object System.Drawing.SolidBrush($volColor)
        $g.DrawString("VOLATILITY", $volFont, $volBrush, $volX, $volY)
        $g.DrawString("$([math]::Round($this.State.Volatility))%", $volFont, $volBrush, $volX + 10, $volY + 25)
        $volBrush.Dispose()
        $volFont.Dispose()
        
        # News flashes
        $newsY = 350
        $newsFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        foreach ($news in $this.NewsFlashes) {
            if ($news.Life -gt 0) {
                $alpha = [math]::Min(255, $news.Life * 5)
                $newsColor = [System.Drawing.Color]::FromArgb($alpha, 255, 255, 0)
                $newsBrush = New-Object System.Drawing.SolidBrush($newsColor)
                $g.DrawString("⚡ $($news.Text)", $newsFont, $newsBrush, 20, $newsY)
                $newsBrush.Dispose()
                $newsY += 20
            }
        }
        $newsFont.Dispose()
        
        # Info
        $infoFont = New-Object System.Drawing.Font("Consolas", 8)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 200, 200, 200))
        $market = if ($this.State.BullScore -gt $this.State.BearScore) { "BULLISH" } else { "BEARISH" }
        $info = "Orders: $($this.Orders.Count) | Market: $market"
        $g.DrawString($info, $infoFont, $infoBrush, 10, $height - 25)
        $infoFont.Dispose()
        $infoBrush.Dispose()
    }
}

# Legacy compatibility
function Stop-Show29 {
    Write-Host "🛑 [Show29] Stop called (v3)" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show29")) {
        $Global:ShowManager.Shows["show29"].Stop()
    }
}

Write-Host "✅ COMPLETE Show29 v3 - Copy/Paste READY for ISE!" -ForegroundColor Green

