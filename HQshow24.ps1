# ===============================
# HQ Show24 — MARKET CONSTELLATION
# Commerce Bank: 3D Stock Universe
# ===============================

Write-Host "`n=> _____ HQshow24 (Market Constellation) ___________ <=`n" -ForegroundColor Cyan

class Show24 : BaseShow {
    hidden [System.Collections.ArrayList] $Stocks
    hidden [System.Collections.ArrayList] $ShootingStars
    hidden [System.Collections.ArrayList] $Connections
    hidden [System.Collections.ArrayList] $BlackHoles
    hidden [System.Collections.ArrayList] $Nebulas
    hidden [hashtable] $State
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    
    Show24([System.Windows.Forms.Panel]$panel) : base("show24", $panel) {
        $this.State = @{
            TickCount = 0
            RotationAngle = 0
            SelectedStock = $null
            UniverseExpansion = 1.0
            TimeOfDay = "Trading"  # Trading, AfterHours, PreMarket
        }
        
        $this.Stocks = [System.Collections.ArrayList]::new()
        $this.ShootingStars = [System.Collections.ArrayList]::new()
        $this.Connections = [System.Collections.ArrayList]::new()
        $this.BlackHoles = [System.Collections.ArrayList]::new()
        $this.Nebulas = [System.Collections.ArrayList]::new()
        
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 50
        
        $self = $this
        $this.AnimationTimer.Add_Tick({ $self.OnUpdate() }.GetNewClosure())
    }
    
    [void] OnStart() {
        Write-Host "  🌌 [Show24] Market Constellation initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::Black
        
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        $this.InitializeStockUniverse()
        $this.SetupEvents()
        $this.AnimationTimer.Start()
        
        Write-Host "  ✅ [Show24] Stock universe ready with $($this.Stocks.Count) celestial bodies!" -ForegroundColor Green
    }
    
    [void] OnUpdate() {
        $this.State.TickCount++
        $this.State.RotationAngle += 0.01
        
        # Universe expansion/contraction
        $this.State.UniverseExpansion = 1.0 + ([Math]::Sin($this.State.TickCount * 0.02) * 0.2)
        
        # Update stocks orbiting
        foreach ($stock in $this.Stocks) {
            $stock.OrbitAngle += $stock.OrbitSpeed
            if ($stock.OrbitAngle -gt 6.28) { $stock.OrbitAngle -= 6.28 }
            
            # Calculate 3D position
            $angle = $stock.OrbitAngle
            $radius = $stock.OrbitRadius * $this.State.UniverseExpansion
            
            $stock.X = 400 + ($radius * [Math]::Cos($angle))
            $stock.Y = 250 + ($radius * [Math]::Sin($angle) * 0.5)  # Perspective
            $stock.Z = $radius * [Math]::Sin($angle)
            
            # Pulse based on "volatility"
            $stock.Pulse = [Math]::Abs([Math]::Sin($this.State.TickCount * 0.1 + $stock.OrbitAngle))
            
            # Update price (random walk)
            if ($this.State.TickCount % 30 -eq 0) {
                $change = (Get-Random -Minimum -5 -Maximum 5)
                $stock.Price += $change
                $stock.Price = [Math]::Max(50, [Math]::Min(500, $stock.Price))
                
                # Hot stock becomes shooting star
                if ($change -gt 3 -and (Get-Random) -lt 0.3) {
                    $this.CreateShootingStar($stock)
                }
                
                # Crashing stock creates black hole
                if ($change -lt -3 -and (Get-Random) -lt 0.2) {
                    $this.CreateBlackHole($stock)
                }
            }
        }
        
        # Update shooting stars
        $this.UpdateShootingStars()
        
        # Update black holes
        $this.UpdateBlackHoles()
        
        # Update connections (correlations)
        $this.UpdateConnections()
        
        # Spawn nebulas (sector groupings)
        if ($this.State.TickCount % 100 -eq 0) {
            $this.CreateNebula()
        }
        $this.UpdateNebulas()
        
        $this.Panel.Invalidate()
    }
    
    [void] OnStop() {
        Write-Host "  🛑 [Show24] Cleanup..." -ForegroundColor Yellow
        
        if ($this.AnimationTimer) { $this.AnimationTimer.Stop() }
        
        $this.Stocks.Clear()
        $this.ShootingStars.Clear()
        $this.Connections.Clear()
        $this.BlackHoles.Clear()
        $this.Nebulas.Clear()
        
        Write-Host "  ✅ [Show24] Stopped" -ForegroundColor Green
    }
    
