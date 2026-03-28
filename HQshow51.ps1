# ===============================
# HQshow51.ps1 — Doppler Effect Symphony v3
# Wave Physics Theater: The Sound of Motion
# Converted to Game Machine Architecture
# ===============================

Write-Host "`n=> _____ HQshow51 (Doppler Effect Symphony v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show51 - Inherits from BaseShow
# ============================================
class Show51 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $WaveFronts
    hidden [System.Collections.ArrayList] $ParticleTrails
    hidden [int] $TickCounter
    
    # ========================================
    # Constructor
    # ========================================
    Show51([System.Windows.Forms.Panel]$panel) : base("show51", $panel) {
        # Initialize state
        $this.State = @{
            TimeStep = 0
            Act = 1  # 1=Stationary, 2=Subsonic, 3=Sonic, 4=Supersonic
            ActTimer = 0
            SourceX = 100
            SourceY = 200
            SourceVelocity = 0
            WaveSpeed = 4.0
            Frequency = 0.2
        }
        
        # Initialize collections
        $this.WaveFronts = [System.Collections.ArrayList]::new()
        $this.ParticleTrails = [System.Collections.ArrayList]::new()
        $this.TickCounter = 0
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  🚗 [Show51] Initializing Doppler Effect Symphony..." -ForegroundColor Cyan
        
        # Clear and setup panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 25)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { 
            $prop.SetValue($this.Panel, $true, $null)
        }
        
        # Update ticker messages
        $Show51Messages = @(
            "🚗 DOPPLER EFFECT SYMPHONY - The Physics of Moving Sound",
            "🎵 Stationary source produces symmetric waves",
            "✈️ Moving source compresses waves ahead, stretches behind",
            "💥 At sound speed: Mach 1 - wavefronts pile up!",
            "⚡ Supersonic: Shock wave (sonic boom) forms Mach cone"
        )
        $Global:messages = $Show51Messages
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host "  ✅ [Show51] Doppler simulation engine ready" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM (~50ms)
    [void] OnUpdate() {
        $this.TickCounter++
        $this.State.TimeStep++
        $this.State.ActTimer++
        
        # Emit wavefront periodically
        if ($this.State.TimeStep % 15 -eq 0) {
            [void]$this.WaveFronts.Add(@{
                X = $this.State.SourceX
                Y = $this.State.SourceY
                Age = 0
            })
        }
        
        # Update wavefronts
        $this.UpdateWaveFronts()
        
        # Move source
        $this.State.SourceX += $this.State.SourceVelocity
        
        # Wrap around
        if ($this.State.SourceX -gt 700) {
            $this.State.SourceX = -50
            $this.WaveFronts.Clear()
        }
        
        # Add motion trail
        if ($this.State.SourceVelocity -gt 0) {
            [void]$this.ParticleTrails.Add(@{
                X = $this.State.SourceX
                Y = $this.State.SourceY
                Age = 0
            })
        }
        
        # Update trails
        $this.UpdateParticleTrails()
        
        # Act transitions
        if ($this.State.ActTimer -gt 180) {
            $this.TransitionToNextAct()
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [Show51] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        if ($this.WaveFronts) { $this.WaveFronts.Clear() }
        if ($this.ParticleTrails) { $this.ParticleTrails.Clear() }
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.ActTimer = 0
        $this.State.Act = 1
        $this.State.SourceX = 100
        $this.State.SourceVelocity = 0
        $this.TickCounter = 0
        
        Write-Host "  ✅ [Show51] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Update wavefronts (age and remove old)
    hidden [void] UpdateWaveFronts() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($wf in $this.WaveFronts) {
            $wf.Age++
            if ($wf.Age -gt 100) {
                [void]$toRemove.Add($wf)
            }
        }
        
        foreach ($rem in $toRemove) {
            [void]$this.WaveFronts.Remove($rem)
        }
    }
    
    # Update particle trails
    hidden [void] UpdateParticleTrails() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($trail in $this.ParticleTrails) {
            $trail.Age++
            if ($trail.Age -gt 30) {
                [void]$toRemove.Add($trail)
            }
        }
        
        foreach ($rem in $toRemove) {
            [void]$this.ParticleTrails.Remove($rem)
        }
    }
    
    # Transition to next act
    hidden [void] TransitionToNextAct() {
        $this.State.Act++
        if ($this.State.Act -gt 4) { $this.State.Act = 1 }
        
        $this.State.ActTimer = 0
        $this.State.TimeStep = 0
        $this.State.SourceX = 100
        $this.WaveFronts.Clear()
        $this.ParticleTrails.Clear()
        
        # Set velocity for each act
        switch ($this.State.Act) {
            1 {
                $this.State.SourceVelocity = 0
                $this.State.SourceY = 200
            }
            2 {
                $this.State.SourceVelocity = 2.5  # 0.625 Mach
                $this.State.SourceY = 200
            }
            3 {
                $this.State.SourceVelocity = 4.0  # Mach 1
                $this.State.SourceY = 200
            }
            4 {
                $this.State.SourceVelocity = 6.0  # Mach 1.5
                $this.State.SourceY = 200
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
    hidden [void] RenderScene([object]$sender, [System.Drawing.Graphics]$g) {
        $width = $sender.Width
        $height = $sender.Height
        
        if ($width -le 0 -or $height -le 0) { return }
        
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
    }
    
    # Draw background with ground/horizon
    hidden [void] DrawBackground([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        # Sky gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(10, 10, 25),
            [System.Drawing.Color]::FromArgb(20, 15, 35)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Ground
        $groundY = $height - 80
        $groundBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 40, 40, 40))
        $g.FillRectangle($groundBrush, 0, $groundY, $width, $height - $groundY)
        $groundBrush.Dispose()
        
        # Horizon line
        $horizonPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 100, 100, 100), 2)
        $g.DrawLine($horizonPen, 0, $groundY, $width, $groundY)
        $horizonPen.Dispose()
    }
    
    # Act 1: Stationary source
    hidden [void] DrawAct1([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $srcX = $this.State.SourceX
        $srcY = $this.State.SourceY
        $waveSpeed = $this.State.WaveSpeed
        
        # Draw symmetric wavefronts
        foreach ($wf in $this.WaveFronts) {
            $radius = $wf.Age * $waveSpeed
            
            if ($radius -gt 0 -and $radius -lt 500) {
                $alpha = [int](200 * (1 - $wf.Age / 100.0))
                if ($alpha -gt 0) {
                    $waveColor = [System.Drawing.Color]::FromArgb($alpha, 100, 200, 255)
                    
                    for ($i = 0; $i -lt 2; $i++) {
                        $pen = New-Object System.Drawing.Pen($waveColor, (3 - $i))
                        $g.DrawEllipse($pen, $wf.X - $radius, $wf.Y - $radius, $radius * 2, $radius * 2)
                        $pen.Dispose()
                    }
                }
            }
        }
        
        # Draw speaker source
        $this.DrawSpeaker($g, $srcX, $srcY)
        
        # Info
        $this.DrawInfoOverlay($g, @(
            "STATIONARY SOURCE",
            "Velocity: v = 0",
            "Symmetric wavefronts"
        ), [System.Drawing.Color]::Cyan)
        
        # Math
        $this.DrawMathOverlay($g, $height, @(
            "f_observed = f_source (no Doppler shift)",
            "Wavelength λ = v_sound / f"
        ))
    }
    
    # Act 2: Subsonic motion
    hidden [void] DrawAct2([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $srcX = $this.State.SourceX
        $srcY = $this.State.SourceY
        $velocity = $this.State.SourceVelocity
        $waveSpeed = $this.State.WaveSpeed
        
        # Draw asymmetric wavefronts
        foreach ($wf in $this.WaveFronts) {
            $radius = $wf.Age * $waveSpeed
            
            if ($radius -gt 0 -and $radius -lt 600) {
                $alpha = [int](180 * (1 - $wf.Age / 80.0))
                if ($alpha -gt 0) {
                    $waveColor = [System.Drawing.Color]::FromArgb($alpha, 255, 200, 100)
                    $pen = New-Object System.Drawing.Pen($waveColor, 2)
                    $g.DrawEllipse($pen, $wf.X - $radius, $wf.Y - $radius, $radius * 2, $radius * 2)
                    $pen.Dispose()
                }
            }
        }
        
        # Draw vehicle
        $this.DrawVehicle($g, $srcX, $srcY, [System.Drawing.Color]::Orange)
        
        # Motion trail
        $this.DrawMotionTrail($g, 30, 3, [System.Drawing.Color]::FromArgb(255, 255, 200, 0))
        
        # Info
        $machNumber = $velocity / $waveSpeed
        $this.DrawInfoOverlay($g, @(
            "SUBSONIC MOTION",
            "Mach Number: M = $([math]::Round($machNumber, 2))",
            "Waves compressed ahead →"
        ), [System.Drawing.Color]::Yellow)
        
        # Math
        $this.DrawMathOverlay($g, $height, @(
            "Ahead: f' = f₀(c/(c-v))  → Higher pitch",
            "Behind: f' = f₀(c/(c+v)) → Lower pitch",
            "Classic ambulance siren effect!"
        ))
    }
    
    # Act 3: Sonic (Mach 1)
    hidden [void] DrawAct3([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $srcX = $this.State.SourceX
        $srcY = $this.State.SourceY
        $waveSpeed = $this.State.WaveSpeed
        
        # Draw wavefronts piling up
        foreach ($wf in $this.WaveFronts) {
            $radius = $wf.Age * $waveSpeed
            
            if ($radius -gt 0 -and $radius -lt 500) {
                $alpha = [int](220 * (1 - $wf.Age / 70.0))
                if ($alpha -gt 0) {
                    $waveColor = [System.Drawing.Color]::FromArgb($alpha, 255, 255, 100)
                    $pen = New-Object System.Drawing.Pen($waveColor, 3)
                    $g.DrawEllipse($pen, $wf.X - $radius, $wf.Y - $radius, $radius * 2, $radius * 2)
                    $pen.Dispose()
                }
            }
        }
        
        # Pressure buildup glow
        $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 255, 255, 0))
        $g.FillEllipse($glowBrush, $srcX, $srcY - 60, 120, 120)
        $glowBrush.Dispose()
        
        # Draw vehicle
        $this.DrawVehicle($g, $srcX, $srcY, [System.Drawing.Color]::FromArgb(255, 255, 200))
        
        # Motion trail
        $this.DrawMotionTrail($g, 25, 4, [System.Drawing.Color]::FromArgb(255, 255, 255, 0))
        
        # Warning flash
        if (($this.State.TimeStep % 20) -lt 10) {
            $flashFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $flashBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 0))
            $g.DrawString("⚠️ MACH 1 ⚠️", $flashFont, $flashBrush, $width/2 - 80, $height/2 - 100)
            $flashFont.Dispose()
            $flashBrush.Dispose()
        }
        
        # Info
        $this.DrawInfoOverlay($g, @(
            "TRANSONIC: M = 1.0",
            "Wavefronts PILING UP!",
            "Infinite pressure buildup"
        ), [System.Drawing.Color]::FromArgb(255, 255, 255, 0))
        
        # Math
        $mathFont = New-Object System.Drawing.Font("Consolas", 9)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("At Mach 1: v_source = c_sound", $mathFont, $mathBrush, 20, $height - 70)
        $g.DrawString("Wavefronts cannot escape ahead!", $mathFont, $mathBrush, 20, $height - 50)
        $g.DrawString("f' → ∞ (infinite frequency compression)", $mathFont, $mathBrush, 20, $height - 30)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # Act 4: Supersonic (Mach cone)
    hidden [void] DrawAct4([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $srcX = $this.State.SourceX
        $srcY = $this.State.SourceY
        $velocity = $this.State.SourceVelocity
        $waveSpeed = $this.State.WaveSpeed
        $machNumber = $velocity / $waveSpeed
        
        # Draw Mach cone
        if ($machNumber -gt 1) {
            $machAngle = [math]::Asin(1.0 / $machNumber)
            $coneLength = 400
            $coneWidth = $coneLength * [math]::Tan($machAngle)
            
            # Shock wave lines with glow
            for ($i = 0; $i -lt 5; $i++) {
                $shockAlpha = 255 - ($i * 40)
                $shockColor = [System.Drawing.Color]::FromArgb($shockAlpha, 255, 100, 100)
                $shockPen = New-Object System.Drawing.Pen($shockColor, (6 - $i))
                
                $g.DrawLine($shockPen, $srcX, $srcY, $srcX - $coneLength, $srcY - $coneWidth)
                $g.DrawLine($shockPen, $srcX, $srcY, $srcX - $coneLength, $srcY + $coneWidth)
                $shockPen.Dispose()
            }
            
            # Fill cone
            $conePoint1 = New-Object System.Drawing.Point($srcX, $srcY)
            $conePoint2 = New-Object System.Drawing.Point(($srcX - $coneLength), ($srcY - $coneWidth))
            $conePoint3 = New-Object System.Drawing.Point(($srcX - $coneLength), ($srcY + $coneWidth))
            $conePts = @($conePoint1, $conePoint2, $conePoint3)
            
            $coneBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 255, 100, 100))
            $g.FillPolygon($coneBrush, $conePts)
            $coneBrush.Dispose()
            
            # Mach angle indicator
            $angleDegrees = $machAngle * 180 / [math]::PI
            $arcPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
            $g.DrawArc($arcPen, $srcX - 50, $srcY - 50, 100, 100, 180 - $angleDegrees, $angleDegrees * 2)
            $arcPen.Dispose()
            
            $angleLbl = New-Object System.Drawing.Font("Consolas", 9)
            $angleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
            $g.DrawString("θ=$([math]::Round($angleDegrees, 1))°", $angleLbl, $angleBrush, $srcX - 80, $srcY + 30)
            $angleLbl.Dispose()
            $angleBrush.Dispose()
        }
        
        # Draw wavefronts left behind
        foreach ($wf in $this.WaveFronts) {
            $radius = $wf.Age * $waveSpeed
            
            if ($radius -gt 0 -and $radius -lt 500) {
                $alpha = [int](160 * (1 - $wf.Age / 80.0))
                if ($alpha -gt 0) {
                    $waveColor = [System.Drawing.Color]::FromArgb($alpha, 150, 150, 255)
                    $pen = New-Object System.Drawing.Pen($waveColor, 1)
                    $g.DrawEllipse($pen, $wf.X - $radius, $wf.Y - $radius, $radius * 2, $radius * 2)
                    $pen.Dispose()
                }
            }
        }
        
        # Draw vehicle
        $this.DrawVehicle($g, $srcX, $srcY, [System.Drawing.Color]::FromArgb(255, 255, 100, 100))
        
        # Fire trail
        foreach ($trail in $this.ParticleTrails) {
            $tAlpha = [int](200 * (1 - $trail.Age / 20.0))
            if ($tAlpha -gt 0) {
                $tColor = if ($trail.Age -lt 5) { 
                    [System.Drawing.Color]::FromArgb($tAlpha, 255, 255, 200)
                } else {
                    [System.Drawing.Color]::FromArgb($tAlpha, 255, 150, 100)
                }
                $tBrush = New-Object System.Drawing.SolidBrush($tColor)
                $g.FillEllipse($tBrush, $trail.X - 5, $trail.Y - 5, 10, 10)
                $tBrush.Dispose()
            }
        }
        
        # SONIC BOOM label
        $boomFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $boomBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 150, 150))
        $g.DrawString("💥 SONIC BOOM! 💥", $boomFont, $boomBrush, $width/2 - 120, $height/2 - 100)
        $boomFont.Dispose()
        $boomBrush.Dispose()
        
        # Info
        $this.DrawInfoOverlay($g, @(
            "SUPERSONIC: M = $([math]::Round($machNumber, 2))",
            "Mach Cone Formed!",
            "Shock wave trails behind"
        ), [System.Drawing.Color]::FromArgb(255, 255, 100, 100))
        
        # Math
        $mathFont = New-Object System.Drawing.Font("Consolas", 9)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 200))
        $g.DrawString("Mach angle: sin(θ) = c/v = 1/M", $mathFont, $mathBrush, 20, $height - 70)
        $g.DrawString("Shock wave: sudden pressure discontinuity", $mathFont, $mathBrush, 20, $height - 50)
        $g.DrawString("Sonic boom heard when cone passes observer", $mathFont, $mathBrush, 20, $height - 30)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # Draw speaker icon
    hidden [void] DrawSpeaker([System.Drawing.Graphics]$g, [double]$x, [double]$y) {
        $srcSize = 30
        $srcBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 200, 255))
        $g.FillRectangle($srcBrush, $x - 10, $y - $srcSize/2, 20, $srcSize)
        $srcBrush.Dispose()
        
        # Speaker cone
        $conePoint1 = New-Object System.Drawing.Point(($x + 10), ($y - 15))
        $conePoint2 = New-Object System.Drawing.Point(($x + 25), ($y - 25))
        $conePoint3 = New-Object System.Drawing.Point(($x + 25), ($y + 25))
        $conePoint4 = New-Object System.Drawing.Point(($x + 10), ($y + 15))
        $conePoints = @($conePoint1, $conePoint2, $conePoint3, $conePoint4)
        
        $coneBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 150, 150, 200))
        $g.FillPolygon($coneBrush, $conePoints)
        $coneBrush.Dispose()
    }
    
    # Draw vehicle
    hidden [void] DrawVehicle([System.Drawing.Graphics]$g, [double]$x, [double]$y, [System.Drawing.Color]$color) {
        # Body
        $bodyBrush = New-Object System.Drawing.SolidBrush($color)
        $g.FillRectangle($bodyBrush, $x - 20, $y - 10, 40, 20)
        $bodyBrush.Dispose()
        
        # Nose
        $nosePoint1 = New-Object System.Drawing.Point(($x + 20), ($y - 10))
        $nosePoint2 = New-Object System.Drawing.Point(($x + 35), $y)
        $nosePoint3 = New-Object System.Drawing.Point(($x + 20), ($y + 10))
        $nosePoints = @($nosePoint1, $nosePoint2, $nosePoint3)
        
        $noseR = [math]::Min(255, $color.R + 50)
        $noseG = [math]::Min(255, $color.G + 50)
        $noseB = [math]::Min(255, $color.B + 50)
        $noseBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($color.A, $noseR, $noseG, $noseB))
        $g.FillPolygon($noseBrush, $nosePoints)
        $noseBrush.Dispose()
        
        # Outline
        $outlinePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2)
        $g.DrawRectangle($outlinePen, $x - 20, $y - 10, 40, 20)
        $g.DrawPolygon($outlinePen, $nosePoints)
        $outlinePen.Dispose()
    }
    
    # Draw motion trail
    hidden [void] DrawMotionTrail([System.Drawing.Graphics]$g, [int]$maxAge, [int]$size, [System.Drawing.Color]$baseColor) {
        foreach ($trail in $this.ParticleTrails) {
            $tAlpha = [int](150 * (1 - $trail.Age / $maxAge))
            if ($tAlpha -gt 0) {
                $tBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($tAlpha, $baseColor.R, $baseColor.G, $baseColor.B))
                $g.FillEllipse($tBrush, $trail.X - $size, $trail.Y - $size, $size * 2, $size * 2)
                $tBrush.Dispose()
            }
        }
    }
    
    # Draw info overlay
    hidden [void] DrawInfoOverlay([System.Drawing.Graphics]$g, [string[]]$lines, [System.Drawing.Color]$color) {
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush($color)
        
        $y = 80
        foreach ($line in $lines) {
            $g.DrawString($line, $infoFont, $infoBrush, 20, $y)
            $y += 25
        }
        
        $infoFont.Dispose()
        $infoBrush.Dispose()
    }
    
    # Draw math overlay
    hidden [void] DrawMathOverlay([System.Drawing.Graphics]$g, [int]$height, [string[]]$equations) {
        $mathFont = New-Object System.Drawing.Font("Consolas", 9)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        
        $y = $height - 70
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
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 200, 100))
        
        $actNames = @("", "✨ ACT 1: STATIONARY", "✨ ACT 2: SUBSONIC", "✨ ACT 3: MACH 1", "✨ ACT 4: SUPERSONIC")
        $titleText = "SHOW51: " + $actNames[$this.State.Act]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show51 {
    Write-Host "[Show51] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show51")) {
        $show = $Global:ShowManager.Shows["show51"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show51] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow51 class loaded (v3)" -ForegroundColor Green
