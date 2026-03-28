
# ===============================
# HQshow57.ps1 — Plasma Waves v3
# Wave Physics Theater: Space Physics & Exotic Matter
# Converted to Game Machine Architecture
# ===============================

Write-Host "`n=> _____ HQshow57 (Plasma Waves v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show57 - Inherits from BaseShow
# ============================================
class Show57 : BaseShow {
    # ========================================
    # Private Properties
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $PlasmaParticles
    hidden [System.Collections.ArrayList] $AuroraRays
    hidden [System.Collections.ArrayList] $SolarWind
    hidden [int] $TickCounter
    
    # ========================================
    # Constructor
    # ========================================
    Show57([System.Windows.Forms.Panel]$panel) : base("show57", $panel) {
        $this.State = @{
            TimeStep = 0
            Act = 1
            ActTimer = 0
            WavePhase = 0
        }
        
        $this.PlasmaParticles = [System.Collections.ArrayList]::new()
        $this.AuroraRays = [System.Collections.ArrayList]::new()
        $this.SolarWind = [System.Collections.ArrayList]::new()
        $this.TickCounter = 0
    }
    
    # ========================================
    # Lifecycle Methods
    # ========================================
    
    [void] OnStart() {
        Write-Host "  ⚡ [Show57] Initializing Plasma Waves..." -ForegroundColor Cyan
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 20)
        
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        $Show57Messages = @(
            "⚡ PLASMA WAVES - The Fourth State of Matter!",
            "🌊 Langmuir waves: Electron oscillations in plasma",
            "🔊 Ion acoustic waves: Sound waves in ionized gas",
            "🌌 Aurora Borealis: Plasma waves create dancing lights",
            "☀️ Solar wind: Plasma streams from the Sun at 400 km/s!"
        )
        $Global:messages = $Show57Messages
        
