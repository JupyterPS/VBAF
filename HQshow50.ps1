
# ===============================
# HQshow50.ps1 — 3D Wave Propagation Theater v3
# Wave Physics Theater: Converted to Game Machine Architecture
# ===============================

Write-Host "`n=> _____ HQshow50 (3D Wave Propagation v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show50 - Inherits from BaseShow
# ============================================
class Show50 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Sources
    hidden [System.Collections.ArrayList] $Obstacles
    hidden [System.Collections.ArrayList] $WaveRings
    hidden [System.Drawing.Bitmap] $BackBuffer
    hidden [int] $TickCounter
    
    # ========================================
    # Constructor
    # ========================================
    Show50([System.Windows.Forms.Panel]$panel) : base("show50", $panel) {
        # Initialize state
        $this.State = @{
            TimeStep = 0
            Act = 1  # 1=Single Source, 2=Multiple Sources, 3=Obstacles, 4=Refraction
            ActTimer = 0
            CameraAngle = 30
            WaveSpeed = 3.0
            Frequency = 0.15
        }
        
        # Initialize collections
        $this.Sources = [System.Collections.ArrayList]::new()
        $this.Obstacles = [System.Collections.ArrayList]::new()
        $this.WaveRings = [System.Collections.ArrayList]::new()
        $this.BackBuffer = $null
        $this.TickCounter = 0
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  🌊 [Show50] Initializing 3D Wave Propagation Theater..." -ForegroundColor Cyan
        
        # Clear and setup panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 15)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { 
            $prop.SetValue($this.Panel, $true, $null)
            Write-Host "  ✓ Double buffering enabled" -ForegroundColor Green
        }