    hidden [void] InitializeStockUniverse() {
        $stockData = @(
            @{Symbol="AAPL"; Name="Apple"; Sector="Tech"; Cap=3000; Price=180},
            @{Symbol="MSFT"; Name="Microsoft"; Sector="Tech"; Cap=2800; Price=380},
            @{Symbol="GOOGL"; Name="Google"; Sector="Tech"; Cap=1800; Price=140},
            @{Symbol="AMZN"; Name="Amazon"; Sector="Tech"; Cap=1600; Price=150},
            @{Symbol="NVDA"; Name="Nvidia"; Sector="Tech"; Cap=1200; Price=480},
            @{Symbol="TSLA"; Name="Tesla"; Sector="Auto"; Cap=800; Price=250},
            @{Symbol="META"; Name="Meta"; Sector="Tech"; Cap=900; Price=350},
            @{Symbol="JPM"; Name="JP Morgan"; Sector="Finance"; Cap=500; Price=160},
            @{Symbol="BAC"; Name="Bank of America"; Sector="Finance"; Cap=300; Price=35},
            @{Symbol="WFC"; Name="Wells Fargo"; Sector="Finance"; Cap=200; Price=50},
            @{Symbol="GS"; Name="Goldman Sachs"; Sector="Finance"; Cap=150; Price=380},
            @{Symbol="XOM"; Name="Exxon"; Sector="Energy"; Cap=400; Price=110},
            @{Symbol="CVX"; Name="Chevron"; Sector="Energy"; Cap=300; Price=160},
            @{Symbol="JNJ"; Name="Johnson & Johnson"; Sector="Health"; Cap=450; Price=160},
            @{Symbol="UNH"; Name="UnitedHealth"; Sector="Health"; Cap=500; Price=520},
            @{Symbol="PFE"; Name="Pfizer"; Sector="Health"; Cap=200; Price=30},
            @{Symbol="KO"; Name="Coca-Cola"; Sector="Consumer"; Cap=280; Price=60},
            @{Symbol="PEP"; Name="PepsiCo"; Sector="Consumer"; Cap=240; Price=175},
            @{Symbol="WMT"; Name="Walmart"; Sector="Retail"; Cap=400; Price=160},
            @{Symbol="HD"; Name="Home Depot"; Sector="Retail"; Cap=350; Price=350}
        )
        
        foreach ($data in $stockData) {
            # Orbit based on market cap (larger = closer to center)
            $orbitRadius = 80 + ((3000 - $data.Cap) / 15)
            
            # Speed based on volatility (inverse of market cap)
            $orbitSpeed = 0.005 + (1000.0 / $data.Cap) * 0.002
            
            # Size based on market cap
            $size = 8 + ($data.Cap / 300)
            
            # Color based on sector
            $color = $this.GetSectorColor($data.Sector)
            
            [void]$this.Stocks.Add(@{
                Symbol = $data.Symbol
                Name = $data.Name
                Sector = $data.Sector
                MarketCap = $data.Cap
                Price = $data.Price
                OrbitRadius = $orbitRadius
                OrbitSpeed = $orbitSpeed
                OrbitAngle = (Get-Random) * [Math]::PI * 2
                Size = $size
                Color = $color
                X = 400; Y = 250; Z = 0
                Pulse = 0
                Selected = $false
            })
        }
        
        Write-Host "  🌟 Created $($this.Stocks.Count) stock stars" -ForegroundColor DarkCyan
    }
    
hidden [System.Drawing.Color] GetSectorColor([string]$sector) {
    switch ($sector) {
        "Tech"     { return [System.Drawing.Color]::FromArgb(100, 150, 255) }
        "Finance"  { return [System.Drawing.Color]::FromArgb(255, 215, 0) }
        "Energy"   { return [System.Drawing.Color]::FromArgb(255, 100, 100) }
        "Health"   { return [System.Drawing.Color]::FromArgb(100, 255, 150) }
        "Consumer" { return [System.Drawing.Color]::FromArgb(255, 150, 255) }
        "Retail"   { return [System.Drawing.Color]::FromArgb(150, 200, 255) }
        "Auto"     { return [System.Drawing.Color]::FromArgb(255, 180, 100) }
        default    { return [System.Drawing.Color]::White }
    }

    # Required by PowerShell class parser
    return [System.Drawing.Color]::White
}

    
    hidden [void] CreateShootingStar([hashtable]$stock) {
        [void]$this.ShootingStars.Add(@{
            X = $stock.X
            Y = $stock.Y
            VX = (Get-Random -Minimum 3 -Maximum 8)
            VY = (Get-Random -Minimum -2 -Maximum 2)
            Size = 6
            Color = [System.Drawing.Color]::FromArgb(255, 255, 100)
            Trail = [System.Collections.ArrayList]::new()
            Life = 100
        })
    }
    