        $this.SetupPaintEvent()
        Write-Host "  ✅ [Show57] Plasma wave simulation ready" -ForegroundColor Green
    }
    
    [void] OnUpdate() {
        $this.TickCounter++
        $this.State.TimeStep++
        $this.State.ActTimer++
        $this.State.WavePhase += 0.2
        
        if ($this.State.WavePhase -gt 6.28) {
            $this.State.WavePhase = 0
        }
        
        # Act 3: Spawn aurora rays
        if ($this.State.Act -eq 3 -and $this.State.TimeStep % 30 -eq 0) {
            [void]$this.AuroraRays.Add(@{
                X = Get-Random -Minimum 100 -Maximum 600
                Age = 0
                Active = $true
            })
        }
        
        # Update aurora rays
        if ($this.State.Act -eq 3) {
            $this.UpdateAuroraRays()
        }
        
        # Act 3: Spawn solar wind
        if ($this.State.Act -eq 3 -and $this.State.TimeStep % 5 -eq 0) {
            [void]$this.SolarWind.Add(@{
                X = Get-Random -Minimum 0 -Maximum 700
                Y = 0
                VX = (Get-Random -Minimum -1 -Maximum 2) * 0.5
                VY = 3
                Age = 0
            })
        }
        
        # Update solar wind
        if ($this.State.Act -eq 3) {
            $this.UpdateSolarWind()
        }
        
        # Act transitions
        if ($this.State.ActTimer -gt 200) {
            $this.State.Act++
            if ($this.State.Act -gt 3) { $this.State.Act = 1 }
            $this.State.ActTimer = 0
            $this.State.TimeStep = 0
            $this.State.WavePhase = 0
            $this.PlasmaParticles.Clear()
            $this.AuroraRays.Clear()
            $this.SolarWind.Clear()
        }
        
        $this.Panel.Invalidate()
    }
    
    [void] OnStop() {
        Write-Host "  🛑 [Show57] Cleaning up..." -ForegroundColor Yellow
        
        if ($this.PlasmaParticles) { $this.PlasmaParticles.Clear() }
        if ($this.AuroraRays) { $this.AuroraRays.Clear() }
        if ($this.SolarWind) { $this.SolarWind.Clear() }
        
        $this.Panel.Remove_Paint($null)
        $this.Panel.Controls.Clear()
        
        $this.State.TimeStep = 0
        $this.State.ActTimer = 0
        $this.State.Act = 1
        $this.TickCounter = 0
        
        Write-Host "  ✅ [Show57] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    hidden [void] UpdateAuroraRays() {
        $toRemove = [System.Collections.ArrayList]::new()
        foreach ($ray in $this.AuroraRays) {
            $ray.Age++
            if ($ray.Age -gt 50) {
                [void]$toRemove.Add($ray)
            }
        }
        foreach ($r in $toRemove) {
            [void]$this.AuroraRays.Remove($r)
        }
    }
    
    hidden [void] UpdateSolarWind() {
        $toRemove = [System.Collections.ArrayList]::new()
        foreach ($particle in $this.SolarWind) {
            $particle.X += $particle.VX
            $particle.Y += $particle.VY
            $particle.Age++
            
            if ($particle.X -gt 700 -or $particle.Y -gt 600 -or $particle.Age -gt 100) {
                [void]$toRemove.Add($particle)
            }
        }
        foreach ($w in $toRemove) {
            [void]$this.SolarWind.Remove($w)
        }
    }
    
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderScene($s, $e.Graphics)
        }.GetNewClosure())
    }
    
    hidden [void] RenderScene([object]$sender, [System.Drawing.Graphics]$g) {
        $width = $sender.Width
        $height = $sender.Height
        
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Space background with stars
        $this.DrawBackground($g, $width, $height)
        
        switch ($this.State.Act) {
            1 { $this.DrawLangmuirAct($g, $width, $height) }
            2 { $this.DrawIonAcousticAct($g, $width, $height) }
            3 { $this.DrawAuroraAct($g, $width, $height) }
        }
        
        $this.DrawTitle($g, $width)
    }
    
    hidden [void] DrawBackground([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(5, 5, 20),
            [System.Drawing.Color]::FromArgb(15, 10, 30)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Stars
        $starRandom = New-Object System.Random(42)
        for ($i = 0; $i -lt 100; $i++) {
            $starX = $starRandom.Next(0, $width)
            $starY = $starRandom.Next(0, $height)
            $starBrightness = $starRandom.Next(100, 255)
            $starColor = [System.Drawing.Color]::FromArgb($starBrightness, 255, 255, 255)
            $starBrush = New-Object System.Drawing.SolidBrush($starColor)
            $g.FillEllipse($starBrush, $starX, $starY, 2, 2)
            $starBrush.Dispose()
        }
    }
    
    hidden [void] DrawLangmuirAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $wavelength = 80
        $amplitude = 30
        $phase = $this.State.WavePhase
        
        # Draw rows of electrons and ions
        for ($row = 0; $row -lt 5; $row++) {
            $yPos = 150 + ($row * 50)
            
            for ($xPos = 50; $xPos -lt 650; $xPos += 40) {
                $k = 2 * [math]::PI / $wavelength
                $electronDisp = $amplitude * [math]::Sin($k * $xPos - $phase)
                
                $this.DrawPlasmaParticle($g, $xPos, $yPos, $true, $electronDisp)
                $this.DrawPlasmaParticle($g, $xPos, $yPos, $false, 0)
            }
        }
        
        # Electric field
        $fieldY = 380
        for ($x = 50; $x -lt 650; $x += 80) {
            $k = 2 * [math]::PI / $wavelength
            $fieldStr = [math]::Sin($k * $x - $phase)
            $this.DrawElectricField($g, $x, $fieldY, $x + 70, $fieldStr)
        }
        
        $this.DrawActInfo($g, $width, $height, @(
            "LANGMUIR WAVES",
            "Electron oscillations",
            "Ions remain stationary",
            "High frequency waves"
        ), [System.Drawing.Color]::Cyan, @(
            "Plasma frequency: ωₚ = √(nₑe²/ε₀mₑ)",
            "Phase velocity: v = ω/k",
            "Found in: Ionosphere, fusion reactors, space"
        ))
    }
    
    hidden [void] DrawIonAcousticAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $wavelength = 100
        $amplitude = 20
        $phase = $this.State.WavePhase
        
        for ($row = 0; $row -lt 5; $row++) {
            $yPos = 150 + ($row * 50)
            
            for ($xPos = 50; $xPos -lt 650; $xPos += 50) {
                $k = 2 * [math]::PI / $wavelength
                $ionDisp = $amplitude * [math]::Sin($k * $xPos - $phase)
                $electronDisp = $amplitude * 0.3 * [math]::Sin($k * $xPos - $phase)
                
                $this.DrawPlasmaParticle($g, $xPos, $yPos, $false, $ionDisp)
                $this.DrawPlasmaParticle($g, $xPos + 15, $yPos, $true, $electronDisp)
            }
        }
        
        # Density wave
        $densityY = 380
        for ($x = 0; $x -lt $width; $x += 3) {
            $k = 2 * [math]::PI / $wavelength
            $density = 0.5 + 0.5 * [math]::Sin($k * $x - $phase)
            
            $densityAlpha = [int](150 * $density)
            $densityColor = [System.Drawing.Color]::FromArgb($densityAlpha, 200, 150, 255)
            $densityBrush = New-Object System.Drawing.SolidBrush($densityColor)
            $g.FillRectangle($densityBrush, $x, $densityY, 3, 40)
            $densityBrush.Dispose()
        }
        
        $this.DrawActInfo($g, $width, $height, @(
            "ION ACOUSTIC WAVES",
            "Sound waves in plasma",
            "Both species oscillate",
            "Lower frequency"
        ), [System.Drawing.Color]::FromArgb(255, 200, 150, 255), @(
            "Sound speed: cₛ = √(kTₑ/mᵢ)",
            "Pressure: P = nkT (ion pressure)",
            "Found in: Solar wind, tokamaks, stellar atmospheres"
        ))
    }
    
    hidden [void] DrawAuroraAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        # Aurora curtain
        $this.DrawAuroraCurtain($g, $width, $height)
        
        # Earth
        $centerX = $width / 2
        $earthRadius = 40
        $earthY = $height - 50
        $earthBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 50, 100, 150))
        $g.FillEllipse($earthBrush, $centerX - $earthRadius, $earthY - $earthRadius, $earthRadius * 2, $earthRadius * 2)
        $earthBrush.Dispose()
        
        # Magnetic field
        $this.DrawMagneticFieldLines($g, $centerX, $earthY, $earthRadius)
        
        # Solar wind particles
        $this.DrawSolarWindParticles($g)
        
        $this.DrawActInfo($g, $width, $height, @(
            "AURORA & SOLAR WIND",
            "Plasma stream from Sun's corona",
            "Speed: ~400 km/s",
            "Creates auroras"
        ), [System.Drawing.Color]::FromArgb(255, 255, 200, 100), @(
            "Solar wind pressure: P = ρv² + nkT",
            "Carries Sun's magnetic field (IMF)",
            "Causes geomagnetic storms, auroras, comet tails"
        ))
    }
    
    hidden [void] DrawPlasmaParticle([System.Drawing.Graphics]$g, [double]$x, [double]$y, [bool]$isElectron, [double]$displacement) {
        $actualX = $x + $displacement
        
        if ($isElectron) {
            $electronBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 100, 150, 255))
            $g.FillEllipse($electronBrush, $actualX - 4, $y - 4, 8, 8)
            $electronBrush.Dispose()
            
            $chargeFont = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
            $chargeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString("-", $chargeFont, $chargeBrush, $actualX - 3, $y - 5)
            $chargeFont.Dispose()
            $chargeBrush.Dispose()
        } else {
            $ionBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 100, 100))
            $g.FillEllipse($ionBrush, $actualX - 6, $y - 6, 12, 12)
            $ionBrush.Dispose()
            
            $chargeFont = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
            $chargeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString("+", $chargeFont, $chargeBrush, $actualX - 3, $y - 5)
            $chargeFont.Dispose()
            $chargeBrush.Dispose()
        }
    }
    
    hidden [void] DrawElectricField([System.Drawing.Graphics]$g, [double]$x1, [double]$y, [double]$x2, [double]$strength) {
        $numLines = 5
        $spacing = 15
        
        for ($i = 0; $i -lt $numLines; $i++) {
            $yPos = $y - ($numLines * $spacing / 2) + ($i * $spacing)
            
            $alpha = [int](150 * [math]::Abs($strength))
            $fieldColor = if ($strength -gt 0) {
                [System.Drawing.Color]::FromArgb($alpha, 255, 200, 100)
            } else {
                [System.Drawing.Color]::FromArgb($alpha, 100, 200, 255)
            }
            
            $fieldPen = New-Object System.Drawing.Pen($fieldColor, 2)
            $g.DrawLine($fieldPen, $x1, $yPos, $x2, $yPos)
            
            if ($strength -gt 0) {
                $g.DrawLine($fieldPen, $x2 - 5, $yPos - 3, $x2, $yPos)
                $g.DrawLine($fieldPen, $x2 - 5, $yPos + 3, $x2, $yPos)
            } else {
                $g.DrawLine($fieldPen, $x1 + 5, $yPos - 3, $x1, $yPos)
                $g.DrawLine($fieldPen, $x1 + 5, $yPos + 3, $x1, $yPos)
            }
            
            $fieldPen.Dispose()
        }
    }
    
    hidden [void] DrawAuroraCurtain([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $horizonY = $height - 80
        $phase = $this.State.WavePhase
        
        # Ground
        $groundBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 20, 30, 40))
        $g.FillRectangle($groundBrush, 0, $horizonY, $width, $height - $horizonY)
        $groundBrush.Dispose()
        
        # Aurora curtain
        $auroraTop = 150
        $auroraBottom = $horizonY - 50
        
        for ($x = 0; $x -lt $width; $x += 5) {
            $waveOffset = 30 * [math]::Sin(2 * [math]::PI * $x / 150 + $phase)
            $curtainTop = $auroraTop + $waveOffset
            $curtainBottom = $auroraBottom + $waveOffset * 0.3
            
            for ($y = [int]$curtainTop; $y -lt $curtainBottom; $y += 3) {
                $intensity = [math]::Max(0, [math]::Min(1, 1.0 - (($y - $curtainTop) / ($curtainBottom - $curtainTop))))
                $alpha = [int](180 * $intensity)
                $greenAmount = [int](255 * $intensity)
                $redAmount = [int](100 * (1 - $intensity))
                
                $auroraColor = [System.Drawing.Color]::FromArgb($alpha, $redAmount, $greenAmount, 50)
                $auroraBrush = New-Object System.Drawing.SolidBrush($auroraColor)
                $g.FillEllipse($auroraBrush, $x - 3, $y - 3, 6, 6)
                $auroraBrush.Dispose()
            }
        }
        
        # Aurora rays
        foreach ($ray in $this.AuroraRays) {
            if ($ray.Active) {
                $rayAlpha = [int](200 * (1 - $ray.Age / 50.0))
                if ($rayAlpha -gt 0) {
                    $rayColor = [System.Drawing.Color]::FromArgb($rayAlpha, 150, 255, 150)
                    $rayPen = New-Object System.Drawing.Pen($rayColor, 3)
                    $rayWave = 10 * [math]::Sin($ray.Age * 0.1)
                    $g.DrawLine($rayPen, $ray.X + $rayWave, 0, $ray.X, $horizonY - 50)
                    $rayPen.Dispose()
                }
            }
        }
    }
    
    hidden [void] DrawMagneticFieldLines([System.Drawing.Graphics]$g, [double]$centerX, [double]$centerY, [double]$earthRadius) {
        $numLines = 8
        
        for ($i = 1; $i -le $numLines; $i++) {
            $angle = ($i * 22.5) * [math]::PI / 180
            $points = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            
            for ($t = 0; $t -le 180; $t += 5) {
                $theta = $t * [math]::PI / 180
                $r = $earthRadius * 3 * [math]::Sin($theta) * [math]::Sin($theta)
                
                $x = $centerX + $r * [math]::Cos($theta) * [math]::Cos($angle)
                $y = $centerY - $r * [math]::Sin($theta)
                
                if ($r -gt $earthRadius) {
                    $points.Add([System.Drawing.Point]::new([int]$x, [int]$y))
                }
            }
            
            if ($points.Count -gt 1) {
                $fieldPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 100, 200, 255), 2)
                $fieldPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
                $g.DrawLines($fieldPen, $points.ToArray())
                $fieldPen.Dispose()
            }
        }
    }
    
    hidden [void] DrawSolarWindParticles([System.Drawing.Graphics]$g) {
        foreach ($particle in $this.SolarWind) {
            $alpha = [int](255 * (1 - $particle.Age / 100.0))
            if ($alpha -gt 0) {
                $particleColor = [System.Drawing.Color]::FromArgb($alpha, 255, 200, 100)
                $particleBrush = New-Object System.Drawing.SolidBrush($particleColor)
                $g.FillEllipse($particleBrush, $particle.X - 3, $particle.Y - 3, 6, 6)
                $particleBrush.Dispose()
                
                if ($particle.Age -lt 20) {
                    $trailAlpha = [int](100 * (1 - $particle.Age / 20.0))
                    $trailColor = [System.Drawing.Color]::FromArgb($trailAlpha, 255, 150, 50)
                    $trailBrush = New-Object System.Drawing.SolidBrush($trailColor)
                    $g.FillEllipse($trailBrush, $particle.X - $particle.VX * 2, $particle.Y - $particle.VY * 2, 4, 4)
                    $trailBrush.Dispose()
                }
            }
        }
    }
    
    hidden [void] DrawActInfo([System.Drawing.Graphics]$g, [int]$width, [int]$height, [string[]]$infoLines, [System.Drawing.Color]$color, [string[]]$mathLines) {
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush($color)
        
        $y = 60
        foreach ($line in $infoLines) {
            $g.DrawString($line, $infoFont, $infoBrush, 20, $y)
            $y += 25
        }
        
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 150, 255, 150))
        
        $y = $height - 80
        foreach ($line in $mathLines) {
            $g.DrawString($line, $mathFont, $mathBrush, 20, $y)
            $y += 20
        }
        
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    hidden [void] DrawTitle([System.Drawing.Graphics]$g, [int]$width) {
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 150, 255))
        
        $actNames = @("", "✨ ACT 1: LANGMUIR WAVES", "✨ ACT 2: ION ACOUSTIC", "✨ ACT 3: AURORA & SOLAR WIND")
        $titleText = "⚡ SHOW57: " + $actNames[$this.State.Act]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show57 {
    Write-Host "[Show57] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show57")) {
        $show = $Global:ShowManager.Shows["show57"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show57] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow57 class loaded (v3)" -ForegroundColor Green
