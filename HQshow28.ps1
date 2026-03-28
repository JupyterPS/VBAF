# ===============================
# Show28 — MONEY RIVER HYBRID (GM v3)
# Commerce Bank: Ultimate Cash Flow Visualization
# ===============================

Write-Host "`n=> _____ HQshow28 (Money River Hybrid GMv3) ___________ <=`n" -ForegroundColor Cyan

class Show28 : BaseShow {
    hidden [System.Collections.ArrayList] $Nodes
    hidden [System.Collections.ArrayList] $Rivers
    hidden [System.Collections.ArrayList] $Bills
    hidden [System.Collections.ArrayList] $Coins
    hidden [System.Collections.ArrayList] $WaterParticles

    hidden [int]   $TickCount
    hidden [float] $TotalFlow
    hidden [float] $FlowRate

    Show28([System.Windows.Forms.Panel]$panel) : base("show28", $panel) {
        $this.Nodes          = [System.Collections.ArrayList]::new()
        $this.Rivers         = [System.Collections.ArrayList]::new()
        $this.Bills          = [System.Collections.ArrayList]::new()
        $this.Coins          = [System.Collections.ArrayList]::new()
        $this.WaterParticles = [System.Collections.ArrayList]::new()

        $this.TickCount = 0
        $this.TotalFlow = 0
        $this.FlowRate  = 0
    }

    [void] OnStart() {
        Write-Host "🌊 [Show28] Money River Hybrid initializing..." -ForegroundColor Magenta

        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 25)

        # Double buffering
        $prop = $this.Panel.GetType().GetProperty(
            "DoubleBuffered",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }

        $this.InitializeNetwork()
        $this.InitializeWater()
        $this.SetupPaintEvent()
        $this.SetupVisibleChanged()

        Write-Host "  ✓ [Show28] Nodes: $($this.Nodes.Count), Rivers: $($this.Rivers.Count)" -ForegroundColor Green
        Write-Host "  ✅ [Show28] Ready (GM v3)" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.TickCount++
        $tick = $this.TickCount

        # Water particles
        foreach ($particle in $this.WaterParticles) {
            $particle.X += $particle.VelocityX
            $particle.Y += $particle.VelocityY

            if ($particle.X -lt 0)   { $particle.X = 700 }
            if ($particle.X -gt 700) { $particle.X = 0   }
            if ($particle.Y -lt 0)   { $particle.Y = 500 }
            if ($particle.Y -gt 500) { $particle.Y = 0   }
        }

        # Rivers – flows
        foreach ($river in $this.Rivers) {
            if ($tick % 20 -eq 0) {
                $river.TargetFlow = (Get-Random -Minimum 3 -Maximum 10) / 10.0
            }
            $river.Flow += ($river.TargetFlow - $river.Flow) * 0.1
        }

        # Nodes – pulse/activity/flow
        foreach ($node in $this.Nodes) {
            $node.Pulse = [math]::Abs([math]::Sin($tick * 0.05 + $node.X * 0.01))
            $node.Activity *= 0.95

            if ($tick % 30 -eq 0 -and (Get-Random -Minimum 0 -Maximum 10) -gt 7) {
                $node.Activity = 1.0
                $amount = Get-Random -Minimum 1000 -Maximum 50000
                $node.Balance += $amount
                $this.TotalFlow += $amount
            }
        }

        # Spawn currency
        if ($tick % 10 -eq 0) {
            $activeRivers = $this.Rivers | Where-Object { $_.Flow -gt 0.3 }
            if ($activeRivers.Count -gt 0) {
                $river = $activeRivers | Get-Random
                $amount = Get-Random -Minimum 500 -Maximum 80000

                if ($amount -gt 10000) {
                    # Bill
                    $billColor = switch ([int]($amount / 20000)) {
                        0 { [System.Drawing.Color]::FromArgb(220, 150, 220, 150) }
                        1 { [System.Drawing.Color]::FromArgb(220, 180, 240, 180) }
                        2 { [System.Drawing.Color]::FromArgb(220, 200, 255, 200) }
                        default { [System.Drawing.Color]::FromArgb(220, 220, 255, 220) }
                    }

                    [void]$this.Bills.Add(@{
                        X        = $river.FromNode.X
                        Y        = $river.FromNode.Y
                        Amount   = $amount
                        Scale    = 0.6 + ($amount / 150000)
                        Color    = $billColor
                        River    = $river
                        Progress = 0.0
                        Speed    = 0.015 + (Get-Random -Minimum 0 -Maximum 10) / 100.0
                    })
                } else {
                    # Coin
                    [void]$this.Coins.Add(@{
                        X        = $river.FromNode.X
                        Y        = $river.FromNode.Y
                        Amount   = $amount
                        Scale    = 0.5 + ($amount / 20000)
                        River    = $river
                        Progress = 0.0
                        Speed    = 0.02 + (Get-Random -Minimum 0 -Maximum 15) / 100.0
                    })
                }

                $river.FromNode.Activity = 0.9
            }
        }

