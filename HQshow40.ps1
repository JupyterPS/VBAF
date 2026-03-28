# ===============================
# HQ Show40 — PROTEIN FOLDING
# Novo Nordisk: GM3 Architecture
# ===============================

Write-Host "`n=> _____ HQshow40 (Protein Folding GM3) ___________ <=`n" -ForegroundColor Cyan

class Show40 : BaseShow {
    hidden [System.Collections.ArrayList] $Proteins
    hidden [System.Collections.ArrayList] $FoldingEffects
    hidden [System.Collections.ArrayList] $OrbitingParticles
    hidden [hashtable] $State
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    
    Show40([System.Windows.Forms.Panel]$panel) : base("show40", $panel) {
        $this.State = @{
            TickCount = 0
            TickerOffset = 0
        }
        
        $this.Proteins = [System.Collections.ArrayList]::new()
        $this.FoldingEffects = [System.Collections.ArrayList]::new()
        $this.OrbitingParticles = [System.Collections.ArrayList]::new()
        
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 50
        
        $self = $this
        $this.AnimationTimer.Add_Tick({ $self.OnUpdate() }.GetNewClosure())
    }
    
    [void] OnStart() {
        Write-Host "[Show40] Protein Folding initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 20)
        
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        $this.InitializeProteins()
        $this.InitializeOrbitingParticles()
        $this.SetupEvents()
        $this.AnimationTimer.Start()
        
        Write-Host "  ✅ [Show40] Ready with $($this.Proteins.Count) proteins!" -ForegroundColor Green
    }
    
    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        # Update ticker
        $this.State.TickerOffset += 2
        if ($this.State.TickerOffset -gt 1200) { $this.State.TickerOffset = 0 }
        
        # Update proteins
        foreach ($protein in $this.Proteins) {
            $protein.Rotation += $protein.RotationSpeed
            if ($protein.Rotation -gt 6.28) { $protein.Rotation -= 6.28 }
            
            if ($protein.Folding) {
                $protein.FoldProgress += 0.01
                
                if ($protein.FoldProgress -ge $protein.TargetFold) {
                    $protein.Folding = $false
                    $protein.Stability = 100
                    
                    [void]$this.FoldingEffects.Add(@{
                        X = $protein.CenterX; Y = $protein.CenterY
                        Size = 40; Life = 80
                    })
                }
            }
            
            # Update amino acids
            foreach ($aa in $protein.AminoChain) {
                if ($protein.Folding) {
                    $aa.CurrentX += ($aa.TargetX - $aa.CurrentX) * 0.05
                    $aa.CurrentY += ($aa.TargetY - $aa.CurrentY) * 0.05
                } else {
                    $wobble = [Math]::Sin($tick * 0.05 + $aa.Index) * 2
                    $aa.CurrentX = $aa.TargetX + $wobble
                    $aa.CurrentY = $aa.TargetY + $wobble
                }
            }
            
            # Stability fluctuation
            if (-not $protein.Folding -and $tick % 100 -eq 0) {
                $protein.Stability += (Get-Random -Minimum -3 -Maximum 3)
                $protein.Stability = [Math]::Max(70, [Math]::Min(100, $protein.Stability))
            }
            
            # Restart folding
            if (-not $protein.Folding -and $tick % 500 -eq 0) {
                $protein.Folding = $true
                $protein.FoldProgress = 0
                $protein.Stability = 0
                
                foreach ($aa in $protein.AminoChain) {
                    $angle = (Get-Random) * [Math]::PI * 2
                    $radius = Get-Random -Minimum 80 -Maximum 120
                    $aa.CurrentX = $radius * [Math]::Cos($angle)
                    $aa.CurrentY = $radius * [Math]::Sin($angle)
                }
            }
        }
        
        # Update folding effects
        $activeEffects = [System.Collections.ArrayList]::new()
        foreach ($effect in $this.FoldingEffects) {
            $effect.Life -= 1
            $effect.Size += 2
            if ($effect.Life -gt 0) { [void]$activeEffects.Add($effect) }
        }
        $this.FoldingEffects.Clear()
        foreach ($e in $activeEffects) { [void]$this.FoldingEffects.Add($e) }
        
        # Update orbiting particles
        $this.UpdateOrbitingParticles($tick)
        
