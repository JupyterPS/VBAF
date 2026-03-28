# ====================================================
# HQshow2.ps1 — Wave Interference & Fourier Theater v3
# Converted to Game Machine Architecture
# ZERO VISUAL CHANGES - Looks identical to V1
# ====================================================
Write-Host "`n=> _____ HQshow2 (Wave Interference v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show2 - Inherits from BaseShow
# ============================================
class Show2 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [hashtable[]] $FourierHarmonics
    
    # ========================================
    # Constructor
    # ========================================
    Show2([System.Windows.Forms.Panel]$panel) : base("show2", $panel) {
        # Initialize state (replaces $Global:Show2Data)
        $this.State = @{
            Source1 = @{X=200; Y=200; Phase=0; Frequency=0.15; Amplitude=40}
            Source2 = @{X=450; Y=200; Phase=0; Frequency=0.15; Amplitude=40}
            WaveSpeed = 2.0
            TimeStep = 0
            Act = 1
            ActTimer = 0
        }
        $this.FourierHarmonics = @()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host " 🌊 [Show2] Initializing Wave Interference & Fourier Theater..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 30)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Update ticker messages
        $Show2Messages = @(
            "🌊 WAVE INTERFERENCE & FOURIER THEATER",
            "⚛️ Watch interference patterns form from two sources",
            "📊 Fourier decomposition reveals hidden harmonics",
            "📦 Wave packets demonstrate group velocity",
            "🎸 Standing waves show resonance phenomena"
        )
        $Global:messages = $Show2Messages
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        # Initialize Fourier harmonics
        $this.FourierHarmonics = @()
        for ($n = 1; $n -le 7; $n++) {
            $amplitude = 4.0 / ($n * [math]::PI)
            $this.FourierHarmonics += @{
                N = $n
                Amplitude = $amplitude
                Frequency = $n * 0.1
                Phase = 0
                Active = ($n -le 3)
            }
        }
        
        Write-Host " ✅ [Show2] Wave Interference & Fourier Theater ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Update animation state (replaces timer tick)
        $this.State.TimeStep += 0.1
        $this.State.ActTimer += 1
        
        # Update source phases
        $this.State.Source1.Phase += $this.State.Source1.Frequency
        $this.State.Source2.Phase += $this.State.Source2.Frequency
        
        # Update Fourier harmonics
        foreach ($h in $this.FourierHarmonics) {
            $h.Phase += $h.Frequency
            if ($h.Phase -gt 6.28) { $h.Phase -= 6.28 }
        }
        
        # Act transitions
        if ($this.State.ActTimer -gt 250) {
            $this.State.Act++
            if ($this.State.Act -gt 4) { $this.State.Act = 1 }
            $this.State.ActTimer = 0
            
            if ($this.State.Act -eq 3) {
                $this.State.TimeStep = 0
            }
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host " 🛑 [Show2] Cleaning up..." -ForegroundColor Yellow
        
        # Clear Fourier harmonics
        $this.FourierHarmonics = @()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.ActTimer = 0
        $this.State.Act = 1
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        Write-Host " ✅ [Show2] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Setup paint event
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderScene($s, $e.Graphics)
        }.GetNewClosure())
    }
    
    # Main render method (EXACT V1 LOGIC)
    hidden [void] RenderScene([object]$sender, [System.Drawing.Graphics]$g) {
        $width = $sender.Width
        $height = $sender.Height
        
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Dark background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(10, 10, 30),
            [System.Drawing.Color]::FromArgb(20, 15, 40)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        $currentAct = $this.State.Act
        $centerY = $height / 2
        
        # === ACT 1: TWO-SOURCE INTERFERENCE ===
        if ($currentAct -eq 1) {
            $s1 = $this.State.Source1
            $s2 = $this.State.Source2
            $lambda = 30
            $k = 2 * [math]::PI / $lambda
            
            # Draw 2D interference pattern
            $gridSize = 8
            for ($x = 0; $x -lt $width; $x += $gridSize) {
                for ($y = 60; $y -lt $height - 40; $y += $gridSize) {
                    $r1 = [math]::Sqrt([math]::Pow($x - $s1.X, 2) + [math]::Pow($y - $s1.Y, 2))
                    $r2 = [math]::Sqrt([math]::Pow($x - $s2.X, 2) + [math]::Pow($y - $s2.Y, 2))
                    
                    $wave1 = $s1.Amplitude * [math]::Sin($k * $r1 - $s1.Phase)
                    $wave2 = $s2.Amplitude * [math]::Sin($k * $r2 - $s2.Phase)
                    
                    $amplitude = $wave1 + $wave2
                    $intensity = [math]::Min(255, [math]::Max(0, 128 + $amplitude * 2))
                    $color = [System.Drawing.Color]::FromArgb(150, $intensity, $intensity, 255)
                    $brush = New-Object System.Drawing.SolidBrush($color)
                    $g.FillRectangle($brush, $x, $y, $gridSize, $gridSize)
                    $brush.Dispose()
                }
            }
            
            # Draw sources
            $sourceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 100, 100))
            $g.FillEllipse($sourceBrush, $s1.X - 8, $s1.Y - 8, 16, 16)
            $g.FillEllipse($sourceBrush, $s2.X - 8, $s2.Y - 8, 16, 16)
            $sourceBrush.Dispose()
            
            # Math overlay
            $mathFont = New-Object System.Drawing.Font("Consolas", 10)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString("Ψ(r,t) = A₁sin(kr₁-ωt) + A₂sin(kr₂-ωt)", $mathFont, $mathBrush, 20, $height - 30)
            $g.DrawString("Path difference: Δ = |r₁ - r₂|", $mathFont, $mathBrush, 20, $height - 50)
            $g.DrawString("Constructive: Δ = nλ  |  Destructive: Δ = (n+½)λ", $mathFont, $mathBrush, 20, $height - 70)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        }
        
        # === ACT 2: FOURIER SYNTHESIS ===
        elseif ($currentAct -eq 2) {
            # Draw individual harmonics
            $yOffset = 80
            $harmCount = 0
            foreach ($harmonic in $this.FourierHarmonics) {
                if ($harmonic.Active -and $harmCount -lt 4) {
                    $hPoints = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
                    for ($xi = 0; $xi -lt $width; $xi += 3) {
                        $ti = $xi / 50.0
                        $yi = $yOffset + $harmonic.Amplitude * 15 * [math]::Sin($harmonic.N * $ti + $harmonic.Phase)
                        $hPoints.Add((New-Object System.Drawing.Point($xi, [int]$yi)))
                    }
                    
                    if ($hPoints.Count -gt 1) {
                        $hArray = $hPoints.ToArray()
                        $hColor = [System.Drawing.Color]::FromArgb(180, 100 + $harmonic.N * 20, 150, 255 - $harmonic.N * 20)
                        $hPen = New-Object System.Drawing.Pen($hColor, 1.5)
                        $g.DrawLines($hPen, $hArray)
                        $hPen.Dispose()
                    }
                    
                    $yOffset += 30
                    $harmCount++
                }
            }
            
            # Draw synthesized wave
            $sList = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            for ($xs = 0; $xs -lt $width; $xs += 2) {
                $ts = $xs / 50.0
                $ys = 0
                foreach ($harmonic in $this.FourierHarmonics) {
                    if ($harmonic.Active) {
                        $ys += $harmonic.Amplitude * 15 * [math]::Sin($harmonic.N * $ts + $harmonic.Phase)
                    }
                }
                $sList.Add((New-Object System.Drawing.Point($xs, [int]($centerY + 50 + $ys))))
            }
            
            if ($sList.Count -gt 1) {
                $sArray = $sList.ToArray()
                for ($i = 0; $i -lt 3; $i++) {
                    $alpha = 50 + ($i * 30)
                    $glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 255, 255, 0), (3 - $i))
                    $g.DrawLines($glowPen, $sArray)
                    $glowPen.Dispose()
                }
            }
            
            # Math overlay
            $mathFont = New-Object System.Drawing.Font("Consolas", 9)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
            $g.DrawString("f(t) = Σ [Aₙ sin(nωt)]", $mathFont, $mathBrush, 20, $height - 60)
            $g.DrawString("Square wave ≈ (4/π)[sin(t) + sin(3t)/3 + sin(5t)/5 + ...]", $mathFont, $mathBrush, 20, $height - 40)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        } 

         # === ACT 3: WAVE PACKET & DISPERSION ===
        elseif ($currentAct -eq 3) {
            $t3 = $this.State.TimeStep
            $k0 = 0.15
            $sigma = 0.05
            
            # Build envelope and carrier
            $envList = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            $carList = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            
            for ($x3 = 0; $x3 -lt $width; $x3 += 2) {
                $xPos3 = ($x3 - $width/2) / 100.0
                $env = 80 * [math]::Exp(-[math]::Pow($xPos3 - $t3 * 0.3, 2) / (2 * $sigma))
                $car = $env * [math]::Cos($k0 * $x3 - $t3 * 2)
                
                $envList.Add((New-Object System.Drawing.Point($x3, [int]($centerY - $env))))
                $envList.Add((New-Object System.Drawing.Point($x3, [int]($centerY + $env))))
                $carList.Add((New-Object System.Drawing.Point($x3, [int]($centerY + $car))))
            }
            
            $envArray = $envList.ToArray()
            $carArray = $carList.ToArray()
            
            # Draw envelope
            $envPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 255, 200, 100), 2)
            $envPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            if ($envArray.Count -gt 2) {
                for ($i = 0; $i -lt ($envArray.Count / 2) - 1; $i++) {
                    $g.DrawLine($envPen, $envArray[$i * 2], $envArray[($i + 1) * 2])
                    $g.DrawLine($envPen, $envArray[$i * 2 + 1], $envArray[($i + 1) * 2 + 1])
                }
            }
            $envPen.Dispose()
            
            # Draw carrier
            if ($carArray.Count -gt 1) {
                $carPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 100, 200, 255), 2)
                $g.DrawLines($carPen, $carArray)
                $carPen.Dispose()
            }
            
            # Math overlay
            $mathFont = New-Object System.Drawing.Font("Consolas", 10)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString("Ψ(x,t) = A·exp(-(x-vₘt)²/2σ²)·cos(kx-ωt)", $mathFont, $mathBrush, 20, $height - 60)
            $g.DrawString("Phase velocity: vₚ = ω/k  |  Group velocity: vₘ = dω/dk", $mathFont, $mathBrush, 20, $height - 40)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        }

