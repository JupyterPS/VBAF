# ===============================
# HQ Show22 — WALL STREET HEARTBEAT
# Commerce Bank: Bulls vs Bears Trading Floor
# ===============================

Write-Host "`n=> _____ HQshow22 (Wall Street Heartbeat) ___________ <=`n" -ForegroundColor Cyan

class Show22 : BaseShow {
    hidden [System.Collections.ArrayList] $MoneyParticles
    hidden [System.Collections.ArrayList] $BullParticles
    hidden [System.Collections.ArrayList] $BearParticles
    hidden [System.Collections.ArrayList] $TradingBars
    hidden [System.Collections.ArrayList] $StockWaves
    hidden [System.Collections.ArrayList] $Explosions
    hidden [hashtable] $State
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    
    Show22([System.Windows.Forms.Panel]$panel) : base("show22", $panel) {
        $this.State = @{
            TickCount = 0
            MarketSentiment = 0.5  # 0=Bear, 1=Bull
            TradingVolume = 50
            HeartbeatPhase = 0
            BullScore = 0
            BearScore = 0
            MarketMode = "Opening"  # Opening, Trading, Surge, Crash, Closing
            ModeTimer = 0
        }
        
        $this.MoneyParticles = [System.Collections.ArrayList]::new()
        $this.BullParticles = [System.Collections.ArrayList]::new()
        $this.BearParticles = [System.Collections.ArrayList]::new()
        $this.TradingBars = [System.Collections.ArrayList]::new()
        $this.StockWaves = [System.Collections.ArrayList]::new()
        $this.Explosions = [System.Collections.ArrayList]::new()
        
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 50
        
        $self = $this
        $this.AnimationTimer.Add_Tick({ $self.OnUpdate() }.GetNewClosure())
    }
    
    [void] OnStart() {
        Write-Host "  📈 [Show22] Wall Street Heartbeat initializing..." -ForegroundColor Green
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 25)
        
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        $this.InitializeTradingBars()
        $this.SetupEvents()
        $this.AnimationTimer.Start()
        