try {
    $userPaint    = [System.Windows.Forms.ControlStyles]::UserPaint
    $allPaint     = [System.Windows.Forms.ControlStyles]::AllPaintingInWmPaint
    $doubleBuffer = [System.Windows.Forms.ControlStyles]::OptimizedDoubleBuffer
    $combinedStyles = $userPaint -bor $allPaint -bor $doubleBuffer

    $controlType = [System.Windows.Forms.Control]
    $controlType.InvokeMember("SetStyle",
        [System.Reflection.BindingFlags] "Instance,NonPublic,InvokeMethod",
        $null, $this.Panel, @($combinedStyles, $true))

    $controlType.InvokeMember("UpdateStyles",
        [System.Reflection.BindingFlags] "Instance,NonPublic,InvokeMethod",
        $null, $this.Panel, @())
} catch {
    Write-Host "⚠️ Could not set paint styles: $_" -ForegroundColor Yellow
}






  <#      
        # Set control styles for custom painting
        try {
            $userPaint = [System.Windows.Forms.ControlStyles]::UserPaint
            $allPaint = [System.Windows.Forms.ControlStyles]::AllPaintingInWmPaint
            $doubleBuffer = [System.Windows.Forms.ControlStyles]::OptimizedDoubleBuffer
            $combinedStyles = [int]$userPaint -bor [int]$allPaint -bor [int]$doubleBuffer
            
            $this.Panel.GetType().InvokeMember("SetStyle",
                [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::InvokeMethod,
                $null, $this.Panel, @($combinedStyles, $true))
        } catch {
            Write-Host "  ⚠️ Could not set paint styles: $_" -ForegroundColor Yellow
        }
 #>       
        # Update ticker messages
        $Show50Messages = @(
            "🌊 3D WAVE PROPAGATION THEATER - The Grand Opening!",
            "🎯 Watch spherical waves expand through 3D space",
            "💫 Multiple sources create complex interference patterns",
            "🔲 Waves reflect off obstacles and boundaries",
            "🌈 Refraction: waves change speed in different media"
        )
        $Global:messages = $Show50Messages
        
        # Initialize Act 1
        $this.InitializeAct1()
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host "  ✅ [Show50] 3D Wave Theater ready - GRAND OPENING!" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM (~50ms)
    [void] OnUpdate() {
        $this.TickCounter++
        $this.State.TimeStep++
        $this.State.ActTimer++
        
        # Act transitions every 200 frames (~10 seconds)
        if ($this.State.ActTimer -gt 200) {
            $this.State.Act++
            if ($this.State.Act -gt 4) { $this.State.Act = 1 }
            $this.State.ActTimer = 0
            $this.State.TimeStep = 0
            
            # Setup new act
            $this.TransitionToAct($this.State.Act)
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [Show50] Cleaning up..." -ForegroundColor Yellow
        
        # Dispose back buffer
        if ($this.BackBuffer) {
            $this.BackBuffer.Dispose()
            $this.BackBuffer = $null
        }
        
        # Clear collections
        if ($this.Sources) { $this.Sources.Clear() }
        if ($this.Obstacles) { $this.Obstacles.Clear() }
        if ($this.WaveRings) { $this.WaveRings.Clear() }
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.ActTimer = 0
        $this.State.Act = 1
        $this.TickCounter = 0
        
        Write-Host "  ✅ [Show50] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Initialize Act 1: Single source
    hidden [void] InitializeAct1() {
        $this.Sources.Clear()
        $this.Obstacles.Clear()
        
        [void]$this.Sources.Add(@{
            X = 325
            Y = 150
            Z = 0
            Phase = 0
            Active = $true
            Color = [System.Drawing.Color]::FromArgb(100, 200, 255)
        })
    }
    
    # Transition between acts
    hidden [void] TransitionToAct([int]$act) {
        $this.Sources.Clear()
        $this.Obstacles.Clear()
        
        switch ($act) {
            1 {
                # Single source
                [void]$this.Sources.Add(@{
                    X = 325; Y = 150; Z = 0; Phase = 0; Active = $true
                    Color = [System.Drawing.Color]::FromArgb(100, 200, 255)
                })
            }
            2 {
                # Multiple sources
                [void]$this.Sources.Add(@{
                    X = 200; Y = 150; Z = 0; Phase = 0; Active = $true
                    Color = [System.Drawing.Color]::FromArgb(255, 100, 100)
                })
                [void]$this.Sources.Add(@{
                    X = 450; Y = 150; Z = 0; Phase = 0; Active = $true
                    Color = [System.Drawing.Color]::FromArgb(100, 255, 100)
                })
                [void]$this.Sources.Add(@{
                    X = 325; Y = 250; Z = 0; Phase = 0; Active = $true
                    Color = [System.Drawing.Color]::FromArgb(100, 100, 255)
                })
            }
            3 {
                # Source + obstacles
                [void]$this.Sources.Add(@{
                    X = 150; Y = 150; Z = 0; Phase = 0; Active = $true
                    Color = [System.Drawing.Color]::FromArgb(255, 200, 100)
                })
                [void]$this.Obstacles.Add(@{X = 350; Y = 100; Width = 80; Height = 200})
                [void]$this.Obstacles.Add(@{X = 500; Y = 150; Width = 60; Height = 150})
            }
            4 {
                # Source for refraction
                [void]$this.Sources.Add(@{
                    X = 325; Y = 120; Z = 0; Phase = 0; Active = $true
                    Color = [System.Drawing.Color]::White
                })
            }
        }
    }
    
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
    hidden [void] RenderScene([object]$sender, [System.Drawing.Graphics]$screenGraphics) {
        $width = $sender.Width
        $height = $sender.Height
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Create/recreate back buffer if needed
        if (-not $this.BackBuffer -or $this.BackBuffer.Width -ne $width -or $this.BackBuffer.Height -ne $height) {
            if ($this.BackBuffer) { $this.BackBuffer.Dispose() }
            $this.BackBuffer = New-Object System.Drawing.Bitmap($width, $height)
        }
        
        # Draw to back buffer
        $g = [System.Drawing.Graphics]::FromImage($this.BackBuffer)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Draw background
        $this.DrawBackground($g, $width, $height)
        
        # Draw based on current act
        switch ($this.State.Act) {
            1 { $this.DrawAct1($g, $width, $height) }
            2 { $this.DrawAct2($g, $width, $height) }
            3 { $this.DrawAct3($g, $width, $height) }
            4 { $this.DrawAct4($g, $width, $height) }
        }
        
        # Draw title
        $this.DrawTitle($g, $width)
        
        # Dispose graphics object
        $g.Dispose()
        
        # Blit to screen (eliminates flicker)
        $screenGraphics.DrawImage($this.BackBuffer, 0, 0)
    }
    
    # Draw space background with stars
    hidden [void] DrawBackground([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        # Gradient background
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(5, 5, 15),
            [System.Drawing.Color]::FromArgb(10, 10, 30)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Stars
        for ($i = 0; $i -lt 60; $i++) {
            $starX = ($i * 173) % $width
            $starY = ($i * 241) % ($height - 100)
            $brightness = 80 + (($i * 71) % 120)
            $starBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($brightness, $brightness, $brightness))
            $g.FillEllipse($starBrush, $starX, $starY + 60, 1, 1)
            $starBrush.Dispose()
        }
        
        # Grid
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 100, 100, 150), 1)
        for ($yGrid = 100; $yGrid -lt $height - 80; $yGrid += 40) {
            $g.DrawLine($gridPen, 50, $yGrid, $width - 50, $yGrid)
        }
        for ($xGrid = 100; $xGrid -lt $width; $xGrid += 60) {
            $g.DrawLine($gridPen, $xGrid, 80, $xGrid, $height - 100)
        }
        $gridPen.Dispose()
    }
    
    # Act 1: Single spherical source
    hidden [void] DrawAct1([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        if ($this.Sources.Count -eq 0) { return }
        
        $source = $this.Sources[0]
        $t = $this.State.TimeStep
        
        # Draw expanding spherical wavefronts
        for ($ring = 0; $ring -lt 8; $ring++) {
            $radius = ($t - $ring * 20) * $this.State.WaveSpeed
            
            if ($radius -gt 0 -and $radius -lt 400) {
                # 1/r amplitude falloff
                $amplitude = 200.0 / ($radius + 1)
                $phase = $ring * [math]::PI / 4
                $intensity = [math]::Abs([math]::Sin($phase)) * $amplitude
                
                # Full visibility
                $ringColor = [System.Drawing.Color]::FromArgb(255, 100, 200, 255)
                
                # Draw with thickness for visibility
                for ($thick = 0; $thick -lt 3; $thick++) {
                    $pen = New-Object System.Drawing.Pen($ringColor, 4)
                    # 3D ellipse (compressed Y for perspective)
                    $g.DrawEllipse($pen, $source.X - $radius, $source.Y - $radius * 0.5, $radius * 2, $radius)
                    $pen.Dispose()
                }
            }
        }
        
        # Draw source
        $sourceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.FillEllipse($sourceBrush, $source.X - 10, $source.Y - 10, 20, 20)
        $sourceBrush.Dispose()
        
        # Info overlay
        $this.DrawInfoOverlay($g, "Spherical Wave Expansion", "Amplitude ∝ 1/r", [System.Drawing.Color]::Cyan)
        
        # Math overlay
        $this.DrawMathOverlay($g, $height, @(
            "ψ(r,t) = (A/r)·sin(kr - ωt)",
            "Intensity: I ∝ 1/r²  (inverse square law)"
        ))
    }
    
    # Act 2: Multiple sources with interference
    hidden [void] DrawAct2([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $t = $this.State.TimeStep
        
        foreach ($source in $this.Sources) {
            if (-not $source.Active) { continue }
            
            # Draw waves from each source
            for ($ring = 0; $ring -lt 6; $ring++) {
                $radius = ($t - $ring * 25) * $this.State.WaveSpeed
                
                if ($radius -gt 0 -and $radius -lt 350) {
                    $amplitude = 150.0 / ($radius + 1)
                    $phase = $ring * [math]::PI / 3
                    $intensity = [math]::Abs([math]::Sin($phase)) * $amplitude
                    
                    $ringColor = [System.Drawing.Color]::FromArgb(255, 100, 200, 255)
                    $pen = New-Object System.Drawing.Pen($ringColor, 2)
                    $g.DrawEllipse($pen, $source.X - $radius, $source.Y - $radius * 0.5, $radius * 2, $radius)
                    $pen.Dispose()
                }
            }
            
            # Draw source
            $srcBrush = New-Object System.Drawing.SolidBrush($source.Color)
            $g.FillEllipse($srcBrush, $source.X - 5, $source.Y - 5, 10, 10)
            $srcBrush.Dispose()
        }
        
        # Info
        $this.DrawInfoOverlay($g, "Multiple Source Interference", "$($this.Sources.Count) wave sources", [System.Drawing.Color]::Yellow)
        
        # Math
        $this.DrawMathOverlay($g, $height, @(
            "ψ_total = Σ(Aᵢ/rᵢ)·sin(krᵢ - ωt + φᵢ)",
            "Complex 3D interference patterns emerge"
        ))
    }
    
    # Act 3: Obstacles and reflection
    hidden [void] DrawAct3([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        # Draw obstacles
        foreach ($obstacle in $this.Obstacles) {
            $obsBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 80, 80, 80))
            $g.FillRectangle($obsBrush, $obstacle.X, $obstacle.Y, $obstacle.Width, $obstacle.Height)
            $obsBrush.Dispose()
            
            $edgePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 120, 120, 120), 2)
            $g.DrawRectangle($edgePen, $obstacle.X, $obstacle.Y, $obstacle.Width, $obstacle.Height)
            $edgePen.Dispose()
        }
        
        # Draw waves
        if ($this.Sources.Count -gt 0) {
            $source = $this.Sources[0]
            $t = $this.State.TimeStep
            
            for ($ring = 0; $ring -lt 10; $ring++) {
                $radius = ($t - $ring * 15) * $this.State.WaveSpeed
                
                if ($radius -gt 0 -and $radius -lt 400) {
                    $amplitude = 180.0 / ($radius + 1)
                    $phase = $ring * [math]::PI / 5
                    $intensity = [math]::Abs([math]::Sin($phase)) * $amplitude
                    
                    $ringColor = [System.Drawing.Color]::FromArgb(255, 100, 200, 255)
                    $pen = New-Object System.Drawing.Pen($ringColor, 2)
                    $g.DrawEllipse($pen, $source.X - $radius, $source.Y - $radius * 0.5, $radius * 2, $radius)
                    $pen.Dispose()
                }
            }
            
            # Draw source
            $srcBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 100))
            $g.FillEllipse($srcBrush, $source.X - 6, $source.Y - 6, 12, 12)
            $srcBrush.Dispose()
        }
        
        # Info
        $this.DrawInfoOverlay($g, "Wave Reflection from Obstacles", "Boundary Conditions Applied", [System.Drawing.Color]::Orange)
        
        # Math
        $this.DrawMathOverlay($g, $height, @(
            "Reflected: ψᵣ = -ψᵢ (fixed boundary)",
            "Angle of incidence = Angle of reflection"
        ))
    }
    
    # Act 4: Refraction between media
    hidden [void] DrawAct4([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $centerY = $height / 2
        $mediaY = $centerY
        
        # Medium 1 (top - faster)
        $med1Height = [math]::Max(1, $mediaY - 60)
        $med1Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 100, 100, 200))
        $g.FillRectangle($med1Brush, 0, 60, $width, $med1Height)
        $med1Brush.Dispose()
        
        # Medium 2 (bottom - slower)
        $med2Height = [math]::Max(1, $height - $mediaY - 80)
        $med2Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 200, 100, 100))
        $g.FillRectangle($med2Brush, 0, [int]$mediaY, $width, [int]$med2Height)
        $med2Brush.Dispose()
        
        # Interface line
        $interfacePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 0), 2)
        $interfacePen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        $g.DrawLine($interfacePen, 0, $mediaY, $width, $mediaY)
        $interfacePen.Dispose()
        
        # Draw waves with refraction
        if ($this.Sources.Count -gt 0) {
            $source = $this.Sources[0]
            $t = $this.State.TimeStep
            
            for ($ring = 0; $ring -lt 8; $ring++) {
                $radius1 = ($t - $ring * 20) * $this.State.WaveSpeed * 1.5
                
                if ($radius1 -gt 0 -and $radius1 -lt 350) {
                    $amplitude = 160.0 / ($radius1 + 1)
                    $phase = $ring * [math]::PI / 4
                    $intensity = [math]::Abs([math]::Sin($phase)) * $amplitude
                    
                    $ringColor = [System.Drawing.Color]::FromArgb(255, 100, 200, 255)
                    
                    # Top medium (faster)
                    $clipRect1 = New-Object System.Drawing.Rectangle(0, 60, $width, $med1Height)
                    $region1 = New-Object System.Drawing.Region($clipRect1)
                    $oldClip = $g.Clip
                    $g.Clip = $region1
                    
                    $pen = New-Object System.Drawing.Pen($ringColor, 2)
                    $g.DrawEllipse($pen, $source.X - $radius1, $source.Y - $radius1 * 0.5, $radius1 * 2, $radius1)
                    $pen.Dispose()
                    
                    $g.Clip = $oldClip
                    $region1.Dispose()
                    
                    # Bottom medium (slower, refracted)
                    if ($source.Y + $radius1 * 0.5 -gt $mediaY) {
                        $radius2 = $radius1 * 0.6
                        $ringColor2 = [System.Drawing.Color]::FromArgb(255, 100, 200, 255)
                        
                        $clipRect2 = New-Object System.Drawing.Rectangle(0, [int]$mediaY, $width, [int]$med2Height)
                        $region2 = New-Object System.Drawing.Region($clipRect2)
                        $g.Clip = $region2
                        
                        $pen2 = New-Object System.Drawing.Pen($ringColor2, 2)
                        $refractY = $mediaY + ($mediaY - $source.Y) * 0.7
                        $g.DrawEllipse($pen2, $source.X - $radius2, $refractY, $radius2 * 2, $radius2)
                        $pen2.Dispose()
                        
                        $g.Clip = $oldClip
                        $region2.Dispose()
                    }
                }
            }
            
            # Draw source
            $srcBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.FillEllipse($srcBrush, $source.X - 6, $source.Y - 6, 12, 12)
            $srcBrush.Dispose()
        }
        
        # Medium labels
        $lblFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        
        $lbl1Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 150, 150, 255))
        $g.DrawString("Medium 1: v₁ = 1.5c", $lblFont, $lbl1Brush, 20, 80)
        $lbl1Brush.Dispose()
        
        $lbl2Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 150, 150))
        $g.DrawString("Medium 2: v₂ = 0.6c", $lblFont, $lbl2Brush, 20, $mediaY + 20)
        $lbl2Brush.Dispose()
        
        $lblFont.Dispose()
        
        # Math
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Snell's Law: n₁sin(θ₁) = n₂sin(θ₂)", $mathFont, $mathBrush, 20, $height - 70)
        $g.DrawString("Wavelength changes: λ₂ = λ₁(v₂/v₁)", $mathFont, $mathBrush, 20, $height - 50)
        $g.DrawString("Frequency stays constant: f₁ = f₂", $mathFont, $mathBrush, 20, $height - 30)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # Draw info overlay (helper)
    hidden [void] DrawInfoOverlay([System.Drawing.Graphics]$g, [string]$line1, [string]$line2, [System.Drawing.Color]$color) {
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush($color)
        $g.DrawString($line1, $infoFont, $infoBrush, 20, 80)
        $g.DrawString($line2, $infoFont, $infoBrush, 20, 100)
        $infoFont.Dispose()
        $infoBrush.Dispose()
    }
    
    # Draw math overlay (helper)
    hidden [void] DrawMathOverlay([System.Drawing.Graphics]$g, [int]$height, [string[]]$equations) {
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        
        $y = $height - 60
        foreach ($eq in $equations) {
            $g.DrawString($eq, $mathFont, $mathBrush, 20, $y)
            $y += 20
        }
        
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # Draw title
    hidden [void] DrawTitle([System.Drawing.Graphics]$g, [int]$width) {
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 100, 255, 255))
        
        $actNames = @("", "✨ ACT 1: SPHERICAL EXPANSION", "✨ ACT 2: MULTIPLE SOURCES", "✨ ACT 3: REFLECTION", "✨ ACT 4: REFRACTION")
        $titleText = "SHOW50: " + $actNames[$this.State.Act]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show50 {
    Write-Host "[Show50] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show50")) {
        $show = $Global:ShowManager.Shows["show50"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show50] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow50 class loaded (v3)" -ForegroundColor Green
