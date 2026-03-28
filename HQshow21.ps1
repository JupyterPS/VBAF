# ====================================================
# HQshow21.ps1 — Money River v3 (Commerce Bank)
# Converted to Game Machine Architecture
# ====================================================

# ============================================
# Show21 - Inherits from BaseShow
# ============================================
class Show21 : BaseShow {
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Nodes
    hidden [System.Collections.ArrayList] $Rivers
    hidden [System.Collections.ArrayList] $Particles
    hidden [System.Windows.Forms.Panel] $Canvas

    Show21([System.Windows.Forms.Panel]$panel) : base("show21", $panel) {
        $this.State = @{ TickCount = 0; LastSpawn = 0; TotalFlow = 0 }
        $this.Nodes = [System.Collections.ArrayList]::new()
        $this.Rivers = [System.Collections.ArrayList]::new()
        $this.Particles = [System.Collections.ArrayList]::new()
    }

    [void] OnStart() {
        Write-Host " 💰 [Show21] Initializing Money River..." -ForegroundColor Cyan
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 25)
        
        $Show21Messages = @(
            "💰 MONEY RIVER - Real-time Cash Flow Visualization",
            "🌊 Watch capital flow between accounts and institutions",
            "💵 Golden streams represent transaction volume",
            "🏦 Commerce Bank - Moving Money, Building Futures"
        )
        $global:messages = $Show21Messages
        Update-Ticker
        
        $this.CreateCanvas()
        $this.SetupPaintEvent()
        $this.InitializeFinancialNetwork()
        Write-Host " ✅ [Show21] Money River ready" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        foreach ($river in $this.Rivers) {
            if ($tick % 20 -eq 0) { $river.TargetFlow = (Get-Random -Minimum 3 -Maximum 10) / 10.0 }
            $river.Flow += ($river.TargetFlow - $river.Flow) * 0.1
        }
        
        foreach ($node in $this.Nodes) {
            $node.Pulse = [math]::Abs([math]::Sin($tick * 0.05 + $node.X * 0.01))
            $node.Activity *= 0.95
            if ($tick % 30 -eq 0 -and (Get-Random -Minimum 0 -Maximum 10) -gt 7) {
                $node.Activity = 1.0
                $amount = Get-Random -Minimum 1000 -Maximum 50000
                $node.Balance += $amount
                $this.State.TotalFlow += $amount
            }
        }
        
        if ($tick - $this.State.LastSpawn -gt 3) {
            $this.State.LastSpawn = $tick
            foreach ($river in $this.Rivers) {
                if ($river.Flow -gt 0.3) {
                    $this.Particles.Add(@{
                        X = $river.FromNode.X; Y = $river.FromNode.Y
                        TargetX = $river.ToNode.X; TargetY = $river.ToNode.Y
                        Progress = 0; Speed = 0.02 + (Get-Random -Minimum 0 -Maximum 10) / 100.0
                        Size = 5 + (Get-Random -Minimum 0 -Maximum 5); Life = 100
                        Type = if ((Get-Random -Minimum 0 -Maximum 10) -gt 6) { "Dollar" } else { "Particle" }
                        River = $river
                    }) | Out-Null
                    $river.FromNode.Activity = 0.8
                }
            }
        }
        
