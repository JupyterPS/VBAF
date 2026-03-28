# ====================================================
# HQshow23.ps1 — Money River v3 (Commerce Bank)
# Converted to Game Machine Architecture
# ====================================================

# ============================================
# Show23 - Inherits from BaseShow
# ============================================
class Show23 : BaseShow {
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $River
    hidden [System.Collections.ArrayList] $Bills
    hidden [System.Collections.ArrayList] $Coins
    hidden [System.Collections.ArrayList] $Transactions
    hidden [System.Collections.ArrayList] $Sources
    hidden [System.Collections.ArrayList] $Destinations
    hidden [System.Collections.ArrayList] $WaterParticles

    Show23([System.Windows.Forms.Panel]$panel) : base("show23", $panel) {
        $this.State = @{
            TickCount = 0
            TotalFlow = 0
            FlowRate = 0
            RiverWidth = 200
            CurrentSpeed = 2.0
        }
        $this.River = [System.Collections.ArrayList]::new()
        $this.Bills = [System.Collections.ArrayList]::new()
        $this.Coins = [System.Collections.ArrayList]::new()
        $this.Transactions = [System.Collections.ArrayList]::new()
        $this.Sources = [System.Collections.ArrayList]::new()
        $this.Destinations = [System.Collections.ArrayList]::new()
        $this.WaterParticles = [System.Collections.ArrayList]::new()
    }