    hidden [void] CreateBlackHole([hashtable]$stock) {
        [void]$this.BlackHoles.Add(@{
            X = $stock.X
            Y = $stock.Y
            Size = 10
            MaxSize = 50
            Strength = 0.5
            Life = 150
        })
    }
    
    hidden [void] CreateNebula() {
        # Get a random sector
        $sectors = $this.Stocks | Group-Object -Property Sector
        $sector = $sectors | Get-Random
        
        if ($sector -and $sector.Group.Count -gt 1) {
            # Calculate center of sector stocks
            $sectorStocks = $sector.Group
            $totalX = 0
            $totalY = 0
            $count = 0
            
            foreach ($stock in $sectorStocks) {
                $totalX += $stock.X
                $totalY += $stock.Y
                $count++
            }
            
            if ($count -gt 0) {
                $avgX = $totalX / $count
                $avgY = $totalY / $count
                
                [void]$this.Nebulas.Add(@{
                    X = $avgX
                    Y = $avgY
                    Size = 80
                    Color = $this.GetSectorColor($sector.Name)
                    Life = 200
                })
            }
        }
    }
    
    hidden [void] UpdateShootingStars() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($star in $this.ShootingStars) {
            $star.X += $star.VX
            $star.Y += $star.VY
            $star.Life -= 1
            
            # Add to trail
            if ($this.State.TickCount % 2 -eq 0) {
                [void]$star.Trail.Add(@{ X = $star.X; Y = $star.Y; Life = 20 })
            }
            
            # Update trail
            $activeTrail = [System.Collections.ArrayList]::new()
            foreach ($t in $star.Trail) {
                $t.Life -= 1
                if ($t.Life -gt 0) { [void]$activeTrail.Add($t) }
            }
            $star.Trail.Clear()
            foreach ($t in $activeTrail) { [void]$star.Trail.Add($t) }
            
            if ($star.Life -le 0 -or $star.X -gt 850) {
                [void]$toRemove.Add($star)
            }
        }
        
