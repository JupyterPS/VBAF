# ===============================
# HQshow53.ps1 — Wave Diffraction & Huygens Principle v3
# Wave Physics Theater: The Wave Nature of Light
# Converted to Game Machine Architecture
# ===============================

Write-Host "`n=> _____ HQshow53 (Wave Diffraction v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show53 - Inherits from BaseShow
# ============================================
class Show53 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Wavelets
    hidden [System.Collections.ArrayList] $Photons
    hidden [int] $TickCounter
    
    # ========================================
    # Constructor
    # ========================================
    Show53([System.Windows.Forms.Panel]$panel) : base("show53", $panel) {
        # Initialize state
        $this.State = @{
            TimeStep = 0
            Act = 1  # 1=Single Slit, 2=Double Slit, 3=Huygens, 4=Grating
            ActTimer = 0
            WavePhase = 0
        }
        
        # Initialize collections
        $this.Wavelets = [System.Collections.ArrayList]::new()
        $this.Photons = [System.Collections.ArrayList]::new()
        $this.TickCounter = 0
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  🌊 [Show53] Initializing Wave Diffraction..." -ForegroundColor Cyan
        
        # Clear and setup panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 15)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { 
            $prop.SetValue($this.Panel, $true, $null)
        }
        
        # Update ticker messages
        $Show53Messages = @(
            "🌊 WAVE DIFFRACTION & HUYGENS PRINCIPLE - The Wave Nature of Light",
            "🔦 Single slit: Light bends around edges, creates pattern",
            "👥 Double slit: Wave interference creates bright and dark fringes",
            "💫 Huygens Principle: Every point on a wavefront is a new source",
            "🎯 Diffraction proves light behaves as a wave!"
        )
        $Global:messages = $Show53Messages
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host "  ✅ [Show53] Diffraction engine and wavelet simulation ready" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM (~50ms)
    [void] OnUpdate() {
        $this.TickCounter++
        $this.State.TimeStep++
        $this.State.ActTimer++
        $this.State.WavePhase += 0.12
        
        if ($this.State.WavePhase -gt 6.28) {
            $this.State.WavePhase = 0
        }
        
        # Act transitions
        if ($this.State.ActTimer -gt 180) {
            $this.State.Act++
            if ($this.State.Act -gt 4) { 
                $this.State.Act = 1 
            }
            $this.State.ActTimer = 0
            $this.State.TimeStep = 0
            $this.State.WavePhase = 0
            $this.Wavelets.Clear()
            $this.Photons.Clear()
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [Show53] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        if ($this.Wavelets) { $this.Wavelets.Clear() }
        if ($this.Photons) { $this.Photons.Clear() }
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.ActTimer = 0
        $this.State.Act = 1
        $this.State.WavePhase = 0
        $this.TickCounter = 0
        
        Write-Host "  ✅ [Show53] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Setup paint event
    hidden [void] SetupPaintEvent() {
        # CRITICAL: Capture $this as $self
        $self = $this
        
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderScene($s, $e.Graphics)
        }.GetNewClosure())
    }
    
    # Main render method
    hidden [void] RenderScene([object]$sender, [System.Drawing.Graphics]$g) {
        $width = $sender.Width
        $height = $sender.Height
        
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Background
        $this.DrawBackground($g, $width, $height)
        
        # Draw based on current act
        switch ($this.State.Act) {
            1 { $this.DrawSingleSlitAct($g, $width, $height) }
            2 { $this.DrawDoubleSlitAct($g, $width, $height) }
            3 { $this.DrawHuygensAct($g, $width, $height) }
            4 { $this.DrawGratingAct($g, $width, $height) }
        }
        
        # Draw title
        $this.DrawTitle($g, $width)
    }
    
    # Draw background
    hidden [void] DrawBackground([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(5, 5, 15),
            [System.Drawing.Color]::FromArgb(15, 10, 25)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
    }
    
    # Act 1: Single slit diffraction
    hidden [void] DrawSingleSlitAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $centerY = $height / 2
        $slitX = 200
        $slitWidth = 15
        $slitHeight = 40
        $slitY = $centerY - $slitHeight / 2
        $wavelength = 20
        $phase = $this.State.WavePhase
        
        # Incoming wave
        for ($x = 50; $x -lt $slitX; $x += 3) {
            $waveY = $centerY + 60 * [math]::Sin(2 * [math]::PI * $x / $wavelength + $phase)
            $alpha = [int](150 * (1 - ($x - 50) / 150.0))
            $waveColor = [System.Drawing.Color]::FromArgb($alpha, 100, 200, 255)
            $waveBrush = New-Object System.Drawing.SolidBrush($waveColor)
            $g.FillEllipse($waveBrush, $x - 2, $waveY - 2, 4, 4)
            $waveBrush.Dispose()
        }
        
        # Draw slit
        $this.DrawSlit($g, $slitX, $centerY - 200, $slitY, $slitHeight, 10)
        
        # Diffracted waves
        for ($i = 0; $i -lt 8; $i++) {
            $radius = 30 + ($i * 25) + ($phase * 5) % 25
            $alpha = [int](120 * (1 - $i / 8.0))
            $arcColor = [System.Drawing.Color]::FromArgb($alpha, 150, 220, 255)
            $arcPen = New-Object System.Drawing.Pen($arcColor, 2)
            
            $arcRect = [System.Drawing.Rectangle]::new($slitX + 10 - $radius, $centerY - $radius, $radius * 2, $radius * 2)
            $g.DrawArc($arcPen, $arcRect, -60, 120)
            $arcPen.Dispose()
        }
        
        # Intensity pattern on screen
        $screenX = 500
        $this.DrawIntensityPattern($g, $screenX, $centerY - 150, 50, 300, $slitHeight, $wavelength, "single", 0) 
   
        # Screen
        $screenPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 255, 255, 255), 3)
        $g.DrawLine($screenPen, $screenX, $centerY - 200, $screenX, $centerY + 200)
        $screenPen.Dispose()
        
        # Info
        $this.DrawInfoBox($g, $height, @(
            "SINGLE SLIT DIFFRACTION",
            "Slit width: a = $slitHeight units",
            "Central maximum + side minima"
        ), [System.Drawing.Color]::Cyan, @(
            "Minima: a·sin(θ) = m·λ  (m = ±1, ±2, ...)",
            "Intensity: I(θ) = I₀·[sin(β)/β]²"
        ))
    }
    
    # Act 2: Double slit interference
    hidden [void] DrawDoubleSlitAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $centerY = $height / 2
        $slitX = 200
        $slitWidth = 10
        $slitHeight = 20
        $slitSeparation = 80
        $slit1Y = $centerY - $slitSeparation / 2 - $slitHeight / 2
        $slit2Y = $centerY + $slitSeparation / 2 - $slitHeight / 2
        $wavelength = 20
        $phase = $this.State.WavePhase
        
        # Incoming wave
        for ($x = 50; $x -lt $slitX; $x += 3) {
            $waveY1 = $slit1Y + $slitHeight/2 + 40 * [math]::Sin(2 * [math]::PI * $x / $wavelength + $phase)
            $waveY2 = $slit2Y + $slitHeight/2 + 40 * [math]::Sin(2 * [math]::PI * $x / $wavelength + $phase)
            
            $alpha = [int](150 * (1 - ($x - 50) / 150.0))
            $waveColor = [System.Drawing.Color]::FromArgb($alpha, 100, 255, 150)
            $waveBrush = New-Object System.Drawing.SolidBrush($waveColor)
            $g.FillEllipse($waveBrush, $x - 2, $waveY1 - 2, 4, 4)
            $g.FillEllipse($waveBrush, $x - 2, $waveY2 - 2, 4, 4)
            $waveBrush.Dispose()
        }
        
        # Draw double slit
        $this.DrawDoubleSlit($g, $slitX, $centerY - 200, $slit1Y, $slit2Y, $slitHeight, 10)
        
        # Interfering waves
        for ($i = 0; $i -lt 8; $i++) {
            $radius = 30 + ($i * 25) + ($phase * 5) % 25
            $alpha = [int](100 * (1 - $i / 8.0))
            
            # From slit 1
            $arc1Color = [System.Drawing.Color]::FromArgb($alpha, 150, 255, 150)
            $arc1Pen = New-Object System.Drawing.Pen($arc1Color, 1.5)
            $arc1Rect = [System.Drawing.Rectangle]::new($slitX + 10 - $radius, $slit1Y + $slitHeight/2 - $radius, $radius * 2, $radius * 2)
            $g.DrawArc($arc1Pen, $arc1Rect, -60, 120)
            $arc1Pen.Dispose()
            
            # From slit 2
            $arc2Color = [System.Drawing.Color]::FromArgb($alpha, 255, 150, 150)
            $arc2Pen = New-Object System.Drawing.Pen($arc2Color, 1.5)
            $arc2Rect = [System.Drawing.Rectangle]::new($slitX + 10 - $radius, $slit2Y + $slitHeight/2 - $radius, $radius * 2, $radius * 2)
            $g.DrawArc($arc2Pen, $arc2Rect, -60, 120)
            $arc2Pen.Dispose()
        }
                
        # Interference pattern
        $screenX = 500
        $this.DrawIntensityPattern($g, $screenX, $centerY - 150, 50, 300, $slitHeight, $wavelength, "double", $slitSeparation)
        
        # Screen
        $screenPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 255, 255, 255), 3)
        $g.DrawLine($screenPen, $screenX, $centerY - 200, $screenX, $centerY + 200)
        $screenPen.Dispose()
        
        # Info
        $this.DrawInfoBox($g, $height, @(
            "DOUBLE SLIT INTERFERENCE",
            "Slit separation: d = $slitSeparation units",
            "Bright and dark fringes!"
        ), [System.Drawing.Color]::Lime, @(
            "Bright fringes: d·sin(θ) = m·λ  (m = 0, ±1, ±2, ...)",
            "Dark fringes: d·sin(θ) = (m+½)·λ"
        ))
    }
    
    # Act 3: Huygens wavelets
    hidden [void] DrawHuygensAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $phase = $this.State.WavePhase
        
        # Primary wavefront
        $wavefrontX = 150 + ($phase * 3) % 300
        $wavefrontPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 100, 200, 255), 3)
        $g.DrawLine($wavefrontPen, $wavefrontX, 100, $wavefrontX, $height - 100)
        $wavefrontPen.Dispose()
        
        # Huygens wavelets
        $numWavelets = 12
        for ($i = 0; $i -lt $numWavelets; $i++) {
            $waveletY = 100 + ($i * ($height - 200) / ($numWavelets - 1))
            
            # Point source
            $sourceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            $g.FillEllipse($sourceBrush, $wavefrontX - 4, $waveletY - 4, 8, 8)
            $sourceBrush.Dispose()
            
            # Wavelets
            for ($r = 1; $r -lt 6; $r++) {
                $radius = $r * 25 + (($phase * 5) % 25)
                $alpha = [int](120 * (1 - $r / 6.0))
                $waveletColor = [System.Drawing.Color]::FromArgb($alpha, 150, 200, 255)
                $waveletPen = New-Object System.Drawing.Pen($waveletColor, 1.5)
                $g.DrawEllipse($waveletPen, $wavefrontX - $radius, $waveletY - $radius, $radius * 2, $radius * 2)
                $waveletPen.Dispose()
            }
        }
        
        # Envelope (new wavefront)
        $envelopeX = $wavefrontX + 125
        if ($envelopeX -lt $width - 50) {
            $envelopePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 150, 100), 3)
            $envelopePen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            $g.DrawLine($envelopePen, $envelopeX, 100, $envelopeX, $height - 100)
            $envelopePen.Dispose()
        }
        
        # Info
        $this.DrawInfoBox($g, $height, @(
            "HUYGENS PRINCIPLE",
            "Every point is a new wave source",
            "Wavelets create next wavefront"
        ), [System.Drawing.Color]::Cyan, @(
            "Huygens-Fresnel Principle:",
            "Each point on a wavefront acts as a source",
            "of secondary spherical wavelets."
        ))
    }
    
    # Act 4: Diffraction grating
    hidden [void] DrawGratingAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $centerY = $height / 2
        $gratingX = 200
        $numSlits = 8
        $slitHeight = 15
        $slitSpacing = 40
        $wavelength = 20
        $phase = $this.State.WavePhase
        $startY = $centerY - ($numSlits * $slitSpacing) / 2
        
        # Incoming wave
        for ($x = 50; $x -lt $gratingX; $x += 3) {
            for ($i = 0; $i -lt $numSlits; $i++) {
                $slitCenterY = $startY + ($i * $slitSpacing) + $slitHeight / 2
                $waveY = $slitCenterY + 25 * [math]::Sin(2 * [math]::PI * $x / $wavelength + $phase)
                
                $alpha = [int](120 * (1 - ($x - 50) / 150.0))
                $waveColor = [System.Drawing.Color]::FromArgb($alpha, 255, 100, 255)
                $waveBrush = New-Object System.Drawing.SolidBrush($waveColor)
                $g.FillEllipse($waveBrush, $x - 2, $waveY - 2, 4, 4)
                $waveBrush.Dispose()
            }
        }
        
        # Draw grating
        $barrierBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 60, 60, 60))
        $g.FillRectangle($barrierBrush, $gratingX, $centerY - 200, 10, 400)
        $barrierBrush.Dispose()
        
        $slitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Magenta, 2)
        for ($i = 0; $i -lt $numSlits; $i++) {
            $slitY = $startY + ($i * $slitSpacing)
            $g.DrawRectangle($slitPen, $gratingX, $slitY, 10, $slitHeight)
        }
        $slitPen.Dispose()
        
        # Diffracted waves
        for ($i = 0; $i -lt $numSlits; $i++) {
            $slitCenterY = $startY + ($i * $slitSpacing) + $slitHeight / 2
            
            for ($r = 0; $r -lt 5; $r++) {
                $radius = 30 + ($r * 30) + ($phase * 6) % 30
                $alpha = [int](80 * (1 - $r / 5.0))
                $diffColor = [System.Drawing.Color]::FromArgb($alpha, 200, 100, 255)
                $diffPen = New-Object System.Drawing.Pen($diffColor, 1)
                
                $arcRect = [System.Drawing.Rectangle]::new($gratingX + 10 - $radius, $slitCenterY - $radius, $radius * 2, $radius * 2)
                $g.DrawArc($diffPen, $arcRect, -50, 100)
                $diffPen.Dispose()
            }
        }
        
        # Screen and maxima
        $screenX = 520
        $screenPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 255, 255, 255), 3)
        $g.DrawLine($screenPen, $screenX, $centerY - 200, $screenX, $centerY + 200)
        $screenPen.Dispose()
        
        # Grating orders
        for ($m = -3; $m -le 3; $m++) {
            $angle = [math]::Asin($m * $wavelength / $slitSpacing)
            if ([math]::Abs($angle) -lt 1.0) {
                $screenY = $centerY + ($angle * 150)
                $spotBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 100, 255))
                $g.FillEllipse($spotBrush, $screenX - 5, $screenY - 10, 10, 20)
                $spotBrush.Dispose()
                
                $orderFont = New-Object System.Drawing.Font("Consolas", 8)
                $orderBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $g.DrawString("m=$m", $orderFont, $orderBrush, $screenX + 15, $screenY - 5)
                $orderFont.Dispose()
                $orderBrush.Dispose()
            }
        }
        
        # Info
        $this.DrawInfoBox($g, $height, @(
            "DIFFRACTION GRATING",
            "$numSlits slits, spacing d = $slitSpacing",
            "Sharp, bright maxima!"
        ), [System.Drawing.Color]::Magenta, @(
            "Grating equation: d·sin(θ) = m·λ",
            "Sharp maxima, useful for spectroscopy!"
        ))
    }
    
    # Draw slit aperture
    hidden [void] DrawSlit([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$slitY, [double]$slitHeight, [double]$width) {
        $barrierBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 80, 80, 80))
        $g.FillRectangle($barrierBrush, $x, $y, $width, $slitY - $y)
        $g.FillRectangle($barrierBrush, $x, $slitY + $slitHeight, $width, ($y + 400) - ($slitY + $slitHeight))
        $barrierBrush.Dispose()
        
        $slitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
        $g.DrawLine($slitPen, $x, $slitY, $x + $width, $slitY)
        $g.DrawLine($slitPen, $x, $slitY + $slitHeight, $x + $width, $slitY + $slitHeight)
        $slitPen.Dispose()
    }
    
    # Draw double slit aperture
    hidden [void] DrawDoubleSlit([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$slit1Y, [double]$slit2Y, [double]$slitHeight, [double]$width) {
        $barrierBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 80, 80, 80))
        $g.FillRectangle($barrierBrush, $x, $y, $width, $slit1Y - $y)
        $g.FillRectangle($barrierBrush, $x, $slit1Y + $slitHeight, $width, $slit2Y - ($slit1Y + $slitHeight))
        $g.FillRectangle($barrierBrush, $x, $slit2Y + $slitHeight, $width, ($y + 400) - ($slit2Y + $slitHeight))
        $barrierBrush.Dispose()
        
        $slitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
        $g.DrawRectangle($slitPen, $x, $slit1Y, $width, $slitHeight)
        $g.DrawRectangle($slitPen, $x, $slit2Y, $width, $slitHeight)
        $slitPen.Dispose()
    }
    
    # Draw intensity pattern on screen
    hidden [void] DrawIntensityPattern([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$width, [double]$height, [double]$slitWidth, [double]$wavelength, [string]$type, [double]$slitSeparation = 0) {
        $numPoints = 200
        $maxAngle = 0.3
        
        for ($i = 0; $i -lt $numPoints; $i++) {
            $angle = -$maxAngle + (2 * $maxAngle * $i / $numPoints)
            
            if ($type -eq "single") {
                $intensity = $this.GetSingleSlitIntensity($angle, $slitWidth, $wavelength)
            } else {
                $intensity = $this.GetDoubleSlitIntensity($angle, $slitWidth, $slitSeparation, $wavelength)
            }
            
            $screenY = $y + ($angle / $maxAngle) * $height / 2
            $brightness = [math]::Max(0, [math]::Min(255, $intensity * 255))
            
            $color = [System.Drawing.Color]::FromArgb(255, $brightness, $brightness, [math]::Min(255, $brightness + 100))
            $pen = New-Object System.Drawing.Pen($color, 3)
            $g.DrawLine($pen, $x, $screenY, $x + $width, $screenY)
            $pen.Dispose()
        }
    }
    
    # Calculate single slit intensity
    hidden [double] GetSingleSlitIntensity([double]$angle, [double]$slitWidth, [double]$wavelength) {
        $beta = [math]::PI * $slitWidth * [math]::Sin($angle) / $wavelength
        if ([math]::Abs($beta) -lt 0.001) {
            return 1.0
        }
        $sinc = [math]::Sin($beta) / $beta
        return $sinc * $sinc
    }
    
    # Calculate double slit intensity
    hidden [double] GetDoubleSlitIntensity([double]$angle, [double]$slitWidth, [double]$slitSeparation, [double]$wavelength) {
        $beta = [math]::PI * $slitWidth * [math]::Sin($angle) / $wavelength
        $alpha = [math]::PI * $slitSeparation * [math]::Sin($angle) / $wavelength
        
        $envelope = 1.0
        if ([math]::Abs($beta) -gt 0.001) {
            $sinc = [math]::Sin($beta) / $beta
            $envelope = $sinc * $sinc
        }
        
        $interference = [math]::Cos($alpha)
        return $envelope * $interference * $interference
    }
    
    # Draw info box
    hidden [void] DrawInfoBox([System.Drawing.Graphics]$g, [int]$height, [string[]]$infoLines, [System.Drawing.Color]$color, [string[]]$mathLines) {
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush($color)
        
        $y = 80
        foreach ($line in $infoLines) {
            $g.DrawString($line, $infoFont, $infoBrush, 20, $y)
            $y += 25
        }
        
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math
        $mathFont = New-Object System.Drawing.Font("Consolas", 10)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        
        $y = $height - 60
        foreach ($line in $mathLines) {
            $g.DrawString($line, $mathFont, $mathBrush, 20, $y)
            $y += 20
        }
        
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # Draw title
    hidden [void] DrawTitle([System.Drawing.Graphics]$g, [int]$width) {
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 150, 220, 255))
        
        $actNames = @("", "✨ ACT 1: SINGLE SLIT", "✨ ACT 2: DOUBLE SLIT", "✨ ACT 3: HUYGENS WAVELETS", "✨ ACT 4: DIFFRACTION GRATING")
        $titleText = "SHOW53: " + $actNames[$this.State.Act]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show53 {
    Write-Host "[Show53] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show53")) {
        $show = $Global:ShowManager.Shows["show53"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show53] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow53 class loaded (v3)" -ForegroundColor Green