        # Move bills along Beziers
        $aliveBills = [System.Collections.ArrayList]::new()
        foreach ($bill in $this.Bills) {
            $bill.Progress += $bill.Speed
            if ($bill.Progress -ge 1.0) {
                $bill.River.ToNode.Activity = 1.0
                $bill.River.ToNode.Balance += $bill.Amount
            } else {
                $this.UpdateBezierPosition($bill)
                [void]$aliveBills.Add($bill)
            }
        }
        $this.Bills = $aliveBills

        # Move coins along Beziers
        $aliveCoins = [System.Collections.ArrayList]::new()
        foreach ($coin in $this.Coins) {
            $coin.Progress += $coin.Speed
            if ($coin.Progress -ge 1.0) {
                $coin.River.ToNode.Activity = 0.8
                $coin.River.ToNode.Balance += $coin.Amount
            } else {
                $this.UpdateBezierPosition($coin)
                [void]$aliveCoins.Add($coin)
            }
        }
        $this.Coins = $aliveCoins

        # Flow rate (simple visual metric)
        $this.FlowRate = ($this.Bills.Count * 2000 + $this.Coins.Count * 500)

        # Limit counts
        while ($this.Bills.Count -gt 50) { $this.Bills.RemoveAt(0) }
        while ($this.Coins.Count -gt 80) { $this.Coins.RemoveAt(0) }

        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "🛑 [Show28] Stopping / cleaning..." -ForegroundColor Yellow

        $this.Nodes.Clear()
        $this.Rivers.Clear()
        $this.Bills.Clear()
        $this.Coins.Clear()
        $this.WaterParticles.Clear()

        $this.TickCount = 0
        $this.TotalFlow = 0
        $this.FlowRate  = 0

        $this.Panel.Controls.Clear()
        Write-Host "✅ [Show28] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] InitializeNetwork() {
        $nodeTypes = @(
            @{Name="Central Bank";  X=150; Y=250; Size=35; Type="Bank";      Color=[System.Drawing.Color]::Gold},
            @{Name="Commerce HQ";  X=350; Y=180; Size=30; Type="Bank";      Color=[System.Drawing.Color]::Yellow},
            @{Name="Branch A";     X=550; Y=120; Size=22; Type="Branch";    Color=[System.Drawing.Color]::Orange},
            @{Name="Branch B";     X=550; Y=280; Size=22; Type="Branch";    Color=[System.Drawing.Color]::Orange},
            @{Name="Corporate 1";  X=280; Y=340; Size=20; Type="Business";  Color=[System.Drawing.Color]::LightGreen},
            @{Name="Corporate 2";  X=450; Y=370; Size=20; Type="Business";  Color=[System.Drawing.Color]::LightGreen},
            @{Name="Customers";    X=180; Y=100; Size=18; Type="Customer";  Color=[System.Drawing.Color]::LightBlue},
            @{Name="Investments";  X=600; Y=220; Size=25; Type="Investment";Color=[System.Drawing.Color]::LightGoldenrodYellow}
        )

        foreach ($nodeData in $nodeTypes) {
            [void]$this.Nodes.Add(@{
                Name    = $nodeData.Name
                X       = $nodeData.X
                Y       = $nodeData.Y
                Size    = $nodeData.Size
                Type    = $nodeData.Type
                Color   = $nodeData.Color
                Pulse   = 0.0
                Activity= 0.0
                Balance = Get-Random -Minimum 100000 -Maximum 9999999
            })
        }