        foreach ($s in $toRemove) { [void]$this.ShootingStars.Remove($s) }
    }
    
    hidden [void] UpdateBlackHoles() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($hole in $this.BlackHoles) {
            $hole.Size += ($hole.MaxSize - $hole.Size) * 0.05
            $hole.Life -= 1
            
            # Pull nearby stocks
            foreach ($stock in $this.Stocks) {
                $dx = $hole.X - $stock.X
                $dy = $hole.Y - $stock.Y
                $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
                
                if ($dist -lt 100 -and $dist -gt 1) {
                    $force = $hole.Strength / ($dist * $dist) * 100
                    # Slightly pull stock toward black hole (visual effect)
                    # Don't actually modify orbit, just visual
                }
            }
            
            if ($hole.Life -le 0) { [void]$toRemove.Add($hole) }
        }
        
        foreach ($h in $toRemove) { [void]$this.BlackHoles.Remove($h) }
    }
    
    hidden [void] UpdateConnections() {
        $this.Connections.Clear()
        
        # Find correlations (stocks in same sector nearby)
        for ($i = 0; $i -lt $this.Stocks.Count; $i++) {
            $stock1 = $this.Stocks[$i]
            
            for ($j = $i + 1; $j -lt $this.Stocks.Count; $j++) {
                $stock2 = $this.Stocks[$j]
                
                if ($stock1.Sector -eq $stock2.Sector) {
                    $dx = $stock1.X - $stock2.X
                    $dy = $stock1.Y - $stock2.Y
                    $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
                    
                    if ($dist -lt 150) {
                        [void]$this.Connections.Add(@{
                            X1 = $stock1.X; Y1 = $stock1.Y
                            X2 = $stock2.X; Y2 = $stock2.Y
                            Color = $stock1.Color
                            Strength = 1.0 - ($dist / 150.0)
                        })
                    }
                }
            }
        }
    }
    
    hidden [void] UpdateNebulas() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($nebula in $this.Nebulas) {
            $nebula.Life -= 1
            $nebula.Size += 0.5
            
            if ($nebula.Life -le 0) { [void]$toRemove.Add($nebula) }
        }
        
        foreach ($n in $toRemove) { [void]$this.Nebulas.Remove($n) }
    }
    
    hidden [void] SetupEvents() {
        $self = $this
        
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderConstellation($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
        
        $this.Panel.Add_MouseClick({
            param($sender, $e)
            
            # Check if clicked on a stock
            $self.State.SelectedStock = $null
            
            foreach ($stock in $self.Stocks) {
                $dx = $e.X - $stock.X
                $dy = $e.Y - $stock.Y
                $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
                
                if ($dist -lt $stock.Size + 10) {
                    $self.State.SelectedStock = $stock
                    $stock.Selected = $true
                    
                    # Create shooting star effect
                    for ($i = 0; $i -lt 5; $i++) {
                        $angle = (Get-Random) * [Math]::PI * 2
                        $speed = 2 + (Get-Random) * 3
                        
                        [void]$self.ShootingStars.Add(@{
                            X = $stock.X
                            Y = $stock.Y
                            VX = [Math]::Cos($angle) * $speed
                            VY = [Math]::Sin($angle) * $speed
                            Size = 4
                            Color = $stock.Color
                            Trail = [System.Collections.ArrayList]::new()
                            Life = 60
                        })
                    }
                    
                    Write-Host "  ⭐ Selected: $($stock.Symbol) - $($stock.Name) | Price: `$$($stock.Price) | Cap: `$$($stock.MarketCap)B" -ForegroundColor Cyan
                    break
                }
                else {
                    $stock.Selected = $false
                }
            }
            
            $self.Panel.Invalidate()
        }.GetNewClosure())
    }
    
    hidden [void] RenderConstellation([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Deep space black
        $g.Clear([System.Drawing.Color]::Black)
        
        # Draw distant stars (background)
        $starRandom = New-Object System.Random(42)
        for ($i = 0; $i -lt 200; $i++) {
            $sx = $starRandom.Next(0, $width)
            $sy = $starRandom.Next(0, $height)
            $salpha = $starRandom.Next(50, 150)
            
            $starColor = [System.Drawing.Color]::FromArgb($salpha, 200, 200, 255)
            $starBrush = New-Object System.Drawing.SolidBrush($starColor)
            $g.FillEllipse($starBrush, $sx, $sy, 1, 1)
            $starBrush.Dispose()
        }
        
        # Draw nebulas (sector clouds)
        foreach ($nebula in $this.Nebulas) {
            $alpha = [int](($nebula.Life / 200.0) * 80)
            $nebColor = [System.Drawing.Color]::FromArgb($alpha, $nebula.Color.R, $nebula.Color.G, $nebula.Color.B)
            $nebBrush = New-Object System.Drawing.SolidBrush($nebColor)
            $g.FillEllipse($nebBrush, $nebula.X - $nebula.Size/2, $nebula.Y - $nebula.Size/2, $nebula.Size, $nebula.Size)
            $nebBrush.Dispose()
        }
        
        # Draw connections (correlations)
        foreach ($conn in $this.Connections) {
            $alpha = [int]($conn.Strength * 100)
            $connColor = [System.Drawing.Color]::FromArgb($alpha, $conn.Color.R, $conn.Color.G, $conn.Color.B)
            $connPen = New-Object System.Drawing.Pen($connColor, 1)
            $connPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
            $g.DrawLine($connPen, $conn.X1, $conn.Y1, $conn.X2, $conn.Y2)
            $connPen.Dispose()
        }
        
        # Draw black holes
        foreach ($hole in $this.BlackHoles) {
            # Event horizon
            $horizonColor = [System.Drawing.Color]::FromArgb(150, 100, 0, 150)
            $horizonBrush = New-Object System.Drawing.SolidBrush($horizonColor)
            $g.FillEllipse($horizonBrush, $hole.X - $hole.Size/2, $hole.Y - $hole.Size/2, $hole.Size, $hole.Size)
            $horizonBrush.Dispose()
            
            # Core
            $coreBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
            $coreSize = $hole.Size * 0.6
            $g.FillEllipse($coreBrush, $hole.X - $coreSize/2, $hole.Y - $coreSize/2, $coreSize, $coreSize)
            $coreBrush.Dispose()
            
            # Accretion disk
            $diskPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 100, 100), 2)
            $g.DrawEllipse($diskPen, $hole.X - $hole.Size/2, $hole.Y - $hole.Size/2, $hole.Size, $hole.Size)
            $diskPen.Dispose()
        }
        
        # Sort stocks by Z (depth) for proper layering
        $sortedStocks = $this.Stocks | Sort-Object -Property Z
        
        # Draw stocks (stars/planets)
        foreach ($stock in $sortedStocks) {
            $size = $stock.Size * (1 + $stock.Pulse * 0.3)
            
            # Glow based on size
            $glowSize = $size + 15
            $glowAlpha = [int](50 + $stock.Pulse * 50)
            $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, $stock.Color.R, $stock.Color.G, $stock.Color.B)
            $glowBrush = New-Object System.Drawing.SolidBrush($glowColor)
            $g.FillEllipse($glowBrush, $stock.X - $glowSize/2, $stock.Y - $glowSize/2, $glowSize, $glowSize)
            $glowBrush.Dispose()
            
            # Stock body
            $stockBrush = New-Object System.Drawing.SolidBrush($stock.Color)
            $g.FillEllipse($stockBrush, $stock.X - $size/2, $stock.Y - $size/2, $size, $size)
            $stockBrush.Dispose()
            
            # Selection ring
            if ($stock.Selected) {
                $ringPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3)
                $g.DrawEllipse($ringPen, $stock.X - $size/2 - 5, $stock.Y - $size/2 - 5, $size + 10, $size + 10)
                $ringPen.Dispose()
            }
            
            # Symbol label
            if ($size -gt 10) {
                $labelFont = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
                $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $labelSize = $g.MeasureString($stock.Symbol, $labelFont)
                $g.DrawString($stock.Symbol, $labelFont, $labelBrush, $stock.X - $labelSize.Width/2, $stock.Y + $size/2 + 3)
                $labelFont.Dispose()
                $labelBrush.Dispose()
            }
        }
        
        # Draw shooting stars
        foreach ($star in $this.ShootingStars) {
            # Trail
            foreach ($t in $star.Trail) {
                $alpha = [int](($t.Life / 20.0) * 150)
                $trailColor = [System.Drawing.Color]::FromArgb($alpha, $star.Color.R, $star.Color.G, $star.Color.B)
                $trailBrush = New-Object System.Drawing.SolidBrush($trailColor)
                $g.FillEllipse($trailBrush, $t.X - 2, $t.Y - 2, 4, 4)
                $trailBrush.Dispose()
            }
            
            # Star head
            $starBrush = New-Object System.Drawing.SolidBrush($star.Color)
            $g.FillEllipse($starBrush, $star.X - $star.Size/2, $star.Y - $star.Size/2, $star.Size, $star.Size)
            $starBrush.Dispose()
        }
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 200, 220, 255))
        $g.DrawString("✨ MARKET CONSTELLATION", $titleFont, $titleBrush, 20, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()         
     
        # Selected stock details
        if ($this.State.SelectedStock) {
            $stock = $this.State.SelectedStock
            
            $detailX = $width - 220
            $detailY = 20
            
            $detailBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 10, 10, 20))
            $g.FillRectangle($detailBg, $detailX, $detailY, 200, 140)
            $detailBg.Dispose()
            
            $detailBorder = New-Object System.Drawing.Pen($stock.Color, 2)
            $g.DrawRectangle($detailBorder, $detailX, $detailY, 200, 140)
            $detailBorder.Dispose()
            
            $detailFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $detailBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            
            $yPos = $detailY + 10
            $g.DrawString("⭐ $($stock.Symbol)", $detailFont, $detailBrush, $detailX + 10, $yPos)
            $yPos += 25
            
            $infoFont = New-Object System.Drawing.Font("Segoe UI", 9)
            $g.DrawString($stock.Name, $infoFont, $detailBrush, $detailX + 10, $yPos)
            $yPos += 20
            $g.DrawString("Sector: $($stock.Sector)", $infoFont, $detailBrush, $detailX + 10, $yPos)
            $yPos += 20
            $g.DrawString("Price: `$$($stock.Price)", $infoFont, $detailBrush, $detailX + 10, $yPos)
            $yPos += 20
            $g.DrawString("Market Cap: `$$($stock.MarketCap)B", $infoFont, $detailBrush, $detailX + 10, $yPos)
            
            $detailFont.Dispose()
            $infoFont.Dispose()
            $detailBrush.Dispose()
        }
        
        # Instructions
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 9)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 200, 200, 200))
        $g.DrawString("Click any star to see stock details |Shooting stars = Hot stocks", $infoFont, $infoBrush, 20, $height - 30)
        $infoFont.Dispose()
        $infoBrush.Dispose()
    }
}

function Stop-Show24 {
    Write-Host "[Show24] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show24")) {
        $Global:ShowManager.Shows["show24"].Stop()
    }
}

Write-Host "✅ Show24 - Market Constellation loaded!" -ForegroundColor Green
