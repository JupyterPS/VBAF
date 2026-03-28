# ====================================================
# HQshow58.ps1 — Gravitational Waves v3 (GM)
# PART 1: Class Definition & Core Methods
# ====================================================

Write-Host "`n=> _____ HQshow58 (Gravitational Waves v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show58 - Inherits from BaseShow
# ============================================
class Show58 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $ChirpData
    hidden [System.Collections.ArrayList] $LIGONoise
    
    # ========================================
    # Constructor
    # ========================================
    Show58([System.Windows.Forms.Panel]$panel) : base("show58", $panel) {
        # Initialize state (replaces $Global:Show58Data)
        $this.State = @{
            TimeStep = 0
            Act = 1  # 1=Spacetime Grid, 2=Binary Merger, 3=LIGO Detection, 4=Chirp Signal
            ActTimer = 0
            WavePhase = 0
            OrbitRadius = 150
            OrbitSpeed = 0.05
            OrbitAngle = 0
            MergerStage = 0
        }
        
        $this.ChirpData = [System.Collections.ArrayList]::new()
        $this.LIGONoise = [System.Collections.ArrayList]::new()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host "  🌌 [Show58] Initializing Gravitational Waves..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 10)
        
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
        $this.State.OrbitRadius = 150
        $this.State.OrbitSpeed = 0.05
        $this.State.OrbitAngle = 0
        $this.ChirpData.Clear()
        $this.LIGONoise.Clear()
        
        Write-Host "  ✅ [Show58] Gravitational Waves ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Update animation state
        $this.State.TimeStep += 1
        $this.State.ActTimer += 1
        $this.State.WavePhase += 0.15
        
        if ($this.State.WavePhase -gt 6.28) {
            $this.State.WavePhase = 0
        }
        
        # Update binary orbit
        $this.State.OrbitAngle += $this.State.OrbitSpeed
        if ($this.State.OrbitAngle -gt 6.28) {
            $this.State.OrbitAngle = 0
        }
        
        # Gradually decrease orbit radius (inspiral) in Act 2
        if ($this.State.Act -eq 2) {
            $this.State.OrbitRadius = [math]::Max(50, $this.State.OrbitRadius - 0.1)
            $this.State.OrbitSpeed = [math]::Min(0.2, $this.State.OrbitSpeed + 0.0005)
        } else {
            $this.State.OrbitRadius = 150
            $this.State.OrbitSpeed = 0.05
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
            $this.ChirpData.Clear()
            $this.LIGONoise.Clear()
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
        Write-Host "  🛑 [Show58] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        if ($this.ChirpData) {
            $this.ChirpData.Clear()
        }
        if ($this.LIGONoise) {
            $this.LIGONoise.Clear()
        }
        
        # Remove paint handler
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.Act = 1
        $this.State.ActTimer = 0
        $this.State.WavePhase = 0
        
        Write-Host "  ✅ [Show58] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Paint Event Setup
    # ========================================
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderGravitationalWaves($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }
    
    # ========================================
    # Main Rendering Method
    # ========================================
    hidden [void] RenderGravitationalWaves([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Deep space background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(5, 5, 10),
            [System.Drawing.Color]::FromArgb(10, 5, 15)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Add stars
        $this.DrawStars($g, $width, $height)
        
        $currentAct = $this.State.Act
        $phase = $this.State.WavePhase
        $centerX = $width / 2
        $centerY = $height / 2
        
        # Route to appropriate act renderer
        switch ($currentAct) {
            1 { $this.RenderSpacetimeGrid($g, $width, $height, $centerX, $centerY, $phase) }
            2 { $this.RenderBinaryMerger($g, $width, $height, $centerX, $centerY, $phase) }
            3 { $this.RenderLIGODetection($g, $width, $height, $centerX, $centerY, $phase) }
            4 { $this.RenderChirpSignal($g, $width, $height, $centerX, $centerY, $phase) }
        }
        
        # Title overlay
        $this.RenderTitle($g, $width, $currentAct)
    }
    
    # ========================================
    # ACT 1: Spacetime Grid Distortion
    # ========================================
    hidden [void] RenderSpacetimeGrid([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY, [double]$phase) {
        # Draw distorted spacetime grid
        $waveAmplitude = 20 * [math]::Sin($phase)
        $this.DrawSpacetimeGrid($g, $width, $height, $phase, $waveAmplitude)
        
        # Gravitational wave propagating across
        $waveX = 100 + (($this.State.TimeStep * 3) % 500)
        
        for ($i = 0; $i -lt 5; $i++) {
            $waveRadius = 60 + ($i * 40)
            $waveAlpha = [int](150 * (1 - $i / 5.0))
            $waveColor = [System.Drawing.Color]::FromArgb($waveAlpha, 100, 255, 200)
            $wavePen = New-Object System.Drawing.Pen($waveColor, 3)
            $g.DrawEllipse($wavePen, $waveX - $waveRadius, $centerY - $waveRadius, $waveRadius * 2, $waveRadius * 2)
            $wavePen.Dispose()
        }
        
        # Source indicator
        $sourceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 100))
        $g.FillEllipse($sourceBrush, $waveX - 8, $centerY - 8, 16, 16)
        $sourceBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("SPACETIME RIPPLES", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Gravitational waves distort space", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("+ polarization shown", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Stretching and squeezing", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Wave properties
        $propFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $propBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Speed: c (speed of light!)", $propFont, $propBrush, $width - 280, 60)
        $g.DrawString("Amplitude: ~10⁻²¹ (tiny!)", $propFont, $propBrush, $width - 280, 85)
        $propFont.Dispose()
        $propBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 150, 255, 150))
        $g.DrawString("Metric perturbation: gμν = ημν + hμν", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Strain: h = ΔL/L (fractional length change)", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Predicted by Einstein (1916), detected 2015!", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # ACT 2: Binary Black Hole Merger
    # ========================================
    hidden [void] RenderBinaryMerger([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY, [double]$phase) {
        # Calculate orbital positions
        $angle1 = $this.State.OrbitAngle
        $angle2 = $angle1 + [math]::PI
        $radius = $this.State.OrbitRadius
        
        $bh1X = $centerX + $radius * [math]::Cos($angle1)
        $bh1Y = $centerY + $radius * [math]::Sin($angle1)
        $bh2X = $centerX + $radius * [math]::Cos($angle2)
        $bh2Y = $centerY + $radius * [math]::Sin($angle2)
        
        # Draw orbit paths
        $orbitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 100, 200, 255), 2)
        $orbitPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
        $g.DrawEllipse($orbitPen, $centerX - $radius, $centerY - $radius, $radius * 2, $radius * 2)
        $orbitPen.Dispose()
        
        # Draw gravitational waves emanating
        for ($i = 1; $i -le 4; $i++) {
            $gwRadius = $radius + ($i * 50) + (($this.State.TimeStep * 2) % 50)
            $gwAlpha = [int](120 * (1 - $i / 5.0))
            $gwColor = [System.Drawing.Color]::FromArgb($gwAlpha, 100, 255, 200)
            $gwPen = New-Object System.Drawing.Pen($gwColor, 2)
            $g.DrawEllipse($gwPen, $centerX - $gwRadius, $centerY - $gwRadius, $gwRadius * 2, $gwRadius * 2)
            $gwPen.Dispose()
        }
        
        # Draw black holes
        $this.DrawCompactObject($g, $bh1X, $bh1Y, 25, $true, 36)
        $this.DrawCompactObject($g, $bh2X, $bh2Y, 20, $true, 29)
        
        # Connection line (gravitational interaction)
        $connectPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 255, 200, 100), 2)
        $connectPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        $g.DrawLine($connectPen, $bh1X, $bh1Y, $bh2X, $bh2Y)
        $connectPen.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 100))
        $g.DrawString("BINARY BLACK HOLE MERGER", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("GW150914: First detection!", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("36 M☉ + 29 M☉ → 62 M☉", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("3 solar masses → gravitational waves!", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Orbital data
        $orbitalFont = New-Object System.Drawing.Font("Consolas", 8)
        $orbitalBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $separation = [int]($radius * 2 / 10)
        $g.DrawString("Separation: ~${separation}00 km", $orbitalFont, $orbitalBrush, $width - 280, 60)
        $g.DrawString("Orbital speed: ~0.5c", $orbitalFont, $orbitalBrush, $width - 280, 80)
        $g.DrawString("Duration: 0.2 seconds", $orbitalFont, $orbitalBrush, $width - 280, 100)
        $orbitalFont.Dispose()
        $orbitalBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Luminosity: L ~ 10⁴⁹ W (brighter than all stars!)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Energy loss: dE/dt = -(32/5)·G⁴/c⁵·m₁²m₂²(m₁+m₂)/r⁵", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Distance: 1.3 billion light-years", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }

    # ========================================
    # ACT 3: LIGO Detection
    # ========================================
    hidden [void] RenderLIGODetection([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY, [double]$phase) {
        # LIGO detector (left side)
        $ligoX = 150
        $ligoY = 250
        $armLength = 180
        
        # Simulated strain from passing GW
        $strain = 0.0001 * [math]::Sin($phase * 10)
        
        $this.DrawLIGODetector($g, $ligoX, $ligoY, $armLength, $strain)
        
        # Passing gravitational wave
        $gwY = 100 + (($this.State.TimeStep * 2) % 300)
        
        for ($x = 0; $x -lt $width; $x += 40) {
            $waveHeight = 30 * [math]::Sin(2 * [math]::PI * $x / 150 + $phase)
            $gwColor = [System.Drawing.Color]::FromArgb(150, 100, 255, 200)
            $gwBrush = New-Object System.Drawing.SolidBrush($gwColor)
            $g.FillEllipse($gwBrush, $x, $gwY + $waveHeight - 8, 16, 16)
            $gwBrush.Dispose()
        }
        
        # Strain meter
        $meterX = 500
        $meterY = 180
        $meterWidth = 180
        $meterHeight = 200
        
        # Meter background
        $meterBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 20, 20, 30))
        $g.FillRectangle($meterBrush, $meterX, $meterY, $meterWidth, $meterHeight)
        $meterBrush.Dispose()
        
        $meterPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
        $g.DrawRectangle($meterPen, $meterX, $meterY, $meterWidth, $meterHeight)
        $meterPen.Dispose()
        
        # Strain signal
        $signalY = $meterY + $meterHeight/2
        $signalAmplitude = 60 * [math]::Sin($phase * 10)
        
        $signalPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0, 255, 0), 3)
        $g.DrawLine($signalPen, $meterX + 10, $signalY, $meterX + $meterWidth - 10, $signalY + $signalAmplitude)
        $signalPen.Dispose()
        
        # Meter labels
        $meterFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $meterLblBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("STRAIN METER", $meterFont, $meterLblBrush, $meterX + 35, $meterY + 10)
        $strainValue = [math]::Abs($strain)
        $g.DrawString("h = $($strainValue.ToString('E2'))", $meterFont, $meterLblBrush, $meterX + 45, $signalY - 20)
        $meterFont.Dispose()
        $meterLblBrush.Dispose()
        
        # Detection indicator
        if ([math]::Abs($strain) -gt 0.00005) {
            $detectFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $detectBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 50, 50))
            $g.DrawString("🔴 DETECTION!", $detectFont, $detectBrush, $meterX + 30, $meterY + $meterHeight - 40)
            $detectFont.Dispose()
            $detectBrush.Dispose()
        }
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("LIGO DETECTOR", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Laser Interferometer", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Measures: ΔL/L ~ 10⁻²¹", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Smaller than a proton!", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 150, 255, 150))
        $g.DrawString("Sensitivity: 10⁻²¹ meters (0.0001 proton diameter)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Two detectors: Hanford WA, Livingston LA", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("2017 Nobel Prize: Weiss, Barish, Thorne", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # ACT 4: Chirp Signal
    # ========================================
    hidden [void] RenderChirpSignal([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY, [double]$phase) {
        # Generate chirp waveform data
        if ($this.ChirpData.Count -eq 0 -or $this.State.TimeStep % 3 -eq 0) {
            if ($this.ChirpData.Count -lt 200) {
                $t = $this.ChirpData.Count / 200.0
                
                # Chirp: increasing frequency as merger approaches
                $freq = 30 + ($t * $t * 200)
                $amplitude = 0.3 + ($t * 0.7)
                
                # Generate signal point
                $signalValue = $amplitude * [math]::Sin(2 * [math]::PI * $freq * $t)
                [void]$this.ChirpData.Add($signalValue)
            }
        }
        
        # Draw waveform
        $waveformX = 50
        $waveformY = 100
        $waveformWidth = 600
        $waveformHeight = 200
        
        $this.DrawChirpWaveform($g, $waveformX, $waveformY, $waveformWidth, $waveformHeight, $this.ChirpData, $true)
        
        # Frequency vs time visualization
        $freqX = 50
        $freqY = 340
        $freqWidth = 600
        $freqHeight = 100
        
        # Background
        $freqBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 20, 20, 40))
        $g.FillRectangle($freqBg, $freqX, $freqY, $freqWidth, $freqHeight)
        $freqBg.Dispose()
        
        # Frequency curve (increasing)
        $freqPoints = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
        for ($i = 0; $i -lt 100; $i++) {
            $t = $i / 100.0
            $freq = 30 + ($t * $t * 200)
            $xPos = $freqX + ($i * $freqWidth / 100)
            $yPos = $freqY + $freqHeight - ($freq / 250.0 * $freqHeight)
            $freqPoints.Add([System.Drawing.Point]::new([int]$xPos, [int]$yPos))
        }
        
        if ($freqPoints.Count -gt 1) {
            $freqPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 200, 100), 3)
            $g.DrawLines($freqPen, $freqPoints.ToArray())
            $freqPen.Dispose()
        }
        
        # Labels
        $freqFont = New-Object System.Drawing.Font("Consolas", 9)
        $freqBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("Frequency", $freqFont, $freqBrush, $freqX + 5, $freqY + 5)
        $g.DrawString("Time →", $freqFont, $freqBrush, $freqX + $freqWidth - 50, $freqY + $freqHeight - 20)
        $freqFont.Dispose()
        $freqBrush.Dispose()
        
        # Stages annotation
        $stageFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
        $stageBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("INSPIRAL", $stageFont, $stageBrush, $waveformX + 50, $waveformY + $waveformHeight + 10)
        $g.DrawString("MERGER", $stageFont, $stageBrush, $waveformX + $waveformWidth * 0.75, $waveformY + $waveformHeight + 10)
        $g.DrawString("RINGDOWN", $stageFont, $stageBrush, $waveformX + $waveformWidth - 80, $waveformY + $waveformHeight + 10)
        $stageFont.Dispose()
        $stageBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 100))
        $g.DrawString("GRAVITATIONAL WAVE CHIRP", $infoFont, $infoBrush, 20, 20)
        $g.DrawString("Frequency increases as BHs approach", $infoFont, $infoBrush, 20, 45)
        $g.DrawString("'Chirp' sound when sonified", $infoFont, $infoBrush, 20, 70)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Audio representation
        $audioFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $audioBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("🔊 'Whoop!' sound", $audioFont, $audioBrush, $width - 200, 30)
        $audioFont.Dispose()
        $audioBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Chirp mass: M = (m₁m₂)³/⁵/(m₁+m₂)¹/⁵", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("f(t) ∝ (t_c - t)⁻³/⁸  (frequency increases!)", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Total duration: ~0.2 seconds for GW150914", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # Rendering Utility Methods
    # ========================================
    
    # Draw stars in background
    hidden [void] DrawStars([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $starRandom = New-Object System.Random(123)
        for ($i = 0; $i -lt 150; $i++) {
            $starX = $starRandom.Next(0, $width)
            $starY = $starRandom.Next(0, $height)
            $starSize = $starRandom.Next(1, 3)
            $starBrightness = $starRandom.Next(150, 255)
            $starColor = [System.Drawing.Color]::FromArgb($starBrightness, 255, 255, 255)
            $starBrush = New-Object System.Drawing.SolidBrush($starColor)
            $g.FillEllipse($starBrush, $starX, $starY, $starSize, $starSize)
            $starBrush.Dispose()
        }
    }
    
    # Draw spacetime grid with gravitational wave distortion
    hidden [void] DrawSpacetimeGrid([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$wavePhase, [double]$waveAmplitude) {
        $gridSpacing = 40
        $numLinesX = [int]($width / $gridSpacing) + 1
        $numLinesY = [int]($height / $gridSpacing) + 1
        
        # Vertical grid lines with wave distortion
        for ($i = 0; $i -lt $numLinesX; $i++) {
            $points = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            
            for ($y = 0; $y -le $height; $y += 5) {
                $x = $i * $gridSpacing
                
                # Gravitational wave distortion (+ polarization)
                $distortion = $waveAmplitude * [math]::Sin(2 * [math]::PI * $y / 150 + $wavePhase)
                $xDistorted = $x + $distortion * ($x - $width/2) / 100
                
                $points.Add([System.Drawing.Point]::new([int]$xDistorted, $y))
            }
            
            if ($points.Count -gt 1) {
                $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 100, 200, 255), 1)
                $g.DrawLines($gridPen, $points.ToArray())
                $gridPen.Dispose()
            }
        }
        
        # Horizontal grid lines
        for ($j = 0; $j -lt $numLinesY; $j++) {
            $points = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            
            for ($x = 0; $x -le $width; $x += 5) {
                $y = $j * $gridSpacing
                
                # Gravitational wave distortion (perpendicular)
                $distortion = $waveAmplitude * [math]::Sin(2 * [math]::PI * $x / 150 + $wavePhase)
                $yDistorted = $y - $distortion * ($y - $height/2) / 100
                
                $points.Add([System.Drawing.Point]::new($x, [int]$yDistorted))
            }
            
            if ($points.Count -gt 1) {
                $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 100, 200, 255), 1)
                $g.DrawLines($gridPen, $points.ToArray())
                $gridPen.Dispose()
            }
        }
    }
    
    # Draw black hole or neutron star
    hidden [void] DrawCompactObject([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$radius, [bool]$isBlackHole, [int]$mass) {
        if ($isBlackHole) {
            # Black hole - event horizon
            $horizonBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
            $g.FillEllipse($horizonBrush, $x - $radius, $y - $radius, $radius * 2, $radius * 2)
            $horizonBrush.Dispose()
            
            # Accretion disk glow
            for ($i = 0; $i -lt 4; $i++) {
                $glowRadius = $radius + 5 + ($i * 8)
                $glowAlpha = [int](150 * (1 - $i / 4.0))
                $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, 255, 150, 50)
                $glowPen = New-Object System.Drawing.Pen($glowColor, 3)
                $g.DrawEllipse($glowPen, $x - $glowRadius, $y - $glowRadius, $glowRadius * 2, $glowRadius * 2)
                $glowPen.Dispose()
            }
            
            # Event horizon outline
            $horizonPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 200, 100), 2)
            $g.DrawEllipse($horizonPen, $x - $radius, $y - $radius, $radius * 2, $radius * 2)
            $horizonPen.Dispose()
        } else {
            # Neutron star - bright surface
            $starBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 220, 255))
            $g.FillEllipse($starBrush, $x - $radius, $y - $radius, $radius * 2, $radius * 2)
            $starBrush.Dispose()
            
            # Magnetic field lines
            for ($i = 0; $i -lt 3; $i++) {
                $fieldRadius = $radius + 10 + ($i * 8)
                $fieldPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 150, 200, 255), 1)
                $fieldPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
                $g.DrawEllipse($fieldPen, $x - $fieldRadius, $y - $fieldRadius, $fieldRadius * 2, $fieldRadius * 2)
                $fieldPen.Dispose()
            }
        }
        
        # Mass label
        $massFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $massBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("${mass}M☉", $massFont, $massBrush, $x - 15, $y + $radius + 5)
        $massFont.Dispose()
        $massBrush.Dispose()
    }
    
    # Draw LIGO interferometer
    hidden [void] DrawLIGODetector([System.Drawing.Graphics]$g, [double]$centerX, [double]$centerY, [double]$armLength, [double]$strain) {
        $beamSplitter = 20
        
        # Beam splitter (center)
        $bsBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 150, 150, 150))
        $g.FillRectangle($bsBrush, $centerX - $beamSplitter/2, $centerY - $beamSplitter/2, $beamSplitter, $beamSplitter)
        $bsBrush.Dispose()
        
        # Horizontal arm (X-direction) - stretched by strain
        $xArmLength = $armLength * (1 + $strain)
        $armPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 100, 200, 255), 8)
        $g.DrawLine($armPen, $centerX, $centerY, $centerX + $xArmLength, $centerY)
        $armPen.Dispose()
        
        # End mirror X
        $mirrorBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Silver)
        $g.FillRectangle($mirrorBrush, $centerX + $xArmLength - 5, $centerY - 15, 10, 30)
        $mirrorBrush.Dispose()
        
        # Vertical arm (Y-direction) - compressed by strain
        $yArmLength = $armLength * (1 - $strain)
        $armPen2 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 100, 200, 255), 8)
        $g.DrawLine($armPen2, $centerX, $centerY, $centerX, $centerY - $yArmLength)
        $armPen2.Dispose()
        
        # End mirror Y
        $mirrorBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Silver)
        $g.FillRectangle($mirrorBrush2, $centerX - 15, $centerY - $yArmLength - 5, 30, 10)
        $mirrorBrush2.Dispose()
        
        # Laser beams
        $laserPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 0, 0), 2)
        $g.DrawLine($laserPen, $centerX, $centerY, $centerX + $xArmLength, $centerY)
        $g.DrawLine($laserPen, $centerX, $centerY, $centerX, $centerY - $yArmLength)
        $laserPen.Dispose()
        
        # Labels
        $labelFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("LIGO", $labelFont, $labelBrush, $centerX - 25, $centerY + 25)
        $labelFont.Dispose()
        $labelBrush.Dispose()
        
        # Arm length labels
        $armFont = New-Object System.Drawing.Font("Consolas", 8)
        $armBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("4 km", $armFont, $armBrush, $centerX + $xArmLength/2 - 15, $centerY + 15)
        $g.DrawString("4 km", $armFont, $armBrush, $centerX + 15, $centerY - $yArmLength/2)
        $armFont.Dispose()
        $armBrush.Dispose()
    }
    
    # Draw chirp waveform
    hidden [void] DrawChirpWaveform([System.Drawing.Graphics]$g, [int]$x, [int]$y, [int]$width, [int]$height, [System.Collections.ArrayList]$data, [bool]$highlightEnd) {
        # Draw axes
        $axisPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2)
        $g.DrawLine($axisPen, $x, $y + $height/2, $x + $width, $y + $height/2)
        $axisPen.Dispose()
        
        # Draw waveform
        if ($data.Count -gt 1) {
            $points = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
            
            for ($i = 0; $i -lt $data.Count; $i++) {
                $xPos = $x + ($i * $width / $data.Count)
                $yPos = $y + $height/2 - ($data[$i] * $height / 2)
                $points.Add([System.Drawing.Point]::new([int]$xPos, [int]$yPos))
            }
            
            if ($points.Count -gt 1) {
                $waveformPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0, 255, 150), 2)
                $g.DrawLines($waveformPen, $points.ToArray())
                $waveformPen.Dispose()
            }
            
            # Highlight merger region
            if ($highlightEnd -and $data.Count -gt 20) {
                $highlightX = $x + $width * 0.8
                $highlightBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 255, 255, 0))
                $g.FillRectangle($highlightBrush, $highlightX, $y, $width * 0.2, $height)
                $highlightBrush.Dispose()
                
                $mergerFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
                $mergerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
                $g.DrawString("MERGER", $mergerFont, $mergerBrush, $highlightX + 10, $y + 10)
                $mergerFont.Dispose()
                $mergerBrush.Dispose()
            }
        }
        
        # Axis labels
        $labelFont = New-Object System.Drawing.Font("Consolas", 9)
        $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("Time →", $labelFont, $labelBrush, $x + $width - 50, $y + $height/2 + 5)
        $g.DrawString("Strain", $labelFont, $labelBrush, $x + 5, $y + 5)
        $labelFont.Dispose()
        $labelBrush.Dispose()
    }
    
    # Render title overlay
    hidden [void] RenderTitle([System.Drawing.Graphics]$g, [int]$width, [int]$currentAct) {
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 150, 220, 255))
        
        $actNames = @("", "✨ ACT 1: SPACETIME RIPPLES", "✨ ACT 2: BINARY MERGER", "✨ ACT 3: LIGO DETECTION", "✨ ACT 4: CHIRP SIGNAL")
        $titleText = "SHOW58: " + $actNames[$currentAct]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show58 {
    Write-Host "[Show58] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show58")) {
        $show = $Global:ShowManager.Shows["show58"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show58] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow58 class loaded (v3)" -ForegroundColor Green