    [void] OnStart() {
        Write-Host " 💰 [Show23] Initializing Money River..." -ForegroundColor Cyan
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(15, 25, 35)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Ticker messages
        $Show23Messages = @(
            "💰 MONEY RIVER - Real-time Cash Flow Visualization",
            "🌊 Watch capital flow through the financial ecosystem",
            "💵 Bills represent transactions, size indicates value",
            "🏦 From sources to destinations - the river of commerce",
            "📊 Current flowing through the arteries of business"
        )
        $global:messages = $Show23Messages
        Update-Ticker
        
        # Setup paint event (panel is canvas)
        $this.SetupPaintEvent()
        
        # Initialize data (EXACT V1)
        $this.InitializeRiverData()
        
        Write-Host " ✅ [Show23] Money River ready" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        # === UPDATE WATER PARTICLES ===
        $aliveParts = [System.Collections.ArrayList]::new()
        foreach ($particle in $this.WaterParticles) {
            $particle.Y += $particle.VelocityY
            $particle.X += $particle.VelocityX * 0.3
            
            if ($particle.Y -gt 450) {
                $particle.Y = 100
                $particle.X = Get-Random -Minimum 0 -Maximum 700
            }
            [void]$aliveParts.Add($particle)
        }
        $this.WaterParticles = $aliveParts
        
        # === SPAWN NEW MONEY ===
        if ($tick % 15 -eq 0) {
            $source = $this.Sources | Get-Random
            $dest = $this.Destinations | Get-Random
            $amount = Get-Random -Minimum 100 -Maximum 50000
            
            if ($amount -gt 5000) {
                # Spawn bill
                $billColor = switch ([int]($amount / 10000)) {
                    0 { [System.Drawing.Color]::FromArgb(200, 150, 200, 150) }
                    1 { [System.Drawing.Color]::FromArgb(200, 180, 220, 180) }
                    2 { [System.Drawing.Color]::FromArgb(200, 200, 240, 200) }
                    default { [System.Drawing.Color]::FromArgb(200, 220, 255, 220) }
                }
                
                [void]$this.Bills.Add(@{
                    X = $source.X; Y = $source.Y + 30
                    VelocityY = 2 + (Get-Random -Minimum 0 -Maximum 10) / 10.0
                    Amount = $amount; Scale = 0.6 + ($amount / 100000)
                    Color = $billColor; Rotation = (Get-Random -Minimum -15 -Maximum 15)
                    SourceId = $source.Id; DestId = $dest.Id; TargetX = $dest.X
                })
            } else {
                # Spawn coin
                [void]$this.Coins.Add(@{
                    X = $source.X + (Get-Random -Minimum -10 -Maximum 10)
                    Y = $source.Y + 30
                    VelocityY = 3 + (Get-Random -Minimum 0 -Maximum 15) / 10.0
                    Amount = $amount; Scale = 0.5 + ($amount / 10000)
                    SourceId = $source.Id; DestId = $dest.Id; TargetX = $dest.X
                })
            }
            $source.Pulse = 0
        }
        
        # === UPDATE BILLS ===
        $aliveBills = [System.Collections.ArrayList]::new()
        foreach ($bill in $this.Bills) {
            $bill.Y += $bill.VelocityY
            $drift = ($bill.TargetX - $bill.X) * 0.02
            $bill.X += $drift
            
            if ($bill.Y -gt 470) {
                $dest = $this.Destinations[$bill.DestId]
                $dest.Received += $bill.Amount
                $dest.Pulse = 0
                $this.State.TotalFlow += $bill.Amount
            } else {
                [void]$aliveBills.Add($bill)
            }
        }
        $this.Bills = $aliveBills
        
        # === UPDATE COINS ===
        $aliveCoins = [System.Collections.ArrayList]::new()
        foreach ($coin in $this.Coins) {
            $coin.Y += $coin.VelocityY
            $drift = ($coin.TargetX - $coin.X) * 0.03
            $coin.X += $drift
            
            if ($coin.Y -gt 470) {
                $dest = $this.Destinations[$coin.DestId]
                $dest.Received += $coin.Amount
                $dest.Pulse = 0
                $this.State.TotalFlow += $coin.Amount
            } else {
                [void]$aliveCoins.Add($coin)
            }
        }
        $this.Coins = $aliveCoins
        
        # === UPDATE NODES ===
        foreach ($source in $this.Sources) {
            $source.Pulse += 0.15
            if ($source.Pulse -gt 6.28) { $source.Pulse -= 6.28 }
        }
        foreach ($dest in $this.Destinations) {
            $dest.Pulse += 0.12
            if ($dest.Pulse -gt 6.28) { $dest.Pulse -= 6.28 }
        }
        
        $this.State.FlowRate = ($this.Bills.Count + $this.Coins.Count) * 500
        
        # Repaint
        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host " 🛑 [Show23] Cleaning up Money River..." -ForegroundColor Yellow
        
        $this.Bills.Clear()
        $this.Coins.Clear()
        $this.WaterParticles.Clear()
        $this.Sources.Clear()
        $this.Destinations.Clear()
        
        if ($this.Panel) {
            $this.Panel.Remove_Paint($null)
        }
        $this.Panel.Controls.Clear()
        
        $this.State.TotalFlow = 0
        $this.State.TickCount = 0
        
        Write-Host " ✅ [Show23] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderFrame($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }

    hidden [void] InitializeRiverData() {
        # Sources
        $sourceTypes = @("Sales", "Investments", "Loans", "Deposits", "Interest")
        for ($i = 0; $i -lt 5; $i++) {
            [void]$this.Sources.Add(@{
                Id = $i; X = 100 + ($i * 120); Y = 50
                Name = $sourceTypes[$i]; FlowRate = Get-Random -Minimum 5 -Maximum 20
                Color = [System.Drawing.Color]::FromArgb(50, 200, 100); Pulse = 0
            })
        }
        
        # Destinations
        $destTypes = @("Payroll", "Operations", "Investments", "Reserves", "Dividends")
        for ($i = 0; $i -lt 5; $i++) {
            [void]$this.Destinations.Add(@{
                Id = $i; X = 100 + ($i * 120); Y = 500
                Name = $destTypes[$i]; Received = 0
                Color = [System.Drawing.Color]::FromArgb(200, 100, 50); Pulse = 0
            })
        }
        
        # Water particles
        for ($p = 0; $p -lt 150; $p++) {
            [void]$this.WaterParticles.Add(@{
                X = Get-Random -Minimum 0 -Maximum 700
                Y = Get-Random -Minimum 100 -Maximum 450
                VelocityX = (Get-Random -Minimum -10 -Maximum 10) / 10.0
                VelocityY = 1 + (Get-Random -Minimum 0 -Maximum 20) / 10.0
                Size = 2 + (Get-Random -Minimum 0 -Maximum 3)
                Alpha = 50 + (Get-Random -Minimum 0 -Maximum 100)
            })
        }
    }

    hidden [void] RenderFrame([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(15, 25, 35), [System.Drawing.Color]::FromArgb(25, 40, 60)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # River bed
        $riverX = $width / 2 - $this.State.RiverWidth / 2
        $riverPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $points = [System.Collections.ArrayList]::new()
        $wavePhase = $this.State.TickCount * 0.05
        
        for ($y = 100; $y -lt 450; $y += 10) {
            $wave = [math]::Sin($y * 0.05 + $wavePhase) * 30
            [void]$points.Add([System.Drawing.PointF]::new($riverX + $wave, $y))
        }
        for ($y = 450; $y -gt 100; $y -= 10) {
            $wave = [math]::Sin($y * 0.05 + $wavePhase) * 30
            [void]$points.Add([System.Drawing.PointF]::new($riverX + $this.State.RiverWidth + $wave, $y))
        }
        
        if ($points.Count -gt 2) {
            $riverPath.AddPolygon($points.ToArray([System.Drawing.PointF]))
            $waterBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                [System.Drawing.Point]::new($riverX, 0), [System.Drawing.Point]::new($riverX + $this.State.RiverWidth, 0),
                [System.Drawing.Color]::FromArgb(80, 40, 80, 120), [System.Drawing.Color]::FromArgb(80, 60, 120, 180)
            )
            $g.FillPath($waterBrush, $riverPath)
            $waterBrush.Dispose()
        }
        $riverPath.Dispose()
        
        # Water particles
        foreach ($particle in $this.WaterParticles) {
            $particleColor = [System.Drawing.Color]::FromArgb($particle.Alpha, 150, 200, 255)
            $particleBrush = New-Object System.Drawing.SolidBrush($particleColor)
            $g.FillEllipse($particleBrush, $particle.X, $particle.Y, $particle.Size, $particle.Size)
            $particleBrush.Dispose()
        }
        
        # Bills
        foreach ($bill in $this.Bills) {
            $billWidth = 40 * $bill.Scale; $billHeight = 20 * $bill.Scale
            
            $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 0, 0, 0))
            $g.FillRectangle($shadowBrush, $bill.X + 2, $bill.Y + 2, $billWidth, $billHeight)
            $shadowBrush.Dispose()
            
            $billBrush = New-Object System.Drawing.SolidBrush($bill.Color)
            $g.FillRectangle($billBrush, $bill.X, $bill.Y, $billWidth, $billHeight)
            $billBrush.Dispose()
            
            $billPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 100, 0), 2)
            $g.DrawRectangle($billPen, $bill.X, $bill.Y, $billWidth, $billHeight)
            $billPen.Dispose()
            
            $dollarFont = New-Object System.Drawing.Font("Arial", [int](8 * $bill.Scale), [System.Drawing.FontStyle]::Bold)
            $dollarBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 80, 0))
            $g.DrawString("$", $dollarFont, $dollarBrush, $bill.X + $billWidth/3, $bill.Y + $billHeight/4)
            $dollarFont.Dispose(); $dollarBrush.Dispose()
            
            if ($bill.Scale -gt 0.8) {
                $amountFont = New-Object System.Drawing.Font("Consolas", 6, [System.Drawing.FontStyle]::Bold)
                $amountBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 60, 0))
                $amountText = "$" + $bill.Amount.ToString("N0")
                $g.DrawString($amountText, $amountFont, $amountBrush, $bill.X + 2, $bill.Y + $billHeight - 10)
                $amountFont.Dispose(); $amountBrush.Dispose()
            }
        }
        
        # Coins
        foreach ($coin in $this.Coins) {
            $coinRadius = 8 * $coin.Scale
            $coinPath = New-Object System.Drawing.Drawing2D.GraphicsPath
            $coinPath.AddEllipse($coin.X - $coinRadius, $coin.Y - $coinRadius, $coinRadius * 2, $coinRadius * 2)
            $coinBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($coinPath)
            $coinBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 215, 100)
            $coinBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(180, 140, 0))
            $g.FillPath($coinBrush, $coinPath)
            $coinBrush.Dispose(); $coinPath.Dispose()
            
            $coinPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 100, 0), 1)
            $g.DrawEllipse($coinPen, $coin.X - $coinRadius, $coin.Y - $coinRadius, $coinRadius * 2, $coinRadius * 2)
            $coinPen.Dispose()
        }
        
        # Sources
        foreach ($source in $this.Sources) {
            $pulse = [math]::Abs([math]::Sin($source.Pulse)) * 10
            $nodeSize = 30 + $pulse
            
            $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 50, 200, 100))
            $g.FillEllipse($glowBrush, $source.X - $nodeSize, $source.Y - $nodeSize, $nodeSize * 2, $nodeSize * 2)
            $glowBrush.Dispose()
            
            $nodePath = New-Object System.Drawing.Drawing2D.GraphicsPath
            $nodePath.AddEllipse($source.X - 20, $source.Y - 20, 40, 40)
            $nodeBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($nodePath)
            $nodeBrush.CenterColor = [System.Drawing.Color]::FromArgb(100, 255, 150)
            $nodeBrush.SurroundColors = @($source.Color)
            $g.FillPath($nodeBrush, $nodePath)
            $nodeBrush.Dispose(); $nodePath.Dispose()
            
            $labelFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $labelSize = $g.MeasureString($source.Name, $labelFont)
            $g.DrawString($source.Name, $labelFont, $labelBrush, $source.X - $labelSize.Width/2, $source.Y - 35)
            $labelFont.Dispose(); $labelBrush.Dispose()
            
            $rateFont = New-Object System.Drawing.Font("Consolas", 7)
            $rateBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 255, 255))
            $rateText = "$" + ($source.FlowRate * 1000).ToString("N0") + "/s"
            $rateSize = $g.MeasureString($rateText, $rateFont)
            $g.DrawString($rateText, $rateFont, $rateBrush, $source.X - $rateSize.Width/2, $source.Y + 25)
            $rateFont.Dispose(); $rateBrush.Dispose()
        }
        
        # Destinations
        foreach ($dest in $this.Destinations) {
            $pulse = [math]::Abs([math]::Sin($dest.Pulse)) * 10
            $nodeSize = 30 + $pulse
            
            $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 200, 100, 50))
            $g.FillEllipse($glowBrush, $dest.X - $nodeSize, $dest.Y - $nodeSize, $nodeSize * 2, $nodeSize * 2)
            $glowBrush.Dispose()
            
            $nodePath = New-Object System.Drawing.Drawing2D.GraphicsPath
            $nodePath.AddEllipse($dest.X - 20, $dest.Y - 20, 40, 40)
            $nodeBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($nodePath)
            $nodeBrush.CenterColor = [System.Drawing.Color]::FromArgb(255, 150, 100)
            $nodeBrush.SurroundColors = @($dest.Color)
            $g.FillPath($nodeBrush, $nodePath)
            $nodeBrush.Dispose(); $nodePath.Dispose()
            
            $labelFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $labelSize = $g.MeasureString($dest.Name, $labelFont)
            $g.DrawString($dest.Name, $labelFont, $labelBrush, $dest.X - $labelSize.Width/2, $dest.Y + 25)
            $labelFont.Dispose(); $labelBrush.Dispose()
        }
        
        # Statistics
        $statsFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $statsBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 255, 150))
        
        $stats = @(
            "💰 TOTAL FLOW: $" + $this.State.TotalFlow.ToString("N0"),
            "🌊 FLOW RATE: $" + ([int]$this.State.FlowRate).ToString("N0") + "/s",
            "💵 ACTIVE: " + $this.Bills.Count + " bills, " + $this.Coins.Count + " coins"
        )
        
        $yPos = $height - 80
        foreach ($stat in $stats) {
            $g.DrawString($stat, $statsFont, $statsBrush, 20, $yPos)
            $yPos += 20
        }
        $statsFont.Dispose(); $statsBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 150, 220, 255))
        $titleText = "✨ MONEY RIVER - Cash Flow Visualization"
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, $height - $titleSize.Height - 10)
        $titleFont.Dispose(); $titleBrush.Dispose()
    }
}

# Legacy compatibility
function Stop-Show23 {
    Write-Host "🛑 [Show23] Stop called (v3)" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show23")) {
        $Global:ShowManager.Shows["show23"].Stop()
    }
}

Write-Host "✅ COMPLETE Show23 v3 - Copy/Paste READY for ISE!" -ForegroundColor Green