        $connections = @(
            @{From=0; To=1; Width=8},
            @{From=1; To=2; Width=5},
            @{From=1; To=3; Width=5},
            @{From=1; To=4; Width=4},
            @{From=1; To=5; Width=4},
            @{From=6; To=1; Width=6},
            @{From=1; To=7; Width=6},
            @{From=4; To=0; Width=3},
            @{From=5; To=7; Width=3}
        )

        foreach ($conn in $connections) {
            $fromNode = $this.Nodes[$conn.From]
            $toNode   = $this.Nodes[$conn.To]

            [void]$this.Rivers.Add(@{
                FromNode   = $fromNode
                ToNode     = $toNode
                Width      = $conn.Width
                Flow       = 0.0
                TargetFlow = 0.0
            })
        }
    }

    hidden [void] InitializeWater() {
        for ($p = 0; $p -lt 100; $p++) {
            [void]$this.WaterParticles.Add(@{
                X         = Get-Random -Minimum 0 -Maximum 700
                Y         = Get-Random -Minimum 0 -Maximum 500
                VelocityX = (Get-Random -Minimum -20 -Maximum 20) / 20.0
                VelocityY = (Get-Random -Minimum -20 -Maximum 20) / 20.0
                Size      = 2 + (Get-Random -Minimum 0 -Maximum 2)
                Alpha     = 30 + (Get-Random -Minimum 0 -Maximum 70)
                Life      = Get-Random -Minimum 50 -Maximum 150
            })
        }
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderScene($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }

    hidden [void] SetupVisibleChanged() {
        $self = $this
        $this.Panel.Add_VisibleChanged({
            param($s, $e)
            if (-not $self.Panel.Visible) {
                # Optional: lightweight trim when hidden
                $self.Bills.Clear()
                $self.Coins.Clear()
            }
        }.GetNewClosure())
    }

    hidden [void] UpdateBezierPosition([hashtable]$item) {
        $t  = [double]$item.Progress
        $x1 = $item.River.FromNode.X
        $y1 = $item.River.FromNode.Y
        $x2 = $item.River.ToNode.X
        $y2 = $item.River.ToNode.Y

        $midX   = ($x1 + $x2) / 2.0
        $midY   = ($y1 + $y2) / 2.0
        $offsetX = ($y2 - $y1) * 0.2
        $offsetY = ($x1 - $x2) * 0.2

        $cx = $midX + $offsetX
        $cy = $midY + $offsetY

        # Cubic Bezier via quadratic split (same as original)
        $t2 = $t * $t
        $t3 = $t2 * $t
        $mt = 1.0 - $t
        $mt2 = $mt * $mt
        $mt3 = $mt2 * $mt

        $item.X = $mt3 * $x1 + 3 * $mt2 * $t * $cx + 3 * $mt * $t2 * $cx + $t3 * $x2
        $item.Y = $mt3 * $y1 + 3 * $mt2 * $t * $cy + 3 * $mt * $t2 * $cy + $t3 * $y2
    }

    hidden [void] RenderScene([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        if ($width -le 0 -or $height -le 0) { return }

        # Background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(10, 15, 25),
            [System.Drawing.Color]::FromArgb(20, 10, 35)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()

        # Grid
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(15, 100, 100, 100), 1)
        for ($i = 0; $i -lt 25; $i++) {
            $x = $i * 30
            $g.DrawLine($gridPen, $x, 0, $x, $height)
            $y = $i * 30
            $g.DrawLine($gridPen, 0, $y, $width, $y)
        }
        $gridPen.Dispose()

        # Water particles
        foreach ($particle in $this.WaterParticles) {
            $particleColor = [System.Drawing.Color]::FromArgb($particle.Alpha, 100, 180, 255)
            $particleBrush = New-Object System.Drawing.SolidBrush($particleColor)
            $g.FillEllipse($particleBrush, $particle.X, $particle.Y, $particle.Size, $particle.Size)
            $particleBrush.Dispose()
        }

        # Rivers
        foreach ($river in $this.Rivers) {
            $x1 = $river.FromNode.X
            $y1 = $river.FromNode.Y
            $x2 = $river.ToNode.X
            $y2 = $river.ToNode.Y

            $midX   = ($x1 + $x2) / 2.0
            $midY   = ($y1 + $y2) / 2.0
            $offsetX = ($y2 - $y1) * 0.2
            $offsetY = ($x1 - $x2) * 0.2

            $wave = [math]::Sin($this.TickCount * 0.05) * 5
            $offsetX += $wave
            $offsetY += $wave

            $flowIntensity = [math]::Min(255, $river.Flow * 50)

            # Glow
            if ($flowIntensity -gt 30) {
                $glowAlpha = [math]::Max(20, [math]::Min(255, $flowIntensity / 3))
                $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, 255, 215, 0)
                $glowWidth = $river.Width * 3
                $glowPen = New-Object System.Drawing.Pen($glowColor, $glowWidth)
                $glowPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
                $glowPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round

                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddBezier($x1, $y1, $midX + $offsetX, $midY + $offsetY, $midX + $offsetX, $midY + $offsetY, $x2, $y2)
                $g.DrawPath($glowPen, $path)
                $path.Dispose()
                $glowPen.Dispose()
            }

            # Core
            $riverColor = [System.Drawing.Color]::FromArgb([math]::Max(100, $flowIntensity), 255, 200, 0)
            $riverPen = New-Object System.Drawing.Pen($riverColor, $river.Width)
            $riverPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $riverPen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round

            $path2 = New-Object System.Drawing.Drawing2D.GraphicsPath
            $path2.AddBezier($x1, $y1, $midX + $offsetX, $midY + $offsetY, $midX + $offsetX, $midY + $offsetY, $x2, $y2)
            $g.DrawPath($riverPen, $path2)
            $path2.Dispose()
            $riverPen.Dispose()
        }

        # Bills
        foreach ($bill in $this.Bills) {
            $billWidth  = 45 * $bill.Scale
            $billHeight = 22 * $bill.Scale

            # Shadow
            $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 0, 0, 0))
            $g.FillRectangle($shadowBrush, $bill.X + 2, $bill.Y + 2, $billWidth, $billHeight)
            $shadowBrush.Dispose()

            $billRect = [System.Drawing.Rectangle]::new([int]$bill.X, [int]$bill.Y, [int]$billWidth, [int]$billHeight)
            $billBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                $billRect,
                $bill.Color,
                [System.Drawing.Color]::FromArgb($bill.Color.A, $bill.Color.R - 50, $bill.Color.G - 50, $bill.Color.B - 30),
                45
            )
            $g.FillRectangle($billBrush, $billRect)
            $billBrush.Dispose()

            $billPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 0, 100, 0), 2)
            $g.DrawRectangle($billPen, $billRect)
            $billPen.Dispose()

            if ($bill.Scale -gt 0.5) {
                $dollarFont  = New-Object System.Drawing.Font("Arial", [int](10 * $bill.Scale), [System.Drawing.FontStyle]::Bold)
                $dollarBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 80, 0))
                $g.DrawString("$", $dollarFont, $dollarBrush, $bill.X + $billWidth/3, $bill.Y + $billHeight/4)
                $dollarFont.Dispose()
                $dollarBrush.Dispose()
            }

            if ($bill.Scale -gt 0.7) {
                $amountFont  = New-Object System.Drawing.Font("Consolas", 6, [System.Drawing.FontStyle]::Bold)
                $amountBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 60, 0))
                $amountText  = "$" + $bill.Amount.ToString("N0")
                $g.DrawString($amountText, $amountFont, $amountBrush, $bill.X + 2, $bill.Y + $billHeight - 10)
                $amountFont.Dispose()
                $amountBrush.Dispose()
            }
        }

        # Coins
        foreach ($coin in $this.Coins) {
            $coinRadius = 10 * $coin.Scale

            $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 255, 215, 0))
            $g.FillEllipse($glowBrush, $coin.X - $coinRadius*1.5, $coin.Y - $coinRadius*1.5, $coinRadius*3, $coinRadius*3)
            $glowBrush.Dispose()

            $coinPath = New-Object System.Drawing.Drawing2D.GraphicsPath
            $coinPath.AddEllipse($coin.X - $coinRadius, $coin.Y - $coinRadius, $coinRadius*2, $coinRadius*2)
            $coinBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($coinPath)
            $coinBrush.CenterColor    = [System.Drawing.Color]::FromArgb(255, 215, 100)
            $coinBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(200, 150, 0))
            $g.FillPath($coinBrush, $coinPath)
            $coinBrush.Dispose()
            $coinPath.Dispose()

            if ($coinRadius -gt 5) {
                $fontSize = [math]::Max(5, $coinRadius / 1.5)
                $coinFont = New-Object System.Drawing.Font("Arial", $fontSize, [System.Drawing.FontStyle]::Bold)
                $coinTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 100, 0))
                $coinText = "$"
                $coinSize = $g.MeasureString($coinText, $coinFont)
                $g.DrawString($coinText, $coinFont, $coinTextBrush, $coin.X - $coinSize.Width/2, $coin.Y - $coinSize.Height/2)
                $coinFont.Dispose()
                $coinTextBrush.Dispose()
            }
        }

        # Nodes
        foreach ($node in $this.Nodes) {
            $size = $node.Size + ($node.Pulse * 4)

            if ($node.Activity -gt 0.2) {
                $glowSize = $size * 2.5
                $alpha = [math]::Min(200, $node.Activity * 255)
                $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha/3, 255, 215, 0))
                $g.FillEllipse($glowBrush, $node.X - $glowSize, $node.Y - $glowSize, $glowSize*2, $glowSize*2)
                $glowBrush.Dispose()
            }

            $nodePath = New-Object System.Drawing.Drawing2D.GraphicsPath
            $nodePath.AddEllipse($node.X - $size, $node.Y - $size, $size*2, $size*2)

            $gradientBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($nodePath)
            $gradientBrush.CenterColor    = $node.Color
            $gradientBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(220, $node.Color.R/2, $node.Color.G/2, $node.Color.B/2))
            $g.FillPath($gradientBrush, $nodePath)
            $gradientBrush.Dispose()
            $nodePath.Dispose()

            $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(220, 255, 255, 255), 2.5)
            $g.DrawEllipse($borderPen, $node.X - $size, $node.Y - $size, $size*2, $size*2)
            $borderPen.Dispose()

            $labelFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $labelSize = $g.MeasureString($node.Name, $labelFont)

            $labelBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 0, 0, 0))
            $g.FillRectangle($labelBg, $node.X - $labelSize.Width/2 - 3, $node.Y - $size - 20, $labelSize.Width + 6, $labelSize.Height + 2)
            $labelBg.Dispose()

            $g.DrawString($node.Name, $labelFont, $labelBrush, $node.X - $labelSize.Width/2, $node.Y - $size - 18)
            $labelFont.Dispose()
            $labelBrush.Dispose()

            $balanceText = "$" + [math]::Round($node.Balance / 1000) + "K"
            $balanceFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
            $balanceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 255, 100))
            $balanceSize = $g.MeasureString($balanceText, $balanceFont)
            $g.DrawString($balanceText, $balanceFont, $balanceBrush, $node.X - $balanceSize.Width/2, $node.Y + $size + 8)
            $balanceFont.Dispose()
            $balanceBrush.Dispose()
        }

        # Stats panel
        $statsFont  = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $statsBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 0))
        $stats = @(
            "TOTAL FLOW: $" + [math]::Round($this.TotalFlow / 1000) + "K",
            "FLOW RATE: $" + ([int]$this.FlowRate).ToString("N0") + "/s",
            "ACTIVE: " + $this.Bills.Count + " bills | " + $this.Coins.Count + " coins"
        )
        $yPos = 18
        foreach ($stat in $stats) {
            $g.DrawString($stat, $statsFont, $statsBrush, 18, $yPos)
            $yPos += 25
        }
        $statsFont.Dispose()
        $statsBrush.Dispose()

        # Footer network info
        $infoFont  = New-Object System.Drawing.Font("Consolas", 8)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 200, 200, 200))
        $info = "Network: $($this.Nodes.Count) nodes | $($this.Rivers.Count) rivers"
        $g.DrawString($info, $infoFont, $infoBrush, 10, $height - 25)
        $infoFont.Dispose()
        $infoBrush.Dispose()

        # Title at bottom center
        $titleText  = "✨ MONEY RIVER HYBRID"
        $titleFont  = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 180, 220, 255))
        $titleSize  = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, $height - 35)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

function Stop-Show28 {
    Write-Host "🛑 [Show28] Stop called (GM v3)" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show28")) {
        $Global:ShowManager.Shows["show28"].Stop()
    }
    Write-Host "✅ [Show28] Stopped" -ForegroundColor Green
}

Write-Host "✅ Show28 (Money River Hybrid GM v3) class loaded" -ForegroundColor Green

 


 


 