        $toRemove = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $this.Particles.Count; $i++) {
            $p = $this.Particles[$i]
            $p.Progress += $p.Speed
            
            if ($p.Progress -ge 1.0) {
                $p.River.ToNode.Activity = 1.0
                [void]$toRemove.Add($i)
                continue
            }
            
            $t = $p.Progress
            $x1 = $p.River.FromNode.X; $y1 = $p.River.FromNode.Y
            $x2 = $p.TargetX; $y2 = $p.TargetY
            $midX = ($x1 + $x2) / 2; $midY = ($y1 + $y2) / 2
            $offsetX = ($y2 - $y1) * 0.2; $offsetY = ($x1 - $x2) * 0.2
            
            $t2 = $t * $t; $t3 = $t2 * $t
            $mt = 1 - $t; $mt2 = $mt * $mt; $mt3 = $mt2 * $mt
            
            $p.X = $mt3 * $x1 + 3 * $mt2 * $t * ($midX + $offsetX) + 3 * $mt * $t2 * ($midX + $offsetX) + $t3 * $x2
            $p.Y = $mt3 * $y1 + 3 * $mt2 * $t * ($midY + $offsetY) + 3 * $mt * $t2 * ($midY + $offsetY) + $t3 * $y2
            
            $p.Life -= 0.5
            if ($p.Life -le 0) { [void]$toRemove.Add($i) }
        }
        
        for ($i = $toRemove.Count - 1; $i -ge 0; $i--) {
            $this.Particles.RemoveAt($toRemove[$i])
        }
        
        while ($this.Particles.Count -gt 100) {
            $this.Particles.RemoveAt(0)
        }
        
        if ($this.Canvas) { $this.Canvas.Invalidate() }
    }

    [void] OnStop() {
        Write-Host " 🛑 [Show21] Cleaning up Money River..." -ForegroundColor Yellow
        $this.Nodes.Clear()
        $this.Rivers.Clear()
        $this.Particles.Clear()
        if ($this.Canvas) { $this.Canvas.Remove_Paint($null) }
        $this.Panel.Controls.Clear()
        $this.State.TotalFlow = 0
        $this.State.TickCount = 0
        $this.State.LastSpawn = 0
        Write-Host " ✅ [Show21] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] CreateCanvas() {
        $this.Canvas = New-Object System.Windows.Forms.Panel
        $this.Canvas.Dock = "Fill"
        $this.Canvas.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 25)
        $prop = $this.Canvas.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Canvas, $true, $null) }
        $this.Panel.Controls.Add($this.Canvas)
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Canvas.Add_Paint({
            param($sender, $e)
            $self.RenderFrame($e.Graphics, $sender.Width, $sender.Height)
        }.GetNewClosure())
    }

    hidden [void] InitializeFinancialNetwork() {
        $nodeTypes = @(
            @{Name="Central Bank"; X=100; Y=200; Size=30; Type="Bank"; Color=[System.Drawing.Color]::Gold},
            @{Name="Commerce HQ"; X=300; Y=150; Size=25; Type="Bank"; Color=[System.Drawing.Color]::Yellow},
            @{Name="Branch A"; X=500; Y=100; Size=20; Type="Branch"; Color=[System.Drawing.Color]::Orange},
            @{Name="Branch B"; X=500; Y=250; Size=20; Type="Branch"; Color=[System.Drawing.Color]::Orange},
            @{Name="Corporate 1"; X=250; Y=300; Size=18; Type="Business"; Color=[System.Drawing.Color]::LightGreen},
            @{Name="Corporate 2"; X=400; Y=320; Size=18; Type="Business"; Color=[System.Drawing.Color]::LightGreen},
            @{Name="Customers"; X=150; Y=80; Size=15; Type="Customer"; Color=[System.Drawing.Color]::LightBlue},
            @{Name="Investments"; X=550; Y=200; Size=22; Type="Investment"; Color=[System.Drawing.Color]::LightGoldenrodYellow}
        )
        
        foreach ($nodeData in $nodeTypes) {
            [void]$this.Nodes.Add(@{
                Name = $nodeData.Name; X = $nodeData.X; Y = $nodeData.Y
                OriginalX = $nodeData.X; OriginalY = $nodeData.Y
                Size = $nodeData.Size; Type = $nodeData.Type; Color = $nodeData.Color
                Pulse = 0; Activity = 0; Balance = Get-Random -Minimum 100000 -Maximum 9999999
            })
        }
        
        $connections = @(
            @{From=0; To=1; Width=8}, @{From=1; To=2; Width=5}, @{From=1; To=3; Width=5},
            @{From=1; To=4; Width=4}, @{From=1; To=5; Width=4}, @{From=6; To=1; Width=6},
            @{From=1; To=7; Width=6}, @{From=4; To=0; Width=3}, @{From=5; To=7; Width=3}
        )
        
        foreach ($conn in $connections) {
            $fromNode = $this.Nodes[$conn.From]
            $toNode = $this.Nodes[$conn.To]
            [void]$this.Rivers.Add(@{
                FromNode = $fromNode; ToNode = $toNode; Width = $conn.Width
                Flow = 0; TargetFlow = 0; Particles = [System.Collections.ArrayList]::new()
            })
        }
    }

    hidden [void] RenderFrame([System.Drawing.Graphics]$g, [int]$w, [int]$h) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(0, $h),
            [System.Drawing.Color]::FromArgb(10, 15, 25), [System.Drawing.Color]::FromArgb(5, 10, 20)
        )
        $g.FillRectangle($bgBrush, 0, 0, $w, $h)
        $bgBrush.Dispose()
        
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(20, 100, 100, 100), 1)
        for ($i = 0; $i -lt 20; $i++) {
            $x = $i * 30; $g.DrawLine($gridPen, $x, 0, $x, $h)
            $y = $i * 30; $g.DrawLine($gridPen, 0, $y, $w, $y)
        }
        $gridPen.Dispose()
        
        foreach ($river in $this.Rivers) {
            $x1 = $river.FromNode.X; $y1 = $river.FromNode.Y
            $x2 = $river.ToNode.X; $y2 = $river.ToNode.Y
            $midX = ($x1 + $x2) / 2; $midY = ($y1 + $y2) / 2
            $offsetX = ($y2 - $y1) * 0.2; $offsetY = ($x1 - $x2) * 0.2
            
            $flowIntensity = [math]::Min(255, $river.Flow * 50)
            
            if ($flowIntensity -gt 30) {
                $glowAlpha = [math]::Max(20, [math]::Min(255, $flowIntensity / 3))
                $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, 255, 215, 0)
                $glowWidth = $river.Width * 3
                $glowPen = New-Object System.Drawing.Pen($glowColor, $glowWidth)
                $glowPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
                $glowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
                
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddBezier($x1, $y1, $midX + $offsetX, $midY + $offsetY, $midX + $offsetX, $midY + $offsetY, $x2, $y2)
                $g.DrawPath($glowPen, $path)
                $path.Dispose(); $glowPen.Dispose()
            }
            
            $riverColor = [System.Drawing.Color]::FromArgb([math]::Max(100, $flowIntensity), 255, 200, 0)
            $riverPen = New-Object System.Drawing.Pen($riverColor, $river.Width)
            $riverPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
            $riverPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
            
            $path2 = New-Object System.Drawing.Drawing2D.GraphicsPath
            $path2.AddBezier($x1, $y1, $midX + $offsetX, $midY + $offsetY, $midX + $offsetX, $midY + $offsetY, $x2, $y2)
            $g.DrawPath($riverPen, $path2)
            $path2.Dispose(); $riverPen.Dispose()
        }
        
        foreach ($particle in $this.Particles) {
            $alpha = [math]::Min(255, $particle.Life * 3)
            $size = $particle.Size
            
            if ($particle.Type -eq "Dollar") {
                $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha/4, 255, 215, 0))
                $g.FillEllipse($glowBrush, $particle.X - $size*1.5, $particle.Y - $size*1.5, $size*3, $size*3)
                $glowBrush.Dispose()
                
                $coinBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 215, 0))
                $g.FillEllipse($coinBrush, $particle.X - $size, $particle.Y - $size, $size*2, $size*2)
                $coinBrush.Dispose()
                
                $fontSize = [math]::Max(4, $size / 2)
                $font = New-Object System.Drawing.Font("Arial", $fontSize, [System.Drawing.FontStyle]::Bold)
                $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 0, 100, 0))
                $text = "$"; $textSize = $g.MeasureString($text, $font)
                $g.DrawString($text, $font, $textBrush, $particle.X - $textSize.Width/2, $particle.Y - $textSize.Height/2)
                $font.Dispose(); $textBrush.Dispose()
            } else {
                $particleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 220, 100))
                $g.FillEllipse($particleBrush, $particle.X - $size/2, $particle.Y - $size/2, $size, $size)
                $particleBrush.Dispose()
            }
        }
        
        foreach ($node in $this.Nodes) {
            $size = $node.Size + ($node.Pulse * 3)
            
            if ($node.Activity -gt 0.2) {
                $glowSize = $size * 2
                $alpha = [math]::Min(200, $node.Activity * 255)
                $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha/3, 255, 215, 0))
                $g.FillEllipse($glowBrush, $node.X - $glowSize, $node.Y - $glowSize, $glowSize*2, $glowSize*2)
                $glowBrush.Dispose()
            }
            
            $nodePath = New-Object System.Drawing.Drawing2D.GraphicsPath
            $nodePath.AddEllipse($node.X - $size, $node.Y - $size, $size*2, $size*2)
            $gradientBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($nodePath)
            $gradientBrush.CenterColor = $node.Color
            $gradientBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(200, $node.Color.R/2, $node.Color.G/2, $node.Color.B/2))
            $g.FillPath($gradientBrush, $nodePath)
            $gradientBrush.Dispose()
            $nodePath.Dispose()
            
            $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), 2)
            $g.DrawEllipse($borderPen, $node.X - $size, $node.Y - $size, $size*2, $size*2)
            $borderPen.Dispose()
            
            $font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $textSize = $g.MeasureString($node.Name, $font)
            $g.DrawString($node.Name, $font, $textBrush, $node.X - $textSize.Width/2, $node.Y - $size - 15)
            $font.Dispose()
            $textBrush.Dispose()
            
            $balanceText = "$" + [math]::Round($node.Balance / 1000) + "K"
            $balanceFont = New-Object System.Drawing.Font("Consolas", 7)
            $balanceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 255, 255, 100))
            $balanceSize = $g.MeasureString($balanceText, $balanceFont)
            $g.DrawString($balanceText, $balanceFont, $balanceBrush, $node.X - $balanceSize.Width/2, $node.Y + $size + 5)
            $balanceFont.Dispose()
            $balanceBrush.Dispose()
        }
        
        $counterFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $counterBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 215, 0))
        $flowText = "✨ Total Flow: $" + [math]::Round($this.State.TotalFlow / 1000) + "K"
        $g.DrawString($flowText, $counterFont, $counterBrush, 10, 10)
        $counterFont.Dispose()
        $counterBrush.Dispose()
        
        $infoFont = New-Object System.Drawing.Font("Consolas", 8)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 255, 255, 255))
        $info = "Nodes: $($this.Nodes.Count) | Rivers: $($this.Rivers.Count) | Particles: $($this.Particles.Count)"
        $g.DrawString($info, $infoFont, $infoBrush, 10, $h - 25)
        $infoFont.Dispose()
        $infoBrush.Dispose()
    }
}

# Legacy compatibility
function Stop-Show21 {
    Write-Host "🛑 [Show21] Stop called (v3)" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show21")) {
        $Global:ShowManager.Shows["show21"].Stop()
    }
}

Write-Host "✅ COMPLETE Show21 v3 - Copy/Paste READY for ISE!" -ForegroundColor Green

 