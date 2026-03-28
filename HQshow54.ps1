# ===============================
# HQshow54.ps1 — Acoustic Resonance Chamber v3
# Wave Physics Theater: Musical Instruments Come Alive
# Converted to Game Machine Architecture
# ===============================

Write-Host "`n=> _____ HQshow54 (Acoustic Resonance v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show54 - Inherits from BaseShow
# ============================================
class Show54 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $PressurePoints
    hidden [int] $TickCounter
    
    # ========================================
    # Constructor
    # ========================================
    Show54([System.Windows.Forms.Panel]$panel) : base("show54", $panel) {
        # Initialize state
        $this.State = @{
            TimeStep = 0
            Act = 1  # 1=String, 2=Open Pipe, 3=Closed Pipe, 4=Helmholtz
            ActTimer = 0
            WavePhase = 0
            HarmonicNumber = 1
            ResonanceIntensity = 0
        }
        
        # Initialize collections
        $this.PressurePoints = [System.Collections.ArrayList]::new()
        $this.TickCounter = 0
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  🎸 [Show54] Initializing Acoustic Resonance Chamber..." -ForegroundColor Cyan
        
        # Clear and setup panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(20, 15, 25)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { 
            $prop.SetValue($this.Panel, $true, $null)
        }
        
        # Update ticker messages
        $Show54Messages = @(
            "🎸 ACOUSTIC RESONANCE CHAMBER - Musical Instruments Come Alive!",
            "🎻 Vibrating strings: Guitars, violins create standing waves",
            "🎺 Open pipes: Flutes, organ pipes resonate at harmonics",
            "🎷 Closed pipes: Clarinets use odd harmonics only",
            "🏺 Helmholtz resonators: Bottles, drums have special frequencies"
        )
        $Global:messages = $Show54Messages
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host "  ✅ [Show54] Acoustic resonance simulation ready" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM (~50ms)
    [void] OnUpdate() {
        $this.TickCounter++
        $this.State.TimeStep++
        $this.State.ActTimer++
        $this.State.WavePhase += 0.15
        
        if ($this.State.WavePhase -gt 6.28) {
            $this.State.WavePhase = 0
        }
        
        # Cycle harmonics
        if ($this.State.TimeStep % 90 -eq 0) {
            $this.State.HarmonicNumber++
            if ($this.State.HarmonicNumber -gt 4) {
                $this.State.HarmonicNumber = 1
            }
        }
        
        # Act transitions
        if ($this.State.ActTimer -gt 200) {
            $this.State.Act++
            if ($this.State.Act -gt 4) { 
                $this.State.Act = 1 
            }
            $this.State.ActTimer = 0
            $this.State.TimeStep = 0
            $this.State.WavePhase = 0
            $this.State.HarmonicNumber = 1
            $this.PressurePoints.Clear()
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [Show54] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        if ($this.PressurePoints) { $this.PressurePoints.Clear() }
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.ActTimer = 0
        $this.State.Act = 1
        $this.State.WavePhase = 0
        $this.State.HarmonicNumber = 1
        $this.TickCounter = 0
        
        Write-Host "  ✅ [Show54] Cleanup complete" -ForegroundColor Green
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
            1 { $this.DrawVibratingStringAct($g, $width, $height) }
            2 { $this.DrawOpenPipeAct($g, $width, $height) }
            3 { $this.DrawClosedPipeAct($g, $width, $height) }
            4 { $this.DrawHelmholtzAct($g, $width, $height) }
        }
        
        # Draw title
        $this.DrawTitle($g, $width)
    }
    
    # Draw background
    hidden [void] DrawBackground([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(20, 15, 25),
            [System.Drawing.Color]::FromArgb(35, 20, 40)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
    }
    
    # Act 1: Vibrating string (guitar/violin)
    hidden [void] DrawVibratingStringAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $centerY = $height / 2
        $stringX1 = 100
        $stringX2 = 600
        $stringY = $centerY
        $harmonic = $this.State.HarmonicNumber
        $phase = $this.State.WavePhase
        
        # Support points
        $supportBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 50, 20))
        $g.FillRectangle($supportBrush, $stringX1 - 5, $stringY - 40, 10, 80)
        $g.FillRectangle($supportBrush, $stringX2 - 5, $stringY - 40, 10, 80)
        $supportBrush.Dispose()
        
        # Draw main string
        $this.DrawVibratingString($g, $stringX1, $stringY, $stringX2, $harmonic, $phase, 50)
        
        # Preview harmonics
        $previewY = 100
        for ($h = 1; $h -le 4; $h++) {
            $previewX1 = 80
            $previewX2 = 180
            $isCurrentHarmonic = ($h -eq $harmonic)
            
            if ($isCurrentHarmonic) {
                $previewBox = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
                $g.DrawRectangle($previewBox, $previewX1 - 10, $previewY - 15, 120, 40)
                $previewBox.Dispose()
            }
            
            $this.DrawVibratingString($g, $previewX1, $previewY, $previewX2, $h, 0, 10)
            
            $hFont = New-Object System.Drawing.Font("Consolas", 9)
            $hBrush = New-Object System.Drawing.SolidBrush($(if ($isCurrentHarmonic) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::Gray }))
            $g.DrawString("n=$h", $hFont, $hBrush, $previewX2 + 10, $previewY - 5)
            $hFont.Dispose()
            $hBrush.Dispose()
            
            $previewY += 45
        }
        
        # Info
        $this.DrawInfoBox($g, $height, @(
            "VIBRATING STRING",
            "Harmonic n = $harmonic",
            "Nodes: Red (N)  |  Antinodes: Cyan (A)"
        ), [System.Drawing.Color]::FromArgb(255, 255, 200, 100), 250, @(
            "Standing wave: y(x,t) = A·sin(nπx/L)·cos(ωt)",
            "Frequency: f_n = (n/2L)·√(T/μ)",
            "Guitar, violin, piano strings!"
        ))
    }
    
    # Act 2: Open pipe (flute/organ)
    hidden [void] DrawOpenPipeAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $pipeX = 250
        $pipeY = 100
        $pipeWidth = 100
        $pipeHeight = 350
        $harmonic = $this.State.HarmonicNumber
        $phase = $this.State.WavePhase
        
        # Draw main pipe
        $this.DrawPipeResonance($g, $pipeX, $pipeY, $pipeWidth, $pipeHeight, $harmonic, $phase, $true)
        
        # Preview harmonics
        $previewX = 450
        $previewY = 120
        for ($h = 1; $h -le 4; $h++) {
            $isCurrentHarmonic = ($h -eq $harmonic)
            
            if ($isCurrentHarmonic) {
                $previewBox = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
                $g.DrawRectangle($previewBox, $previewX - 5, $previewY - 5, 60, 90)
                $previewBox.Dispose()
            }
            
            $this.DrawPipeResonance($g, $previewX, $previewY, 50, 80, $h, 0, $true)
            
            $hFont = New-Object System.Drawing.Font("Consolas", 9)
            $hBrush = New-Object System.Drawing.SolidBrush($(if ($isCurrentHarmonic) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::Gray }))
            $g.DrawString("n=$h", $hFont, $hBrush, $previewX + 55, $previewY + 35)
            $hFont.Dispose()
            $hBrush.Dispose()
            
            $previewY += 95
        }
        
        # Info
        $this.DrawInfoBox($g, $height, @(
            "OPEN PIPE RESONANCE",
            "Harmonic n = $harmonic",
            "Both ends OPEN (pressure nodes)",
            "Red = Compression, Blue = Rarefaction"
        ), [System.Drawing.Color]::Lime, 50, @(
            "Open pipe: f_n = n·v/(2L)  (n = 1, 2, 3, ...)",
            "All harmonics present!",
            "Flute, organ pipes, pan flute"
        ))
    }
    
    # Act 3: Closed pipe (clarinet)
    hidden [void] DrawClosedPipeAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $pipeX = 250
        $pipeY = 100
        $pipeWidth = 100
        $pipeHeight = 350
        $harmonic = $this.State.HarmonicNumber
        $phase = $this.State.WavePhase
        
        # Only odd harmonics
        $oddHarmonic = (2 * $harmonic) - 1
        
        # Draw main pipe
        $this.DrawPipeResonance($g, $pipeX, $pipeY, $pipeWidth, $pipeHeight, $oddHarmonic, $phase, $false)
        
        # Preview odd harmonics
        $previewX = 450
        $previewY = 120
        for ($h = 1; $h -le 4; $h++) {
            $oddH = (2 * $h) - 1
            $isCurrentHarmonic = ($h -eq $harmonic)
            
            if ($isCurrentHarmonic) {
                $previewBox = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
                $g.DrawRectangle($previewBox, $previewX - 5, $previewY - 5, 60, 90)
                $previewBox.Dispose()
            }
            
            $this.DrawPipeResonance($g, $previewX, $previewY, 50, 80, $oddH, 0, $false)
            
            $hFont = New-Object System.Drawing.Font("Consolas", 9)
            $hBrush = New-Object System.Drawing.SolidBrush($(if ($isCurrentHarmonic) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::Gray }))
            $g.DrawString("n=$oddH", $hFont, $hBrush, $previewX + 55, $previewY + 35)
            $hFont.Dispose()
            $hBrush.Dispose()
            
            $previewY += 95
        }
        
        # Info
        $this.DrawInfoBox($g, $height, @(
            "CLOSED PIPE RESONANCE",
            "Harmonic n = $oddHarmonic",
            "One end CLOSED (pressure antinode)",
            "Only ODD harmonics! (1, 3, 5, 7...)"
        ), [System.Drawing.Color]::FromArgb(255, 255, 100, 100), 50, @(
            "Closed pipe: f_n = n·v/(4L)  (n = 1, 3, 5, 7, ...)",
            "Only odd harmonics - unique timbre!",
            "Clarinet, some organ stops"
        ))
    }
    
    # Act 4: Helmholtz resonator
    hidden [void] DrawHelmholtzAct([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $phase = $this.State.WavePhase
        
        # Three resonators
        $resonatorData = @(
            @{X=100; Y=150; Size=120; Label="Low freq"},
            @{X=280; Y=170; Size=90; Label="Mid freq"},
            @{X=420; Y=190; Size=60; Label="High freq"}
        )
        
        $resonatingIndex = ([math]::Floor($this.State.TimeStep / 60)) % 3
        
        for ($i = 0; $i -lt 3; $i++) {
            $res = $resonatorData[$i]
            $isActive = ($i -eq $resonatingIndex)
            $this.DrawHelmholtzResonator($g, $res.X, $res.Y, $res.Size, $phase, $isActive)
            
            $lblFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $lblBrush = New-Object System.Drawing.SolidBrush($(if ($isActive) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::Gray }))
            $g.DrawString($res.Label, $lblFont, $lblBrush, $res.X + 10, $res.Y + $res.Size + 20)
            $lblFont.Dispose()
            $lblBrush.Dispose()
        }
        
        # Info
        $this.DrawInfoBox($g, $height, @(
            "HELMHOLTZ RESONATOR",
            "Air in neck oscillates like mass on spring",
            "Each cavity has ONE natural frequency",
            "Larger cavity = Lower frequency"
        ), [System.Drawing.Color]::FromArgb(255, 255, 200, 100), 50, @(
            "Helmholtz frequency: f = (v/2π)·√(A/(V·L))",
            "A=neck area, V=cavity volume, L=neck length",
            "Bottles, drums, acoustic bass traps!"
        ))
    }
    
    # Draw vibrating string with nodes/antinodes
    hidden [void] DrawVibratingString([System.Drawing.Graphics]$g, [double]$x1, [double]$y, [double]$x2, [int]$harmonic, [double]$phase, [double]$amplitude) {
        $length = $x2 - $x1
        $numPoints = 200
        $points = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
        
        for ($i = 0; $i -le $numPoints; $i++) {
            $xPos = $x1 + ($i * $length / $numPoints)
            $relativeX = ($xPos - $x1) / $length
            $displacement = $amplitude * [math]::Sin($harmonic * [math]::PI * $relativeX) * [math]::Cos($phase)
            $yPos = $y + $displacement
            $points.Add([System.Drawing.Point]::new([int]$xPos, [int]$yPos))
        }
        
        if ($points.Count -gt 1) {
            # Shadow
            $shadowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 0, 0, 0), 4)
            $g.DrawLines($shadowPen, $points.ToArray())
            $shadowPen.Dispose()
            
            # Main string
            $stringPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 200, 100), 3)
            $g.DrawLines($stringPen, $points.ToArray())
            $stringPen.Dispose()
        }
        
        # Nodes (don't move)
        for ($n = 0; $n -le $harmonic; $n++) {
            $nodeX = $x1 + ($n * $length / $harmonic)
            $nodeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
            $g.FillEllipse($nodeBrush, $nodeX - 5, $y - 5, 10, 10)
            $nodeBrush.Dispose()
            
            $nodeFont = New-Object System.Drawing.Font("Consolas", 8)
            $nodeLblBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
            $g.DrawString("N", $nodeFont, $nodeLblBrush, $nodeX - 4, $y + 15)
            $nodeFont.Dispose()
            $nodeLblBrush.Dispose()
        }
        
        # Antinodes (max displacement)
        for ($a = 0; $a -lt $harmonic; $a++) {
            $antinodeX = $x1 + (($a + 0.5) * $length / $harmonic)
            $antinodeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
            $g.FillEllipse($antinodeBrush, $antinodeX - 5, $y - 5, 10, 10)
            $antinodeBrush.Dispose()
            
            $antiFont = New-Object System.Drawing.Font("Consolas", 8)
            $antiLblBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
            $g.DrawString("A", $antiFont, $antiLblBrush, $antinodeX - 4, $y + 15)
            $antiFont.Dispose()
            $antiLblBrush.Dispose()
        }
    }
    
    # Draw pipe resonance (pressure variations)
    hidden [void] DrawPipeResonance([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$width, [double]$height, [int]$harmonic, [double]$phase, [bool]$isOpen) {
        # Pipe walls
        $pipePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 100, 100, 100), 4)
        $g.DrawLine($pipePen, $x, $y, $x, $y + $height)
        $g.DrawLine($pipePen, $x + $width, $y, $x + $width, $y + $height)
        
        if (-not $isOpen) {
            $g.DrawLine($pipePen, $x, $y + $height, $x + $width, $y + $height)
        }
        $pipePen.Dispose()
        
        # Pressure wave
        $numPoints = 100
        for ($i = 0; $i -le $numPoints; $i++) {
            $yPos = $y + ($i * $height / $numPoints)
            $relativeY = ($yPos - $y) / $height
            
            if ($isOpen) {
                $pressure = [math]::Sin($harmonic * [math]::PI * $relativeY) * [math]::Cos($phase)
            } else {
                $pressure = [math]::Cos($harmonic * [math]::PI * $relativeY) * [math]::Cos($phase)
            }
            
            $displacement = $pressure * 30
            $xCenter = $x + $width / 2
            
            # Color based on compression/rarefaction
            if ($pressure -gt 0) {
                $colorIntensity = [int]([math]::Abs($pressure) * 255)
                $pressureColor = [System.Drawing.Color]::FromArgb(150, $colorIntensity, 100, 100)
            } else {
                $colorIntensity = [int]([math]::Abs($pressure) * 255)
                $pressureColor = [System.Drawing.Color]::FromArgb(150, 100, 100, $colorIntensity)
            }
            
            $pressureBrush = New-Object System.Drawing.SolidBrush($pressureColor)
            $g.FillEllipse($pressureBrush, $xCenter + $displacement - 8, $yPos - 8, 16, 16)
            $pressureBrush.Dispose()
        }
        
        # Label
        if ($isOpen) {
            $openFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $openBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Lime)
            $g.DrawString("OPEN", $openFont, $openBrush, $x + $width/2 - 20, $y - 25)
            $openFont.Dispose()
            $openBrush.Dispose()
        } else {
            $closedFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $closedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
            $g.DrawString("CLOSED", $closedFont, $closedBrush, $x + $width/2 - 30, $y + $height + 10)
            $closedFont.Dispose()
            $closedBrush.Dispose()
        }
    }
    
    # Draw Helmholtz resonator
    hidden [void] DrawHelmholtzResonator([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$size, [double]$phase, [bool]$isResonating) {
        # Cavity
        $cavityPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 150, 150, 150), 3)
        $g.DrawEllipse($cavityPen, $x, $y, $size, $size)
        $cavityPen.Dispose()
        
        # Neck
        $neckWidth = $size / 4
        $neckHeight = $size / 3
        $neckX = $x + $size/2 - $neckWidth/2
        $neckY = $y - $neckHeight
        
        $neckPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 150, 150, 150), 3)
        $g.DrawRectangle($neckPen, $neckX, $neckY, $neckWidth, $neckHeight)
        $neckPen.Dispose()
        
        if ($isResonating) {
            # Air oscillating
            $airDisplacement = 15 * [math]::Sin($phase)
            $airY = $neckY + $neckHeight/2 + $airDisplacement
            
            $airBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 100, 200, 255))
            $g.FillRectangle($airBrush, $neckX, $airY - 3, $neckWidth, 6)
            $airBrush.Dispose()
            
            # Pressure glow
            $glowIntensity = [int]([math]::Abs([math]::Cos($phase)) * 150)
            $glowColor = [System.Drawing.Color]::FromArgb($glowIntensity, 255, 200, 100)
            $glowBrush = New-Object System.Drawing.SolidBrush($glowColor)
            $g.FillEllipse($glowBrush, $x + 10, $y + 10, $size - 20, $size - 20)
            $glowBrush.Dispose()
            
            # Sound waves
            for ($r = 1; $r -le 3; $r++) {
                $waveRadius = $size/2 + $r * 30 + (($phase * 10) % 30)
                $waveAlpha = [int](120 * (1 - $r / 3.0))
                $waveColor = [System.Drawing.Color]::FromArgb($waveAlpha, 255, 200, 100)
                $wavePen = New-Object System.Drawing.Pen($waveColor, 2)
                $g.DrawEllipse($wavePen, $x + $size/2 - $waveRadius, $y + $size/2 - $waveRadius, $waveRadius * 2, $waveRadius * 2)
                $wavePen.Dispose()
            }
        }
    }
    
    # Draw info box
    hidden [void] DrawInfoBox([System.Drawing.Graphics]$g, [int]$height, [string[]]$infoLines, [System.Drawing.Color]$color, [double]$xPos, [string[]]$mathLines) {
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush($color)
        
        $y = 80
        foreach ($line in $infoLines) {
            $g.DrawString($line, $infoFont, $infoBrush, $xPos, $y)
            $y += 25
        }
        
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math
        $mathFont = New-Object System.Drawing.Font("Consolas", 10)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        
        $y = $height - 80
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
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 220, 150))
        
        $actNames = @("", "✨ ACT 1: VIBRATING STRING", "✨ ACT 2: OPEN PIPE", "✨ ACT 3: CLOSED PIPE", "✨ ACT 4: HELMHOLTZ RESONATOR")
        $titleText = "SHOW54: " + $actNames[$this.State.Act]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show54 {
    Write-Host "[Show54] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show54")) {
        $show = $Global:ShowManager.Shows["show54"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show54] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow54 class loaded (v3)" -ForegroundColor Green