        Write-Host "  ✅ [Show22] Trading floor ready!" -ForegroundColor Green
    }
    
    [void] OnUpdate() {
        $this.State.TickCount++
        $this.State.ModeTimer++
        $this.State.HeartbeatPhase += 0.15
        
        # Market mode transitions
        if ($this.State.ModeTimer -gt 200) {
            $this.State.ModeTimer = 0
            $modes = @("Opening", "Trading", "Surge", "Crash", "Trading", "Closing")
            $currentIndex = $modes.IndexOf($this.State.MarketMode)
            $this.State.MarketMode = $modes[($currentIndex + 1) % $modes.Count]
            Write-Host "  📊 Market Mode: $($this.State.MarketMode)" -ForegroundColor Cyan
        }
        
        # Update based on market mode
        switch ($this.State.MarketMode) {
            "Opening" { $this.UpdateOpening() }
            "Trading" { $this.UpdateTrading() }
            "Surge" { $this.UpdateSurge() }
            "Crash" { $this.UpdateCrash() }
            "Closing" { $this.UpdateClosing() }
        }
        
        # Update all particles
        $this.UpdateMoneyParticles()
        $this.UpdateBullBearParticles()
        $this.UpdateTradingBars()
        $this.UpdateStockWaves()
        $this.UpdateExplosions()
        
        # Update market sentiment
        $bullForce = $this.BullParticles.Count
        $bearForce = $this.BearParticles.Count
        $total = $bullForce + $bearForce
        if ($total -gt 0) {
            $this.State.MarketSentiment = $bullForce / [double]$total
        }
        
        $this.Panel.Invalidate()
    }
    
    [void] OnStop() {
        Write-Host "  🛑 [Show22] Cleanup..." -ForegroundColor Yellow
        
        if ($this.AnimationTimer) { $this.AnimationTimer.Stop() }
        
        $this.MoneyParticles.Clear()
        $this.BullParticles.Clear()
        $this.BearParticles.Clear()
        $this.TradingBars.Clear()
        $this.StockWaves.Clear()
        $this.Explosions.Clear()
        
        Write-Host "  ✅ [Show22] Stopped" -ForegroundColor Green
    }
    
    hidden [void] InitializeTradingBars() {
        $stocks = @("AAPL", "GOOGL", "MSFT", "AMZN", "TSLA", "NVDA", "META", "NFLX")
        
        for ($i = 0; $i -lt $stocks.Count; $i++) {
            [void]$this.TradingBars.Add(@{
                Symbol = $stocks[$i]
                X = 50 + ($i * 90)
                BaseY = 350
                Height = 50 + (Get-Random -Minimum 0 -Maximum 100)
                TargetHeight = 50
                Volume = 50 + (Get-Random -Minimum 0 -Maximum 50)
                Color = $this.GetStockColor()
                Pulse = 0
            })
        }
    }
    
    hidden [void] UpdateOpening() {
        # Market opening - gentle price discovery
        if ($this.State.TickCount % 5 -eq 0) {
            $x = Get-Random -Minimum 100 -Maximum 700
            [void]$this.MoneyParticles.Add(@{
                X = $x; Y = 50
                VX = (Get-Random -Minimum -10 -Maximum 10) / 10.0
                VY = 1 + (Get-Random) * 2
                Size = 3 + (Get-Random -Minimum 0 -Maximum 3)
                Type = "Dollar"
                Life = 100
            })
        }
    }
    
    hidden [void] UpdateTrading() {
        # Normal trading - bulls and bears
        if ($this.State.TickCount % 8 -eq 0) {
            # Spawn bull
            [void]$this.BullParticles.Add(@{
                X = 50; Y = 200 + (Get-Random -Minimum -50 -Maximum 50)
                VX = 2 + (Get-Random) * 2
                VY = (Get-Random -Minimum -5 -Maximum 5) / 10.0
                Size = 8
                Life = 150
            })
        }
        
        if ($this.State.TickCount % 10 -eq 0) {
            # Spawn bear
            [void]$this.BearParticles.Add(@{
                X = 750; Y = 200 + (Get-Random -Minimum -50 -Maximum 50)
                VX = -2 - (Get-Random) * 2
                VY = (Get-Random -Minimum -5 -Maximum 5) / 10.0
                Size = 8
                Life = 150
            })
        }
        
        # Money flow
        if ($this.State.TickCount % 3 -eq 0) {
            $x = Get-Random -Minimum 100 -Maximum 700
            [void]$this.MoneyParticles.Add(@{
                X = $x; Y = 100
                VX = (Get-Random -Minimum -20 -Maximum 20) / 10.0
                VY = 2 + (Get-Random) * 1
                Size = 2 + (Get-Random -Minimum 0 -Maximum 2)
                Type = "Dollar"
                Life = 80
            })
        }
    }
    
    hidden [void] UpdateSurge() {
        # Bull surge - market going up!
        if ($this.State.TickCount % 3 -eq 0) {
            [void]$this.BullParticles.Add(@{
                X = Get-Random -Minimum 0 -Maximum 100
                Y = 200 + (Get-Random -Minimum -80 -Maximum 80)
                VX = 3 + (Get-Random) * 3
                VY = (Get-Random -Minimum -10 -Maximum 10) / 10.0
                Size = 10
                Life = 120
            })
        }
        
        # Stock wave going up
        if ($this.State.TickCount % 20 -eq 0) {
            [void]$this.StockWaves.Add(@{
                X = 0; Y = 250; Direction = 1
                Amplitude = 30; Wavelength = 100
                Speed = 5; Life = 100
            })
        }
        
        # Money explosion
        if ($this.State.TickCount % 15 -eq 0) {
            $x = Get-Random -Minimum 200 -Maximum 600
            $y = Get-Random -Minimum 150 -Maximum 300
            
            for ($i = 0; $i -lt 15; $i++) {
                $angle = (Get-Random) * [Math]::PI * 2
                $speed = 2 + (Get-Random) * 3
                
                [void]$this.MoneyParticles.Add(@{
                    X = $x; Y = $y
                    VX = [Math]::Cos($angle) * $speed
                    VY = [Math]::Sin($angle) * $speed
                    Size = 3 + (Get-Random -Minimum 0 -Maximum 3)
                    Type = "Dollar"
                    Life = 60
                })
            }
        }
    }
    
    hidden [void] UpdateCrash() {
        # Market crash - bears dominate
        if ($this.State.TickCount % 3 -eq 0) {
            [void]$this.BearParticles.Add(@{
                X = Get-Random -Minimum 700 -Maximum 800
                Y = 200 + (Get-Random -Minimum -80 -Maximum 80)
                VX = -3 - (Get-Random) * 3
                VY = (Get-Random -Minimum -10 -Maximum 10) / 10.0
                Size = 10
                Life = 120
            })
        }
        
        # Stock wave going down
        if ($this.State.TickCount % 20 -eq 0) {
            [void]$this.StockWaves.Add(@{
                X = 800; Y = 250; Direction = -1
                Amplitude = 30; Wavelength = 100
                Speed = 5; Life = 100
            })
        }
        
        # Red explosions
        if ($this.State.TickCount % 25 -eq 0) {
            $x = Get-Random -Minimum 200 -Maximum 600
            $y = Get-Random -Minimum 150 -Maximum 300
            
            [void]$this.Explosions.Add(@{
                X = $x; Y = $y
                Size = 20; MaxSize = 80
                Life = 30; Type = "Crash"
            })
        }
    }
    
    hidden [void] UpdateClosing() {
        # Market closing - settling
        foreach ($bar in $this.TradingBars) {
            $bar.Pulse += 0.1
        }
        
        if ($this.State.TickCount % 10 -eq 0) {
            $x = Get-Random -Minimum 100 -Maximum 700
            [void]$this.MoneyParticles.Add(@{
                X = $x; Y = 400
                VX = (Get-Random -Minimum -5 -Maximum 5) / 10.0
                VY = -1 - (Get-Random) * 1
                Size = 2
                Type = "Dollar"
                Life = 50
            })
        }
    }
    
    hidden [void] UpdateMoneyParticles() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($p in $this.MoneyParticles) {
            $p.X += $p.VX
            $p.Y += $p.VY
            $p.VY += 0.1  # Gravity
            $p.Life -= 1
            
            if ($p.Life -le 0 -or $p.Y -gt 500 -or $p.X -lt 0 -or $p.X -gt 800) {
                [void]$toRemove.Add($p)
            }
        }
        
        foreach ($p in $toRemove) { [void]$this.MoneyParticles.Remove($p) }
    }
    
    hidden [void] UpdateBullBearParticles() {
        # Update bulls
        $toRemove = [System.Collections.ArrayList]::new()
        foreach ($bull in $this.BullParticles) {
            $bull.X += $bull.VX
            $bull.Y += $bull.VY
            $bull.Life -= 1
            
            if ($bull.Life -le 0 -or $bull.X -gt 800) {
                [void]$toRemove.Add($bull)
                $this.State.BullScore += 1
            }
        }
        foreach ($b in $toRemove) { [void]$this.BullParticles.Remove($b) }
        
        # Update bears
        $toRemove.Clear()
        foreach ($bear in $this.BearParticles) {
            $bear.X += $bear.VX
            $bear.Y += $bear.VY
            $bear.Life -= 1
            
            if ($bear.Life -le 0 -or $bear.X -lt 0) {
                [void]$toRemove.Add($bear)
                $this.State.BearScore += 1
            }
        }
        foreach ($b in $toRemove) { [void]$this.BearParticles.Remove($b) }
        
        # Bull-Bear collisions
        foreach ($bull in $this.BullParticles) {
            foreach ($bear in $this.BearParticles) {
                $dx = $bull.X - $bear.X
                $dy = $bull.Y - $bear.Y
                $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
                
                if ($dist -lt 15) {
                    # Collision! Create explosion
                    [void]$this.Explosions.Add(@{
                        X = ($bull.X + $bear.X) / 2
                        Y = ($bull.Y + $bear.Y) / 2
                        Size = 10; MaxSize = 40
                        Life = 20; Type = "Collision"
                    })
                    
                    [void]$toRemove.Add($bull)
                    [void]$toRemove.Add($bear)
                    break
                }
            }
        }
    }
    
    hidden [void] UpdateTradingBars() {
        foreach ($bar in $this.TradingBars) {
            # Random price movement
            if ($this.State.TickCount % 20 -eq 0) {
                $change = (Get-Random -Minimum -30 -Maximum 30)
                $bar.TargetHeight = [Math]::Max(20, [Math]::Min(150, $bar.Height + $change))
            }
            
            # Smooth transition
            $bar.Height += ($bar.TargetHeight - $bar.Height) * 0.1
            
            # Pulse effect
            $bar.Pulse = [Math]::Abs([Math]::Sin($this.State.HeartbeatPhase + $bar.X * 0.01)) * 10
        }
    }
    
    hidden [void] UpdateStockWaves() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($wave in $this.StockWaves) {
            $wave.X += $wave.Speed * $wave.Direction
            $wave.Life -= 1
            
            if ($wave.Life -le 0 -or $wave.X -lt -200 -or $wave.X -gt 1000) {
                [void]$toRemove.Add($wave)
            }
        }
        
        foreach ($w in $toRemove) { [void]$this.StockWaves.Remove($w) }
    }
    
    hidden [void] UpdateExplosions() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($exp in $this.Explosions) {
            $exp.Size += ($exp.MaxSize - $exp.Size) * 0.2
            $exp.Life -= 1
            
            if ($exp.Life -le 0) { [void]$toRemove.Add($exp) }
        }
        
        foreach ($e in $toRemove) { [void]$this.Explosions.Remove($e) }
    }
    
    hidden [System.Drawing.Color] GetStockColor() {
        $sentiment = $this.State.MarketSentiment
        $r = [int](255 * (1 - $sentiment))
        $g = [int](255 * $sentiment)
        return [System.Drawing.Color]::FromArgb($r, $g, 50)
    }
    
    hidden [void] SetupEvents() {
        $self = $this
        
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderWallStreet($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
        
        $this.Panel.Add_MouseClick({
            param($sender, $e)
            
            # Market surge on click!
            for ($i = 0; $i -lt 20; $i++) {
                $angle = (Get-Random) * [Math]::PI * 2
                $speed = 3 + (Get-Random) * 4
                
                [void]$self.MoneyParticles.Add(@{
                    X = $e.X; Y = $e.Y
                    VX = [Math]::Cos($angle) * $speed
                    VY = [Math]::Sin($angle) * $speed
                    Size = 4 + (Get-Random -Minimum 0 -Maximum 4)
                    Type = "Dollar"
                    Life = 80
                })
            }
            
            # Add bull surge
            for ($i = 0; $i -lt 5; $i++) {
                [void]$self.BullParticles.Add(@{
                    X = $e.X - 50
                    Y = $e.Y + (Get-Random -Minimum -20 -Maximum 20)
                    VX = 4 + (Get-Random) * 2
                    VY = (Get-Random -Minimum -10 -Maximum 10) / 10.0
                    Size = 12
                    Life = 100
                })
            }
            
            Write-Host "  💰 Market surge triggered at ($($e.X), $($e.Y))!" -ForegroundColor Green
        }.GetNewClosure())
    }
    
    hidden [void] RenderWallStreet([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Dark gradient background
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(10, 15, 25), [System.Drawing.Color]::FromArgb(20, 25, 35)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Grid lines
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 100, 150, 200), 1)
        for ($y = 0; $y -lt $height; $y += 50) {
            $g.DrawLine($gridPen, 0, $y, $width, $y)
        }
        $gridPen.Dispose()
        
        # Draw stock waves
        foreach ($wave in $this.StockWaves) {
            $waveColor = if ($wave.Direction -gt 0) {
                [System.Drawing.Color]::FromArgb(150, 100, 255, 100)
            } else {
                [System.Drawing.Color]::FromArgb(150, 255, 100, 100)
            }
            $wavePen = New-Object System.Drawing.Pen($waveColor, 3)
            
            for ($i = 0; $i -lt 10; $i++) {
                $x1 = $wave.X + ($i * $wave.Wavelength / 10)
                $x2 = $wave.X + (($i + 1) * $wave.Wavelength / 10)
                $y1 = $wave.Y + $wave.Amplitude * [Math]::Sin($i * 0.628)
                $y2 = $wave.Y + $wave.Amplitude * [Math]::Sin(($i + 1) * 0.628)
                
                $g.DrawLine($wavePen, $x1, $y1, $x2, $y2)
            }
            $wavePen.Dispose()
        }
        
        # Draw trading bars
        foreach ($bar in $this.TradingBars) {
            $barColor = $bar.Color
            $barBrush = New-Object System.Drawing.SolidBrush($barColor)
            
            $barWidth = 60
            $barHeight = $bar.Height + $bar.Pulse
            $barY = $bar.BaseY - $barHeight
            
            $g.FillRectangle($barBrush, $bar.X, $barY, $barWidth, $barHeight)
            $barBrush.Dispose()
            
            # Symbol label
            $labelFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString($bar.Symbol, $labelFont, $labelBrush, $bar.X + 10, $bar.BaseY + 5)
            $labelFont.Dispose()
            $labelBrush.Dispose()
        }
        
        # Draw explosions
        foreach ($exp in $this.Explosions) {
            $expColor = if ($exp.Type -eq "Crash") {
                [System.Drawing.Color]::FromArgb(150, 255, 50, 50)
            } else {
                [System.Drawing.Color]::FromArgb(150, 255, 200, 50)
            }
            $expBrush = New-Object System.Drawing.SolidBrush($expColor)
            $g.FillEllipse($expBrush, $exp.X - $exp.Size/2, $exp.Y - $exp.Size/2, $exp.Size, $exp.Size)
            $expBrush.Dispose()
        }
        
        # Draw money particles
        foreach ($p in $this.MoneyParticles) {
            $alpha = [int](($p.Life / 100.0) * 200)
            $moneyColor = [System.Drawing.Color]::FromArgb($alpha, 100, 220, 100)
            $moneyBrush = New-Object System.Drawing.SolidBrush($moneyColor)
            $g.FillEllipse($moneyBrush, $p.X - $p.Size/2, $p.Y - $p.Size/2, $p.Size, $p.Size)
            $moneyBrush.Dispose()
            
            # Dollar sign
            if ($p.Size -gt 3) {
                $dollarFont = New-Object System.Drawing.Font("Arial", 6, [System.Drawing.FontStyle]::Bold)
                $dollarBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $g.DrawString("$", $dollarFont, $dollarBrush, $p.X - 3, $p.Y - 4)
                $dollarFont.Dispose()
                $dollarBrush.Dispose()
            }
        }
        
        # Draw bulls (green arrows up)
        foreach ($bull in $this.BullParticles) {
            $bullBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 255, 100))
            $points = @(
                [System.Drawing.Point]::new($bull.X, $bull.Y - $bull.Size),
                [System.Drawing.Point]::new($bull.X - $bull.Size/2, $bull.Y + $bull.Size/2),
                [System.Drawing.Point]::new($bull.X + $bull.Size/2, $bull.Y + $bull.Size/2)
            )
            $g.FillPolygon($bullBrush, $points)
            $bullBrush.Dispose()
        }
        
        # Draw bears (red arrows down)
        foreach ($bear in $this.BearParticles) {
            $bearBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 100, 100))
            $points = @(
                [System.Drawing.Point]::new($bear.X, $bear.Y + $bear.Size),
                [System.Drawing.Point]::new($bear.X - $bear.Size/2, $bear.Y - $bear.Size/2),
                [System.Drawing.Point]::new($bear.X + $bear.Size/2, $bear.Y - $bear.Size/2)
            )
            $g.FillPolygon($bearBrush, $points)
            $bearBrush.Dispose()
        }
        
        # Title and stats
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 200, 200, 255))
        $g.DrawString("✨ WALL STREET HEARTBEAT", $titleFont, $titleBrush, 20, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Mode indicator
        $modeFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $modeColor = [System.Drawing.Color]::Cyan
        if ($this.State.MarketMode -eq "Surge") { $modeColor = [System.Drawing.Color]::Lime }
        elseif ($this.State.MarketMode -eq "Crash") { $modeColor = [System.Drawing.Color]::Red }
        
        $modeBrush = New-Object System.Drawing.SolidBrush($modeColor)
        $g.DrawString("Market: $($this.State.MarketMode)", $modeFont, $modeBrush, 20, 55)
        $modeFont.Dispose()
        $modeBrush.Dispose()
        
        # Sentiment meter
        $sentimentX = $width - 200
        $sentimentY = 30
        $sentimentWidth = 150
        $sentimentHeight = 20
        
        $meterBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 50, 50, 50))
        $g.FillRectangle($meterBg, $sentimentX, $sentimentY, $sentimentWidth, $sentimentHeight)
        $meterBg.Dispose()
        
        $sentiment = $this.State.MarketSentiment
        $meterFill = $sentimentWidth * $sentiment
        $meterColor = [System.Drawing.Color]::FromArgb(200, [int](255 * (1 - $sentiment)), [int](255 * $sentiment), 50)
        $meterBrush = New-Object System.Drawing.SolidBrush($meterColor)
        $g.FillRectangle($meterBrush, $sentimentX, $sentimentY, $meterFill, $sentimentHeight)
        $meterBrush.Dispose()
        
        # Labels
        $labelFont = New-Object System.Drawing.Font("Segoe UI", 8)
        $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("BEAR", $labelFont, $labelBrush, $sentimentX - 40, $sentimentY + 3)
        $g.DrawString("BULL", $labelFont, $labelBrush, $sentimentX + $sentimentWidth + 5, $sentimentY + 3)
        $labelFont.Dispose()
        $labelBrush.Dispose()
        
        # Instructions
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 9)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 200, 200, 200))
        $g.DrawString("Click anywhere to trigger a MARKET SURGE! 💰", $infoFont, $infoBrush, 20, $height - 30)
        $infoFont.Dispose()
        $infoBrush.Dispose()
    }
}

function Stop-Show22 {
    Write-Host "[Show22] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show22")) {
        $Global:ShowManager.Shows["show22"].Stop()
    }
}

Write-Host "✅ Show22 - Wall Street Heartbeat loaded!" -ForegroundColor Green
Write-Host "💰 Bulls vs Bears with explosive trading action!" -ForegroundColor Cyan