# === ACT 3: WAVE PACKET & DISPERSION ===
        elseif ($currentAct -eq 3) {
            $t3 = $this.State.TimeStep
            $k0 = 0.15
            $sigma = 0.05
            
            # Build envelope and carrier
            $envList = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            $carList = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            
            for ($x3 = 0; $x3 -lt $width; $x3 += 2) {
                $xPos3 = ($x3 - $width/2) / 100.0
                $env = 80 * [math]::Exp(-[math]::Pow($xPos3 - $t3 * 0.3, 2) / (2 * $sigma))
                $car = $env * [math]::Cos($k0 * $x3 - $t3 * 2)
                
                $envList.Add((New-Object System.Drawing.Point($x3, [int]($centerY - $env))))
                $envList.Add((New-Object System.Drawing.Point($x3, [int]($centerY + $env))))
                $carList.Add((New-Object System.Drawing.Point($x3, [int]($centerY + $car))))
            }
            
            $envArray = $envList.ToArray()
            $carArray = $carList.ToArray()
            
            # Draw envelope
            $envPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 255, 200, 100), 2)
            $envPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            if ($envArray.Count -gt 2) {
                for ($i = 0; $i -lt ($envArray.Count / 2) - 1; $i++) {
                    $g.DrawLine($envPen, $envArray[$i * 2], $envArray[($i + 1) * 2])
                    $g.DrawLine($envPen, $envArray[$i * 2 + 1], $envArray[($i + 1) * 2 + 1])
                }
            }
            $envPen.Dispose()
            
            # Draw carrier
            if ($carArray.Count -gt 1) {
                $carPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 100, 200, 255), 2)
                $g.DrawLines($carPen, $carArray)
                $carPen.Dispose()
            }
            
            # Math overlay
            $mathFont = New-Object System.Drawing.Font("Consolas", 10)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString("Ψ(x,t) = A·exp(-(x-vₘt)²/2σ²)·cos(kx-ωt)", $mathFont, $mathBrush, 20, $height - 60)
            $g.DrawString("Phase velocity: vₚ = ω/k  |  Group velocity: vₘ = dω/dk", $mathFont, $mathBrush, 20, $height - 40)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        }
        
        # === ACT 4: STANDING WAVES ===
        elseif ($currentAct -eq 4) {
            $L = $width - 100
            $t4 = $this.State.TimeStep
            
            # Draw string boundaries
            $boundaryPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gray, 3)
            $g.DrawLine($boundaryPen, 50, $centerY - 100, 50, $centerY + 100)
            $g.DrawLine($boundaryPen, 50 + $L, $centerY - 100, 50 + $L, $centerY + 100)
            $boundaryPen.Dispose()
            
            # Draw mode 1 (fundamental)
            $w1List = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            for ($x4a = 0; $x4a -le $L; $x4a += 3) {
                $amp4a = 40 * [math]::Sin([math]::PI * $x4a / $L) * [math]::Cos($t4 * 0.5)
                $y4a = $centerY - 80 + $amp4a
                $xPosA = 50 + $x4a
                $yPosA = [int]$y4a
                $w1List.Add((New-Object System.Drawing.Point($xPosA, $yPosA)))
            }
            if ($w1List.Count -gt 1) {
                $w1Color = [System.Drawing.Color]::FromArgb(200, 255, 100, 255)
                $w1Pen = New-Object System.Drawing.Pen($w1Color, 2)
                $g.DrawLines($w1Pen, $w1List.ToArray())
                $w1Pen.Dispose()
                
                $lbl1Font = New-Object System.Drawing.Font("Consolas", 9)
                $lbl1Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $g.DrawString("n=1", $lbl1Font, $lbl1Brush, 55, $centerY - 140)
                $lbl1Font.Dispose()
                $lbl1Brush.Dispose()
            }
            
            # Draw mode 2
            $w2List = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            for ($x4b = 0; $x4b -le $L; $x4b += 3) {
                $amp4b = 40 * [math]::Sin(2 * [math]::PI * $x4b / $L) * [math]::Cos($t4 * 0.5)
                $y4b = $centerY + $amp4b
                $xPosB = 50 + $x4b
                $yPosB = [int]$y4b
                $w2List.Add((New-Object System.Drawing.Point($xPosB, $yPosB)))
            }
            if ($w2List.Count -gt 1) {
                $w2Color = [System.Drawing.Color]::FromArgb(200, 205, 150, 255)
                $w2Pen = New-Object System.Drawing.Pen($w2Color, 2)
                $g.DrawLines($w2Pen, $w2List.ToArray())
                $w2Pen.Dispose()
                
                $lbl2Font = New-Object System.Drawing.Font("Consolas", 9)
                $lbl2Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $g.DrawString("n=2", $lbl2Font, $lbl2Brush, 55, $centerY - 60)
                $lbl2Font.Dispose()
                $lbl2Brush.Dispose()
            }
            
            # Draw mode 3
            $w3List = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            for ($x4c = 0; $x4c -le $L; $x4c += 3) {
                $amp4c = 40 * [math]::Sin(3 * [math]::PI * $x4c / $L) * [math]::Cos($t4 * 0.5)
                $y4c = $centerY + 80 + $amp4c
                $xPosC = 50 + $x4c
                $yPosC = [int]$y4c
                $w3List.Add((New-Object System.Drawing.Point($xPosC, $yPosC)))
            }
            if ($w3List.Count -gt 1) {
                $w3Color = [System.Drawing.Color]::FromArgb(200, 155, 200, 255)
                $w3Pen = New-Object System.Drawing.Pen($w3Color, 2)
                $g.DrawLines($w3Pen, $w3List.ToArray())
                $w3Pen.Dispose()
                
                $lbl3Font = New-Object System.Drawing.Font("Consolas", 9)
                $lbl3Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $g.DrawString("n=3", $lbl3Font, $lbl3Brush, 55, $centerY + 20)
                $lbl3Font.Dispose()
                $lbl3Brush.Dispose()
            }
            
            # Math overlay
            $mathFont = New-Object System.Drawing.Font("Consolas", 10)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
            $g.DrawString("y(x,t) = 2A·sin(kx)·cos(ωt)", $mathFont, $mathBrush, 20, $height - 60)
            $g.DrawString("Resonance frequencies: fₙ = n·v/2L  (n = 1, 2, 3, ...)", $mathFont, $mathBrush, 20, $height - 40)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        }
        
        # === TITLE & ACT INFO ===
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 200, 255))
        
        $actNames = @("", "✨ ACT 1: INTERFERENCE", "✨ ACT 2: FOURIER SYNTHESIS", "✨ ACT 3: WAVE PACKETS", "✨ ACT 4: STANDING WAVES")
        $titleText = "SHOW2: " + $actNames[$currentAct]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show2 {
    Write-Host "[Show2] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show2")) {
        $show = $Global:ShowManager.Shows["show2"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show2] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow2 class loaded (v3)" -ForegroundColor Green