        $this.Panel.Invalidate()
    }
    
    [void] OnStop() {
        Write-Host "  🛑 [Show40] Cleanup..." -ForegroundColor Yellow
        
        if ($this.AnimationTimer) { $this.AnimationTimer.Stop() }
        
        $this.Proteins.Clear()
        $this.FoldingEffects.Clear()
        $this.OrbitingParticles.Clear()
        
        Write-Host "  ✅ [Show40] Stopped" -ForegroundColor Green
    }
    
    hidden [void] InitializeProteins() {
        $proteinData = @(
            @{Name="Insulin"; AminoCount=51; CenterX=150; CenterY=180; Type="Hormone"; Color=[System.Drawing.Color]::FromArgb(100, 200, 255)},
            @{Name="Glucagon"; AminoCount=29; CenterX=350; CenterY=150; Type="Peptide"; Color=[System.Drawing.Color]::FromArgb(255, 150, 100)},
            @{Name="GLP-1"; AminoCount=37; CenterX=500; CenterY=200; Type="Hormone"; Color=[System.Drawing.Color]::FromArgb(150, 255, 100)}
        )
        
        foreach ($data in $proteinData) {
            $aminoChain = [System.Collections.ArrayList]::new()
            $aaTypes = @("Gly", "Ala", "Val", "Leu", "Ile", "Pro", "Phe", "Tyr", "Trp", "Ser")
            
            for ($i = 0; $i -lt $data.AminoCount; $i++) {
                $angle = ($i * 360 / $data.AminoCount) * [Math]::PI / 180
                $radius = 60 + ($i % 3) * 10
                $aaType = $aaTypes[$i % $aaTypes.Count]
                
                $aaColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
                if ($aaType -in @("Ser","Thr","Asn","Gln")) { $aaColor = [System.Drawing.Color]::FromArgb(100, 200, 255) }
                elseif ($aaType -in @("Phe","Tyr","Trp")) { $aaColor = [System.Drawing.Color]::FromArgb(255, 200, 100) }
                
                [void]$aminoChain.Add(@{
                    Type = $aaType; Index = $i
                    LocalX = $radius * [Math]::Cos($angle)
                    LocalY = $radius * [Math]::Sin($angle)
                    CurrentX = 0; CurrentY = 0
                    TargetX = $radius * [Math]::Cos($angle)
                    TargetY = $radius * [Math]::Sin($angle)
                    Color = $aaColor; Size = 6; Charge = 0
                })
            }
            
            [void]$this.Proteins.Add(@{
                Name = $data.Name; Type = $data.Type
                CenterX = $data.CenterX; CenterY = $data.CenterY; Color = $data.Color
                AminoChain = $aminoChain; FoldProgress = 0; TargetFold = 1.0
                Stability = 0; Rotation = 0; RotationSpeed = 0.01
                Energy = 100; Folding = $true
            })
        }
    }
    
    hidden [void] InitializeOrbitingParticles() {
        foreach ($protein in $this.Proteins) {
            for ($ring = 0; $ring -lt 4; $ring++) {
                $radius = 40 + ($ring * 20)
                $particleCount = 6 + ($ring * 2)
                
                for ($i = 0; $i -lt $particleCount; $i++) {
                    $angle = ($i * 360 / $particleCount) * [Math]::PI / 180
                    
                    $direction = 1
                    if ($i % 2 -eq 1) { $direction = -1 }
                    
                    $speed = (0.02 + ($ring * 0.01)) * $direction
                    $randomSize = Get-Random -Minimum 0 -Maximum 3
                    
                    [void]$this.OrbitingParticles.Add(@{
                        ProteinIndex = $this.Proteins.IndexOf($protein)
                        Radius = $radius
                        Angle = $angle
                        Speed = $speed
                        Size = 4 + $randomSize
                        Color = $protein.Color
                        TrailLength = 8
                        Trail = [System.Collections.ArrayList]::new()
                    })
                }
            }
        }
    }
    
    hidden [void] UpdateOrbitingParticles([int]$tick) {
        foreach ($particle in $this.OrbitingParticles) {
            $protein = $this.Proteins[$particle.ProteinIndex]
            
            $particle.Angle += $particle.Speed
            if ($particle.Angle -gt 6.28) { $particle.Angle -= 6.28 }
            if ($particle.Angle -lt 0) { $particle.Angle += 6.28 }
            
            $x = $protein.CenterX + ($particle.Radius * [Math]::Cos($particle.Angle))
            $y = $protein.CenterY + ($particle.Radius * [Math]::Sin($particle.Angle))
            
            [void]$particle.Trail.Add(@{ X = $x; Y = $y; Life = $particle.TrailLength })
            
            $activeTrail = [System.Collections.ArrayList]::new()
            foreach ($trailPoint in $particle.Trail) {
                $trailPoint.Life -= 1
                if ($trailPoint.Life -gt 0) { [void]$activeTrail.Add($trailPoint) }
            }
            $particle.Trail.Clear()
            foreach ($point in $activeTrail) { [void]$particle.Trail.Add($point) }
            
            if ($tick % 60 -eq 0) {
                $particle.Radius += (Get-Random -Minimum -5 -Maximum 5)
                $particle.Radius = [Math]::Max(30, [Math]::Min(120, $particle.Radius))
            }
        }
    }
    
    hidden [void] SetupEvents() {
        $self = $this
        
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderProteinFolding($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }
    
    hidden [void] RenderProteinFolding([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Background
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(10, 15, 20), [System.Drawing.Color]::FromArgb(20, 25, 35)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Grid
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(20, 100, 150, 200), 1)
        for ($i = 0; $i -lt 40; $i++) {
            $x = $i * 20
            $g.DrawLine($gridPen, $x, 0, $x, $height)
            $y = $i * 20
            $g.DrawLine($gridPen, 0, $y, $width, $y)
        }
        $gridPen.Dispose()
        
        # Folding effects
        foreach ($effect in $this.FoldingEffects) {
            $alpha = [math]::Min(255, $effect.Life * 4)
            
            for ($r = 0; $r -lt 4; $r++) {
                $ringSize = $effect.Size + ($r * 10)
                $ringAlpha = [int]($alpha / (1 + $r * 0.5))
                $ringColor = [System.Drawing.Color]::FromArgb($ringAlpha, 100, 255, 200)
                $ringPen = New-Object System.Drawing.Pen($ringColor, 2)
                $g.DrawEllipse($ringPen, $effect.X - $ringSize/2, $effect.Y - $ringSize/2, $ringSize, $ringSize)
                $ringPen.Dispose()
            }
        }
        
        # Draw proteins
        foreach ($protein in $this.Proteins) {
            $this.DrawProtein($g, $protein)
        }
        
        # Draw orbiting particles
        $this.DrawOrbitingParticles($g)
        
        # Ticker
        $this.DrawTicker($g, $width, $height)
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 100, 200, 255))
        $titleSize = $g.MeasureString("✨ PROTEIN FOLDING", $titleFont)
        $g.DrawString("✨ PROTEIN FOLDING", $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
    
    hidden [void] DrawProtein([System.Drawing.Graphics]$g, [hashtable]$protein) {
        $cx = $protein.CenterX
        $cy = $protein.CenterY
        $rot = $protein.Rotation
        
        # Glow
        $glowSize = 150
        $glowAlpha = [int](30 + ($protein.Stability * 0.5))
        $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($glowAlpha, $protein.Color.R, $protein.Color.G, $protein.Color.B))
        $g.FillEllipse($glowBrush, $cx - $glowSize/2, $cy - $glowSize/2, $glowSize, $glowSize)
        $glowBrush.Dispose()
        
        # Backbone
        for ($i = 0; $i -lt $protein.AminoChain.Count - 1; $i++) {
            $aa1 = $protein.AminoChain[$i]
            $aa2 = $protein.AminoChain[$i + 1]
            
            $x1 = $cx + ($aa1.CurrentX * [Math]::Cos($rot) - $aa1.CurrentY * [Math]::Sin($rot))
            $y1 = $cy + ($aa1.CurrentX * [Math]::Sin($rot) + $aa1.CurrentY * [Math]::Cos($rot))
            $x2 = $cx + ($aa2.CurrentX * [Math]::Cos($rot) - $aa2.CurrentY * [Math]::Sin($rot))
            $y2 = $cy + ($aa2.CurrentX * [Math]::Sin($rot) + $aa2.CurrentY * [Math]::Cos($rot))
            
            $bondPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 150, 150, 150), 2)
            $g.DrawLine($bondPen, $x1, $y1, $x2, $y2)
            $bondPen.Dispose()
        }
        
        # Amino acids
        foreach ($aa in $protein.AminoChain) {
            $x = $cx + ($aa.CurrentX * [Math]::Cos($rot) - $aa.CurrentY * [Math]::Sin($rot))
            $y = $cy + ($aa.CurrentX * [Math]::Sin($rot) + $aa.CurrentY * [Math]::Cos($rot))
            
            $aaBrush = New-Object System.Drawing.SolidBrush($aa.Color)
            $g.FillEllipse($aaBrush, $x - $aa.Size, $y - $aa.Size, $aa.Size * 2, $aa.Size * 2)
            $aaBrush.Dispose()
            
            $aaPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 255, 255, 255), 1)
            $g.DrawEllipse($aaPen, $x - $aa.Size, $y - $aa.Size, $aa.Size * 2, $aa.Size * 2)
            $aaPen.Dispose()
        }
        
        # Label
        $nameFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $nameBrush = New-Object System.Drawing.SolidBrush($protein.Color)
        $nameSize = $g.MeasureString($protein.Name, $nameFont)
        
        $labelBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
        $g.FillRectangle($labelBg, $cx - $nameSize.Width/2 - 5, $cy - 100, $nameSize.Width + 10, $nameSize.Height + 4)
        $labelBg.Dispose()
        
        $g.DrawString($protein.Name, $nameFont, $nameBrush, $cx - $nameSize.Width/2, $cy - 98)
        $nameFont.Dispose()
        $nameBrush.Dispose()
        
        # Stability bar
        $stabX = $cx - 50; $stabY = $cy + 100; $stabWidth = 100; $stabHeight = 8
        
        $stabBgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 50, 50, 50))
        $g.FillRectangle($stabBgBrush, $stabX, $stabY, $stabWidth, $stabHeight)
        $stabBgBrush.Dispose()
        
        $stabFill = ($protein.Stability / 100) * $stabWidth
        $stabColor = if ($protein.Stability -gt 80) { [System.Drawing.Color]::FromArgb(100, 255, 100) }
                     elseif ($protein.Stability -gt 50) { [System.Drawing.Color]::FromArgb(255, 200, 100) }
                     else { [System.Drawing.Color]::FromArgb(255, 150, 100) }
        $stabBrush = New-Object System.Drawing.SolidBrush($stabColor)
        $g.FillRectangle($stabBrush, $stabX, $stabY, $stabFill, $stabHeight)
        $stabBrush.Dispose()
        
        $stabLabelFont = New-Object System.Drawing.Font("Consolas", 8)
        $stabLabelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 200, 200))
        $g.DrawString("Stability: $([int]$protein.Stability)%", $stabLabelFont, $stabLabelBrush, $stabX, $stabY + 12)
        $stabLabelFont.Dispose()
        $stabLabelBrush.Dispose()
    }
    
    hidden [void] DrawOrbitingParticles([System.Drawing.Graphics]$g) {
        foreach ($particle in $this.OrbitingParticles) {
            $protein = $this.Proteins[$particle.ProteinIndex]
            
            # Trail
            foreach ($trailPoint in $particle.Trail) {
                $alpha = [int](($trailPoint.Life / [double]$particle.TrailLength) * 150)
                $trailColor = [System.Drawing.Color]::FromArgb($alpha, $particle.Color.R, $particle.Color.G, $particle.Color.B)
                $trailBrush = New-Object System.Drawing.SolidBrush($trailColor)
                $trailSize = $particle.Size * 0.6
                $g.FillEllipse($trailBrush, $trailPoint.X - $trailSize/2, $trailPoint.Y - $trailSize/2, $trailSize, $trailSize)
                $trailBrush.Dispose()
            }
            
            # Particle
            $x = $protein.CenterX + ($particle.Radius * [Math]::Cos($particle.Angle))
            $y = $protein.CenterY + ($particle.Radius * [Math]::Sin($particle.Angle))
            
            $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 255, 255, 255))
            $glowSize = $particle.Size + 4
            $g.FillEllipse($glowBrush, $x - $glowSize/2, $y - $glowSize/2, $glowSize, $glowSize)
            $glowBrush.Dispose()
            
            $particleBrush = New-Object System.Drawing.SolidBrush($particle.Color)
            $g.FillEllipse($particleBrush, $x - $particle.Size/2, $y - $particle.Size/2, $particle.Size, $particle.Size)
            $particleBrush.Dispose()
        }
    }
    
    hidden [void] DrawTicker([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $tickerHeight = 35
        $tickerY = $height - $tickerHeight - 5
        
        $tickerBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
        $g.FillRectangle($tickerBg, 0, $tickerY, $width, $tickerHeight)
        $tickerBg.Dispose()
        
        $tickerBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 100, 200, 255), 2)
        $g.DrawRectangle($tickerBorder, 0, $tickerY, $width - 1, $tickerHeight - 1)
        $tickerBorder.Dispose()
        
        $tickerText = "  PROTEINS: "
        foreach ($prot in $this.Proteins) {
            $status = if ($prot.Folding) { "Folding" } else { "Folded" }
            $tickerText += "$($prot.Name) [$($prot.Type), $($prot.AminoChain.Count) AA, Stab: $([int]$prot.Stability)%, $status] • "
        }
        $tickerText += "   |   "
        
        $tickerFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $tickerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 200, 255))
        
        $textSize = $g.MeasureString($tickerText, $tickerFont)
        $tickerX = $width - $this.State.TickerOffset
        
        $g.DrawString($tickerText, $tickerFont, $tickerBrush, $tickerX, $tickerY + 8)
        $g.DrawString($tickerText, $tickerFont, $tickerBrush, $tickerX + $textSize.Width, $tickerY + 8)
        
        $tickerFont.Dispose()
        $tickerBrush.Dispose()
    }
}

function Stop-Show40 {
    Write-Host "🛑 [Show40] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show40")) {
        $Global:ShowManager.Shows["show40"].Stop()
    }
}

Write-Host "✅ Show40 - Protein Folding GM3 loaded!" -ForegroundColor Green
Write-Host "🧬 With fantastic orbiting particles inside!" -ForegroundColor Cyan
