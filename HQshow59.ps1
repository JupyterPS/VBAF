# ====================================================
# HQshow59.ps1 — Polarization Theater v3 (GM)
# PART 1: Class Definition & Core Methods
# ====================================================

Write-Host "`n=> _____ HQshow59 (Polarization v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show59 - Inherits from BaseShow
# ============================================
class Show59 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    
    # ========================================
    # Constructor
    # ========================================
    Show59([System.Windows.Forms.Panel]$panel) : base("show59", $panel) {
        # Initialize state (replaces $Global:Show59Data)
        $this.State = @{
            TimeStep = 0
            Act = 1  # 1=Linear, 2=Circular, 3=Elliptical, 4=Malus Law
            ActTimer = 0
            WavePhase = 0
            PolarizationAngle = 0
            FilterAngle = 45
            CircularPhase = 0
        }
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host "  🔦 [Show59] Initializing Polarization Theater..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 20)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        # Reset state for fresh start
        $this.State.TimeStep = 0
        $this.State.Act = 1
        $this.State.ActTimer = 0
        $this.State.WavePhase = 0
        $this.State.CircularPhase = 0
        $this.State.FilterAngle = 45
        
        Write-Host "  ✅ [Show59] Polarization Theater ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Update animation state
        $this.State.TimeStep += 1
        $this.State.ActTimer += 1
        $this.State.WavePhase += 0.15
        $this.State.CircularPhase += 0.1
        
        if ($this.State.WavePhase -gt 6.28) {
            $this.State.WavePhase = 0
        }
        
        if ($this.State.CircularPhase -gt 6.28) {
            $this.State.CircularPhase = 0
        }
        
        # Vary filter angle for Malus's Law demonstration
        if ($this.State.Act -eq 4) {
            $this.State.FilterAngle = 90 + 90 * [math]::Sin($this.State.TimeStep * 0.02)
        }
        
        # Act transitions (cycle through all 4 acts every ~8 seconds)
        if ($this.State.ActTimer -gt 200) {
            $this.State.Act++
            if ($this.State.Act -gt 4) { 
                $this.State.Act = 1 
            }
            $this.State.ActTimer = 0
            $this.State.TimeStep = 0
            $this.State.WavePhase = 0
            $this.State.CircularPhase = 0
            $this.State.FilterAngle = 45
        }
        
        # Invalidate to trigger repaint
        if ($this.Panel -and $this.Panel.Visible -and $this.Panel.Width -gt 0) {
            $this.Panel.Invalidate()
        }
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host "  🛑 [Show59] Cleaning up..." -ForegroundColor Yellow
        
        # Remove paint handler
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.Act = 1
        $this.State.ActTimer = 0
        $this.State.WavePhase = 0
        
        Write-Host "  ✅ [Show59] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Paint Event Setup
    # ========================================
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderPolarization($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }
    
    # ========================================
    # Main Rendering Method
    # ========================================
    hidden [void] RenderPolarization([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Dark background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(15, 15, 20),
            [System.Drawing.Color]::FromArgb(25, 20, 30)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        $currentAct = $this.State.Act
        $phase = $this.State.WavePhase
        $polAngle = $this.State.PolarizationAngle
        $circPhase = $this.State.CircularPhase
        
        # Route to appropriate act renderer
        switch ($currentAct) {
            1 { $this.RenderLinearPolarization($g, $width, $height, $phase) }
            2 { $this.RenderCircularPolarization($g, $width, $height, $phase, $circPhase) }
            3 { $this.RenderEllipticalPolarization($g, $width, $height, $phase, $circPhase) }
            4 { $this.RenderMalusLaw($g, $width, $height, $phase) }
        }
        
        # Title overlay
        $this.RenderTitle($g, $width, $currentAct)
    }
    
    # ========================================
    # ACT 1: Linear Polarization
    # ========================================
    hidden [void] RenderLinearPolarization([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        # Show three different linear polarizations
        $angles = @(0, ([math]::PI / 4), ([math]::PI / 2))
        $labels = @("Horizontal (0°)", "Diagonal (45°)", "Vertical (90°)")
        $yPositions = @(150, 250, 350)
        
        for ($i = 0; $i -lt 3; $i++) {
            # Draw wave
            $this.DrawPolarizedWave($g, 80, $yPositions[$i], 350, 40, $phase, $angles[$i], $false, $false, 1.0)
            
            # Draw polarization state
            $this.DrawPolarizationState($g, 500, $yPositions[$i], 50, $phase, "linear", $angles[$i], 1.0)
            
            # Label
            $labelFont = New-Object System.Drawing.Font("Consolas", 8)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
            $g.DrawString($labels[$i], $labelFont, $labelBrush, 80, $yPositions[$i] - 30)
            $labelFont.Dispose()
            $labelBrush.Dispose()
        }
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 100, 100))
        $g.DrawString("LINEAR POLARIZATION", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("E-field oscillates in fixed plane", $infoFont, $infoBrush, 20, 85)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("E = E₀·cos(kz - ωt)·x̂  (horizontal)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("E = E₀·cos(kz - ωt)·ŷ  (vertical)", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Polaroid filters, LCD screens, reflections", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # ACT 2: Circular Polarization
    # ========================================
    hidden [void] RenderCircularPolarization([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase, [double]$circPhase) {
        # Right-handed circular
        $this.DrawPolarizedWave($g, 80, 200, 350, 40, $phase, 0, $true, $false, 1.0)
        $this.DrawPolarizationState($g, 500, 200, 50, $circPhase, "circular", 0, 1.0)
        
        $rhLabel = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $rhBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Lime)
        $g.DrawString("RIGHT-HANDED", $rhLabel, $rhBrush, 80, 170)
        $g.DrawString("(clockwise rotation)", $rhLabel, $rhBrush, 500, 260)
        $rhLabel.Dispose()
        $rhBrush.Dispose()
        
        # Left-handed circular (opposite phase)
        $this.DrawPolarizedWave($g, 80, 330, 350, 40, $phase, 0, $true, $false, 1.0)
        $this.DrawPolarizationState($g, 500, 330, 50, (-$circPhase), "circular", 0, 1.0)
        
        $lhLabel = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $lhBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 150, 150, 255))
        $g.DrawString("LEFT-HANDED", $lhLabel, $lhBrush, 80, 300)
        $g.DrawString("(counterclockwise)", $lhLabel, $lhBrush, 500, 390)
        $lhLabel.Dispose()
        $lhBrush.Dispose()
        
        # Component breakdown
        $compX = 600
        $compY = 100
        $compFont = New-Object System.Drawing.Font("Consolas", 9)
        $compBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("Components:", $compFont, $compBrush, $compX, $compY)
        $g.DrawString("Ex = E₀·cos(kz - ωt)", $compFont, $compBrush, $compX, $compY + 20)
        $g.DrawString("Ey = ±E₀·sin(kz - ωt)", $compFont, $compBrush, $compX, $compY + 40)
        $g.DrawString("(90° phase difference)", $compFont, $compBrush, $compX, $compY + 60)
        $compFont.Dispose()
        $compBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 100, 255, 100))
        $g.DrawString("CIRCULAR POLARIZATION", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("E-field rotates in circle", $infoFont, $infoBrush, 20, 85)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("3D cinema, satellite communication, optical activity", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Quarter-wave plate converts linear → circular", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }

    # ========================================
    # ACT 3: Elliptical Polarization
    # ========================================
    hidden [void] RenderEllipticalPolarization([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase, [double]$circPhase) {
        # Show three elliptical states with different ratios
        $ratios = @(0.3, 0.6, 0.9)
        $yPositions = @(150, 250, 350)
        
        for ($i = 0; $i -lt 3; $i++) {
            $this.DrawPolarizedWave($g, 80, $yPositions[$i], 350, 40, $phase, 0, $false, $true, $ratios[$i])
            $this.DrawPolarizationState($g, 500, $yPositions[$i], 50, $circPhase, "elliptical", 0, $ratios[$i])
            
            # Ratio label
            $ratioFont = New-Object System.Drawing.Font("Consolas", 10)
            $ratioBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Magenta)
            $g.DrawString("Ratio: $($ratios[$i].ToString('F1'))", $ratioFont, $ratioBrush, 80, $yPositions[$i] - 30)
            $ratioFont.Dispose()
            $ratioBrush.Dispose()
        }
        
        # Transition diagram
        $transX = 580
        $transY = 100
        $transFont = New-Object System.Drawing.Font("Consolas", 8)
        $transBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("Polarization Types:", $transFont, $transBrush, $transX, $transY)
        $g.DrawString("", $transFont, $transBrush, $transX, $transY + 20)
        $g.DrawString("Linear (ratio = 0)", $transFont, $transBrush, $transX, $transY + 40)
        $g.DrawString("    ↓", $transFont, $transBrush, $transX, $transY + 60)
        $g.DrawString("Elliptical (0 < r < 1)", $transFont, $transBrush, $transX, $transY + 80)
        $g.DrawString("    ↓", $transFont, $transBrush, $transX, $transY + 100)
        $g.DrawString("Circular (ratio = 1)", $transFont, $transBrush, $transX, $transY + 120)
        $transFont.Dispose()
        $transBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 150, 255))
        $g.DrawString("ELLIPTICAL POLARIZATION", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("General case: E-field traces ellipse", $infoFont, $infoBrush, 20, 85)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Ex = E₀x·cos(kz - ωt)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Ey = E₀y·cos(kz - ωt + δ)  (phase δ ≠ 0, 90°)", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Most general polarization state!", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # ACT 4: Malus's Law (Polarizers)
    # ========================================
    hidden [void] RenderMalusLaw([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        # Light source
        $sourceX = 80
        $sourceY = 250
        $sourceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 150))
        $g.FillEllipse($sourceBrush, $sourceX - 20, $sourceY - 20, 40, 40)
        $sourceBrush.Dispose()
        
        # Unpolarized light rays
        for ($i = 0; $i -lt 8; $i++) {
            $angle = $i * [math]::PI / 4
            $rayLength = 30
            $rayX = $sourceX + $rayLength * [math]::Cos($angle)
            $rayY = $sourceY + $rayLength * [math]::Sin($angle)
            
            $rayPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
            $g.DrawLine($rayPen, $sourceX, $sourceY, $rayX, $rayY)
            $rayPen.Dispose()
        }
        
        $sourceFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $sourceLblBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("Unpolarized", $sourceFont, $sourceLblBrush, $sourceX - 30, $sourceY + 30)
        $sourceFont.Dispose()
        $sourceLblBrush.Dispose()
        
        # First polarizer (vertical)
        $pol1X = 200
        $pol1Y = 200
        $polAngle1 = [math]::PI / 2  # 90° (vertical)
        $this.DrawPolarizer($g, $pol1X, $pol1Y, 40, 100, $polAngle1, "Polarizer")
        
        # After first polarizer: linear polarized light
        $beam1Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 0, 255, 0), 6)
        $g.DrawLine($beam1Pen, $pol1X + 40, $pol1Y + 50, $pol1X + 120, $pol1Y + 50)
        $beam1Pen.Dispose()
        
        # Second polarizer (analyzer) - variable angle
        $pol2X = 360
        $pol2Y = 200
        $polAngle2 = ($this.State.FilterAngle * [math]::PI / 180)
        $this.DrawPolarizer($g, $pol2X, $pol2Y, 40, 100, $polAngle2, "Analyzer")
        
        # Calculate transmitted intensity (Malus's Law)
        $angleDiff = $polAngle2 - $polAngle1
        $intensity = [math]::Cos($angleDiff) * [math]::Cos($angleDiff)
        
        # After second polarizer: attenuated beam
        if ($intensity -gt 0.01) {
            $beamAlpha = [int](200 * $intensity)
            $beam2Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($beamAlpha, 0, 255, 0), [int](6 * $intensity))
            $g.DrawLine($beam2Pen, $pol2X + 40, $pol2Y + 50, $pol2X + 120, $pol2Y + 50)
            $beam2Pen.Dispose()
        }
        
        # Intensity bars
        $this.DrawIntensityBar($g, 260, 350, 50, 100, 1.0, "I₀")
        $this.DrawIntensityBar($g, 420, 350, 50, 100, $intensity, "I")
        
        # Malus's Law formula display
        $malusX = 520
        $malusY = 200
        $malusFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $malusBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("MALUS'S LAW", $malusFont, $malusBrush, $malusX, $malusY)
        $malusFont.Dispose()
        $malusBrush.Dispose()
        
        $formulaFont = New-Object System.Drawing.Font("Consolas", 8)
        $formulaBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("I = I₀·cos²(θ)", $formulaFont, $formulaBrush, $malusX, $malusY + 30)
        $g.DrawString("", $formulaFont, $formulaBrush, $malusX, $malusY + 50)
        $g.DrawString("θ = $([int]($this.State.FilterAngle))°", $formulaFont, $formulaBrush, $malusX, $malusY + 70)
        $g.DrawString("I/I₀ = $($intensity.ToString('F3'))", $formulaFont, $formulaBrush, $malusX, $malusY + 90)
        $formulaFont.Dispose()
        $formulaBrush.Dispose()
        
        # Angle control indicator
        $ctrlFont = New-Object System.Drawing.Font("Consolas", 8)
        $ctrlBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
        $g.DrawString("Angle varies: 0° → 90° → 180°", $ctrlFont, $ctrlBrush, $malusX, $malusY + 120)
        $ctrlFont.Dispose()
        $ctrlBrush.Dispose()
        
        # Special cases
        $specialY = $malusY + 150
        $specialFont = New-Object System.Drawing.Font("Consolas", 8)
        $specialBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("Special cases:", $specialFont, $specialBrush, $malusX, $specialY)
        $g.DrawString("θ = 0°:   I = I₀ (parallel)", $specialFont, $specialBrush, $malusX, $specialY + 18)
        $g.DrawString("θ = 45°:  I = I₀/2", $specialFont, $specialBrush, $malusX, $specialY + 36)
        $g.DrawString("θ = 90°:  I = 0 (crossed)", $specialFont, $specialBrush, $malusX, $specialY + 54)
        $specialFont.Dispose()
        $specialBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("MALUS'S LAW", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Intensity through polarizers", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Crossed → blocks all light!", $infoFont, $infoBrush, 20, 110)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Applications: Sunglasses, LCD displays, photography", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Polaroid filters discovered by Edwin Land (1928)", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # Rendering Utility Methods
    # ========================================
    
    # Draw 3D wave with polarization
    hidden [void] DrawPolarizedWave([System.Drawing.Graphics]$g, [double]$startX, [double]$startY, [double]$length, [double]$amplitude, [double]$phase, [double]$polAngle, [bool]$isCircular, [bool]$isElliptical, [double]$ellipseRatio) {
        $numPoints = 100
        
        for ($i = 0; $i -lt $numPoints; $i++) {
            $x = $startX + ($i * $length / $numPoints)
            $t = $i / 20.0
            
            if ($isCircular) {
                # Circular polarization
                $yDisp = $amplitude * [math]::Cos(2 * [math]::PI * $t + $phase)
                $zDisp = $amplitude * [math]::Sin(2 * [math]::PI * $t + $phase)
            } elseif ($isElliptical) {
                # Elliptical polarization
                $yDisp = $amplitude * [math]::Cos(2 * [math]::PI * $t + $phase)
                $zDisp = $amplitude * $ellipseRatio * [math]::Sin(2 * [math]::PI * $t + $phase)
            } else {
                # Linear polarization
                $yDisp = $amplitude * [math]::Cos(2 * [math]::PI * $t + $phase) * [math]::Cos($polAngle)
                $zDisp = $amplitude * [math]::Cos(2 * [math]::PI * $t + $phase) * [math]::Sin($polAngle)
            }
            
            # Project to 2D
            $yScreen = $startY + $yDisp - $zDisp * 0.5
            
            # Color based on Z component (depth)
            $colorIntensity = [int](128 + 127 * ($zDisp / $amplitude))
            $waveColor = [System.Drawing.Color]::FromArgb(255, $colorIntensity, 150, 255 - $colorIntensity)
            $waveBrush = New-Object System.Drawing.SolidBrush($waveColor)
            $g.FillEllipse($waveBrush, $x - 3, $yScreen - 3, 6, 6)
            $waveBrush.Dispose()
        }
        
        # Draw propagation axis
        $axisPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 200, 200, 200), 2)
        $g.DrawLine($axisPen, $startX, $startY, $startX + $length, $startY)
        $axisPen.Dispose()
    }
    
    # Draw polarization vector/ellipse at end
    hidden [void] DrawPolarizationState([System.Drawing.Graphics]$g, [double]$centerX, [double]$centerY, [double]$radius, [double]$phase, [string]$polType, [double]$angle, [double]$ellipseRatio) {
        if ($polType -eq "linear") {
            # Draw linear polarization direction
            $endX = $centerX + $radius * [math]::Cos($angle)
            $endY = $centerY + $radius * [math]::Sin($angle)
            
            $vectorPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 100, 100), 4)
            $g.DrawLine($vectorPen, $centerX, $centerY, $endX, $endY)
            
            # Arrowhead
            $arrowSize = 10
            $arrowAngle1 = $angle + 2.8
            $arrowAngle2 = $angle - 2.8
            $g.DrawLine($vectorPen, $endX, $endY, $endX - $arrowSize * [math]::Cos($arrowAngle1), $endY - $arrowSize * [math]::Sin($arrowAngle1))
            $g.DrawLine($vectorPen, $endX, $endY, $endX - $arrowSize * [math]::Cos($arrowAngle2), $endY - $arrowSize * [math]::Sin($arrowAngle2))
            $vectorPen.Dispose()
            
            # Angle label
            $angleFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $angleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            $angleDeg = [int]($angle * 180 / [math]::PI)
            $g.DrawString("${angleDeg}°", $angleFont, $angleBrush, $centerX + 10, $centerY - 25)
            $angleFont.Dispose()
            $angleBrush.Dispose()
            
        } elseif ($polType -eq "circular") {
            # Draw rotating vector
            $vecX = $centerX + $radius * [math]::Cos($phase)
            $vecY = $centerY + $radius * [math]::Sin($phase)
            
            $vectorPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 100, 255, 100), 4)
            $g.DrawLine($vectorPen, $centerX, $centerY, $vecX, $vecY)
            $vectorPen.Dispose()
            
            # Circle outline
            $circlePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 100, 255, 100), 2)
            $circlePen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
            $g.DrawEllipse($circlePen, $centerX - $radius, $centerY - $radius, $radius * 2, $radius * 2)
            $circlePen.Dispose()
            
            # Rotation arrow
            $arrowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
            $g.DrawArc($arrowPen, $centerX - $radius - 10, $centerY - $radius - 10, ($radius + 10) * 2, ($radius + 10) * 2, -90, 270)
            $arrowPen.Dispose()
            
        } elseif ($polType -eq "elliptical") {
            # Draw rotating ellipse vector
            $vecX = $centerX + $radius * [math]::Cos($phase)
            $vecY = $centerY + $radius * $ellipseRatio * [math]::Sin($phase)
            
            $vectorPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 150, 255), 4)
            $g.DrawLine($vectorPen, $centerX, $centerY, $vecX, $vecY)
            $vectorPen.Dispose()
            
            # Ellipse outline
            $ellipsePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 255, 150, 255), 2)
            $ellipsePen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
            $g.DrawEllipse($ellipsePen, $centerX - $radius, $centerY - $radius * $ellipseRatio, $radius * 2, $radius * 2 * $ellipseRatio)
            $ellipsePen.Dispose()
        }
        
        # Center dot
        $centerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.FillEllipse($centerBrush, $centerX - 4, $centerY - 4, 8, 8)
        $centerBrush.Dispose()
    }
    
    # Draw polarizing filter
    hidden [void] DrawPolarizer([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$width, [double]$height, [double]$angle, [string]$label) {
        # Filter rectangle
        $filterBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 80, 80, 80))
        $g.FillRectangle($filterBrush, $x, $y, $width, $height)
        $filterBrush.Dispose()
        
        $filterPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 3)
        $g.DrawRectangle($filterPen, $x, $y, $width, $height)
        $filterPen.Dispose()
        
        # Transmission axis (lines showing polarization direction)
        $numLines = 8
        $centerX = $x + $width / 2
        $centerY = $y + $height / 2
        $lineLength = $height * 0.8
        
        for ($i = 0; $i -lt $numLines; $i++) {
            $lineY = $y + ($i + 0.5) * ($height / $numLines)
            $dx = ($lineLength / 2) * [math]::Cos($angle)
            $dy = ($lineLength / 2) * [math]::Sin($angle)
            
            $axisPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
            $g.DrawLine($axisPen, $centerX - $dx, $lineY - $dy, $centerX + $dx, $lineY + $dy)
            $axisPen.Dispose()
        }
        
        # Label
        $labelFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString($label, $labelFont, $labelBrush, $x + 5, $y - 25)
        $labelFont.Dispose()
        $labelBrush.Dispose()
        
        # Angle label
        $angleFont = New-Object System.Drawing.Font("Consolas", 8)
        $angleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $angleDeg = [int]($angle * 180 / [math]::PI)
        $g.DrawString("${angleDeg}°", $angleFont, $angleBrush, $x + $width - 30, $y + $height + 5)
        $angleFont.Dispose()
        $angleBrush.Dispose()
    }
    
    # Draw intensity bar
    hidden [void] DrawIntensityBar([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$width, [double]$height, [double]$intensity, [string]$label) {
        # Background
        $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 30, 30, 30))
        $g.FillRectangle($bgBrush, $x, $y, $width, $height)
        $bgBrush.Dispose()
        
        # Intensity fill
        $fillHeight = [int]($height * $intensity)
        $intensityColor = [System.Drawing.Color]::FromArgb(255, [int](255 * $intensity), [int](200 * $intensity), 100)
        $intensityBrush = New-Object System.Drawing.SolidBrush($intensityColor)
        $g.FillRectangle($intensityBrush, $x, $y + $height - $fillHeight, $width, $fillHeight)
        $intensityBrush.Dispose()
        
        # Border
        $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2)
        $g.DrawRectangle($borderPen, $x, $y, $width, $height)
        $borderPen.Dispose()
        
        # Label
        $labelFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString($label, $labelFont, $labelBrush, $x, $y - 20)
        $percentText = "$([int]($intensity * 100))%"
        $g.DrawString($percentText, $labelFont, $labelBrush, $x + 5, $y + $height/2 - 10)
        $labelFont.Dispose()
        $labelBrush.Dispose()
    }
    
    # Render title overlay
    hidden [void] RenderTitle([System.Drawing.Graphics]$g, [int]$width, [int]$currentAct) {
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 200, 255))
        
        $actNames = @("", "✨ ACT 1: LINEAR", "✨ ACT 2: CIRCULAR", "✨ ACT 3: ELLIPTICAL", "✨ ACT 4: MALUS'S LAW")
        $titleText = "SHOW59: " + $actNames[$currentAct]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show59 {
    Write-Host "[Show59] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show59")) {
        $show = $Global:ShowManager.Shows["show59"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show59] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow59 class loaded (v3)" -ForegroundColor Green
