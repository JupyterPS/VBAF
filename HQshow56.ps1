# ====================================================
# HQshow56.ps1 — Shock Waves & Explosions v3 (GM)
# PART 1: Class Definition & Core Methods
# ====================================================

Write-Host "`n=> _____ HQshow56 (Shock Waves v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show56 - Inherits from BaseShow
# ============================================
class Show56 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $BlastWaves
    hidden [System.Collections.ArrayList] $DebrisParticles
    hidden [System.Collections.ArrayList] $ReflectionPoints
    
    # ========================================
    # Constructor
    # ========================================
    Show56([System.Windows.Forms.Panel]$panel) : base("show56", $panel) {
        # Initialize state (replaces $Global:Show56Data)
        $this.State = @{
            TimeStep = 0
            Act = 1  # 1=Blast Wave, 2=Overpressure, 3=Mach Reflection, 4=Multiple Explosions
            ActTimer = 0
            ExplosionCenters = @()
        }
        
        $this.BlastWaves = [System.Collections.ArrayList]::new()
        $this.DebrisParticles = [System.Collections.ArrayList]::new()
        $this.ReflectionPoints = [System.Collections.ArrayList]::new()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host "  💥 [Show56] Initializing Shock Waves & Explosions..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 10, 15)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        # Reset state for fresh start
        $this.State.TimeStep = 0
        $this.State.Act = 1
        $this.State.ActTimer = 0
        $this.BlastWaves.Clear()
        $this.DebrisParticles.Clear()
        $this.ReflectionPoints.Clear()
        
        Write-Host "  ✅ [Show56] Shock Waves ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Update animation state
        $this.State.TimeStep += 1
        $this.State.ActTimer += 1
        
        # Update blast waves
        foreach ($wave in $this.BlastWaves) {
            $wave.Radius += 3
            $wave.Age += 1
        }
        
        # Act transitions (cycle through all 4 acts every ~8 seconds)
        if ($this.State.ActTimer -gt 200) {
            $this.State.Act++
            if ($this.State.Act -gt 4) { 
                $this.State.Act = 1 
            }
            $this.State.ActTimer = 0
            $this.State.TimeStep = 0
            $this.BlastWaves.Clear()
            $this.DebrisParticles.Clear()
            $this.ReflectionPoints.Clear()
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
        Write-Host "  🛑 [Show56] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        if ($this.BlastWaves) {
            $this.BlastWaves.Clear()
        }
        if ($this.DebrisParticles) {
            $this.DebrisParticles.Clear()
        }
        if ($this.ReflectionPoints) {
            $this.ReflectionPoints.Clear()
        }
        
        # Remove paint handler
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.Act = 1
        $this.State.ActTimer = 0
        
        Write-Host "  ✅ [Show56] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Paint Event Setup
    # ========================================
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderExplosions($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }
    
    # ========================================
    # Main Rendering Method
    # ========================================
    hidden [void] RenderExplosions([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Dark background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(10, 10, 15),
            [System.Drawing.Color]::FromArgb(20, 15, 10)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        $currentAct = $this.State.Act
        $centerX = $width / 2
        $centerY = $height / 2
        
        # Route to appropriate act renderer
        switch ($currentAct) {
            1 { $this.RenderBlastWave($g, $width, $height, $centerX, $centerY) }
            2 { $this.RenderOverpressure($g, $width, $height, $centerX, $centerY) }
            3 { $this.RenderMachReflection($g, $width, $height, $centerX, $centerY) }
            4 { $this.RenderMultipleExplosions($g, $width, $height, $centerX, $centerY) }
        }
        
        # Title overlay
        $this.RenderTitle($g, $width, $currentAct)
    }
    
    # ========================================
    # ACT 1: Blast Wave Propagation
    # ========================================
    hidden [void] RenderBlastWave([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY) {
        $maxRadius = 250
        $maxAge = 150
        
        # Spawn new blast wave periodically
        if ($this.State.TimeStep % 80 -eq 0) {
            [void]$this.BlastWaves.Add(@{
                Radius = 0
                Age = 0
                CenterX = $centerX
                CenterY = $centerY
            })
        }
        
        # Draw all active blast waves
        $wavesToRemove = [System.Collections.ArrayList]::new()
        foreach ($wave in $this.BlastWaves) {
            $this.DrawBlastWave($g, $wave.CenterX, $wave.CenterY, $wave.Radius, $wave.Age, $maxAge)
            
            if ($wave.Age -ge $maxAge) {
                [void]$wavesToRemove.Add($wave)
            }
        }
        
        foreach ($w in $wavesToRemove) {
            [void]$this.BlastWaves.Remove($w)
        }
        
        # Explosion epicenter
        $epicenterBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 0, 0))
        $g.FillEllipse($epicenterBrush, $centerX - 8, $centerY - 8, 16, 16)
        $epicenterBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 100))
        $g.DrawString("BLAST WAVE PROPAGATION", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Supersonic shock front", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Leading edge: Sharp discontinuity", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Followed by hot gases", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Speed indicator
        $speedFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $speedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Speed: >343 m/s (supersonic!)", $speedFont, $speedBrush, $width - 280, 60)
        $speedFont.Dispose()
        $speedBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Shock velocity: U = c + u (sound speed + particle velocity)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Overpressure: ΔP ∝ 1/R³ (near field)", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("TNT, C4, nuclear explosions", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # ACT 2: Overpressure Zones
    # ========================================
    hidden [void] RenderOverpressure([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY) {
        $radius = 50 + ($this.State.TimeStep % 120) * 1.5
        $maxPressure = 50
        
        # Draw overpressure field
        $this.DrawOverpressure($g, $centerX, $centerY, $radius, $this.State.TimeStep, 50)
        
        # Explosion center with pulsing
        $pulseSize = 15 + 5 * [math]::Sin($this.State.TimeStep * 0.1)
        $explosionBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 100, 0))
        $g.FillEllipse($explosionBrush, $centerX - $pulseSize, $centerY - $pulseSize, $pulseSize * 2, $pulseSize * 2)
        $explosionBrush.Dispose()
        
        # Pressure values at different distances
        $pressureData = @(
            @{Distance=50; Pressure=50; Damage="Complete destruction"},
            @{Distance=100; Pressure=12.5; Damage="Heavy structural damage"},
            @{Distance=150; Pressure=5.6; Damage="Moderate damage"},
            @{Distance=200; Pressure=3.1; Damage="Light damage"}
        )
        
        $dataY = 180
        $dataFont = New-Object System.Drawing.Font("Consolas", 9)
        $dataBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        
        $g.DrawString("Distance  | Pressure | Effect", $dataFont, $dataBrush, $width - 350, $dataY)
        $dataY += 20
        $g.DrawString("----------|----------|------------------", $dataFont, $dataBrush, $width - 350, $dataY)
        
        foreach ($pd in $pressureData) {
            $dataY += 18
            $line = "{0,6} m  | {1,5} PSI | {2}" -f $pd.Distance, $pd.Pressure, $pd.Damage
            $g.DrawString($line, $dataFont, $dataBrush, $width - 350, $dataY)
        }
        
        $dataFont.Dispose()
        $dataBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 150, 100))
        $g.DrawString("OVERPRESSURE ZONES", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Pressure above atmospheric", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Primary damage mechanism", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Measured in PSI or kPa", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Scaled distance: Z = R/W^(1/3)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Overpressure decreases with distance", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString(">5 PSI: Structural collapse likely", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # ACT 3: Mach Reflection
    # ========================================
    hidden [void] RenderMachReflection([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY) {
        $groundY = 400
        $burstHeight = 200
        $blastRadius = 30 + ($this.State.TimeStep % 150) * 2
        
        # Draw Mach reflection
        $this.DrawMachReflection($g, $width, $height, $centerX, $burstHeight, $blastRadius, $groundY)
        
        # Explosion center
        $burstBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 150, 0))
        $g.FillEllipse($burstBrush, $centerX - 10, $burstHeight - 10, 20, 20)
        $burstBrush.Dispose()
        
        # Height indicator
        $heightPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
        $heightPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
        $g.DrawLine($heightPen, $centerX, $burstHeight, $centerX, $groundY)
        $heightPen.Dispose()
        
        $heightFont = New-Object System.Drawing.Font("Consolas", 8)
        $heightBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Burst height", $heightFont, $heightBrush, $centerX + 15, $burstHeight + 80)
        $heightFont.Dispose()
        $heightBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 150))
        $g.DrawString("MACH REFLECTION", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Air burst above ground", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Incident + Reflected waves", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Creates vertical MACH STEM", $infoFont, $infoBrush, 20, 135)
        $g.DrawString("Enhanced ground damage!", $infoFont, $infoBrush, 20, 160)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Mach stem forms when height/radius < ~0.4", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Triple point: 3 shock waves meet", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Nuclear airbursts optimized for this effect", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }

    # ========================================
    # ACT 4: Multiple Explosions with Debris
    # ========================================
    hidden [void] RenderMultipleExplosions([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY) {
        # Multiple explosion centers
        $explosions = @(
            @{X=200; Y=250; Time=0},
            @{X=400; Y=200; Time=30},
            @{X=500; Y=300; Time=60}
        )
        
        foreach ($expl in $explosions) {
            $explAge = $this.State.TimeStep - $expl.Time
            
            if ($explAge -ge 0 -and $explAge -lt 120) {
                $explRadius = $explAge * 2
                $this.DrawBlastWave($g, $expl.X, $expl.Y, $explRadius, $explAge, 120)
            }
        }
        
        # Spawn debris particles
        if ($this.State.TimeStep % 5 -eq 0) {
            foreach ($expl in $explosions) {
                $explAge = $this.State.TimeStep - $expl.Time
                
                if ($explAge -ge 5 -and $explAge -lt 40) {
                    $angle = (Get-Random) * 2 * [math]::PI
                    $speed = Get-Random -Minimum 3 -Maximum 8
                    
                    [void]$this.DebrisParticles.Add(@{
                        X = $expl.X
                        Y = $expl.Y
                        VX = $speed * [math]::Cos($angle)
                        VY = $speed * [math]::Sin($angle) - 2
                        Age = 0
                        Size = Get-Random -Minimum 3 -Maximum 8
                    })
                }
            }
        }
        
        # Update and draw debris
        $debrisToRemove = [System.Collections.ArrayList]::new()
        foreach ($debris in $this.DebrisParticles) {
            $debris.X += $debris.VX
            $debris.Y += $debris.VY
            $debris.VY += 0.2  # Gravity
            $debris.Age += 1
            
            if ($debris.Age -gt 100 -or $debris.Y -gt $height) {
                [void]$debrisToRemove.Add($debris)
            }
        }
        
        $this.DrawDebrisField($g, $centerX, $centerY, $this.DebrisParticles)
        
        foreach ($d in $debrisToRemove) {
            [void]$this.DebrisParticles.Remove($d)
        }
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 100, 100))
        $g.DrawString("MULTIPLE EXPLOSIONS", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Chain reactions", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Flying debris & shrapnel", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Overlapping blast waves", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Debris velocity: v = √(2·ΔP/ρ)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Fragment range: hundreds of meters", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Secondary fires, structural collapse", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # Rendering Utility Methods
    # ========================================
    
    # Draw expanding blast wave with shock front
    hidden [void] DrawBlastWave([System.Drawing.Graphics]$g, [double]$centerX, [double]$centerY, [double]$radius, [int]$age, [int]$maxAge) {
        # Shock front (leading edge)
        $shockThickness = 8
        $alpha = [int](255 * (1 - $age / $maxAge))
        
        if ($alpha -gt 0) {
            # Outer glow
            for ($i = 0; $i -lt 5; $i++) {
                $glowAlpha = [int]($alpha * 0.6 * (1 - $i / 5.0))
                $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, 255, 150, 50)
                $glowPen = New-Object System.Drawing.Pen($glowColor, ($shockThickness + $i * 2))
                $g.DrawEllipse($glowPen, $centerX - $radius, $centerY - $radius, $radius * 2, $radius * 2)
                $glowPen.Dispose()
            }
            
            # Main shock front
            $shockColor = [System.Drawing.Color]::FromArgb($alpha, 255, 200, 100)
            $shockPen = New-Object System.Drawing.Pen($shockColor, $shockThickness)
            $g.DrawEllipse($shockPen, $centerX - $radius, $centerY - $radius, $radius * 2, $radius * 2)
            $shockPen.Dispose()
            
            # Inner fireball (early stage only)
            if ($age -lt $maxAge * 0.3) {
                $fireballRadius = $radius * 0.6
                $fireAlpha = [int](255 * (1 - $age / ($maxAge * 0.3)))
                
                # Draw multiple layers for gradient effect
                for ($i = 0; $i -lt 5; $i++) {
                    $layerRadius = $fireballRadius * (1 - $i / 5.0)
                    $layerAlpha = [int]($fireAlpha * (1 - $i / 5.0))
                    
                    # Inner layers are brighter (yellow-white)
                    if ($i -lt 2) {
                        $layerColor = [System.Drawing.Color]::FromArgb($layerAlpha, 255, 255, [int](200 - $i * 50))
                    } else {
                        # Outer layers are more orange-red
                        $layerColor = [System.Drawing.Color]::FromArgb($layerAlpha, 255, [int](150 - $i * 20), 0)
                    }
                    
                    $layerBrush = New-Object System.Drawing.SolidBrush($layerColor)
                    $g.FillEllipse($layerBrush, $centerX - $layerRadius, $centerY - $layerRadius, $layerRadius * 2, $layerRadius * 2)
                    $layerBrush.Dispose()
                }
            }
        }
    }
    
    # Draw overpressure visualization
    hidden [void] DrawOverpressure([System.Drawing.Graphics]$g, [double]$centerX, [double]$centerY, [double]$radius, [int]$age, [double]$maxPressure) {
        # Create pressure field visualization
        $numRings = 8
        
        for ($i = 0; $i -lt $numRings; $i++) {
            $ringRadius = $radius * ($i + 1) / $numRings
            
            # Pressure decreases with distance (approximately 1/r²)
            $pressure = $maxPressure / (($i + 1) * ($i + 1))
            
            # Color based on pressure
            if ($pressure -gt 10) {
                # Lethal zone - red
                $pressureColor = [System.Drawing.Color]::FromArgb(180, 255, 0, 0)
            } elseif ($pressure -gt 5) {
                # Severe damage - orange
                $pressureColor = [System.Drawing.Color]::FromArgb(150, 255, 100, 0)
            } elseif ($pressure -gt 2) {
                # Moderate damage - yellow
                $pressureColor = [System.Drawing.Color]::FromArgb(120, 255, 255, 0)
            } else {
                # Light damage - fading
                $pressureColor = [System.Drawing.Color]::FromArgb(80, 200, 200, 100)
            }
            
            $pressurePen = New-Object System.Drawing.Pen($pressureColor, 3)
            $g.DrawEllipse($pressurePen, $centerX - $ringRadius, $centerY - $ringRadius, $ringRadius * 2, $ringRadius * 2)
            $pressurePen.Dispose()
        }
        
        # Label pressure zones
        $labelFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        
        $labelData = @(
            @{Radius=($radius * 0.3); Text="LETHAL"; Color=[System.Drawing.Color]::Red},
            @{Radius=($radius * 0.5); Text="SEVERE"; Color=[System.Drawing.Color]::Orange},
            @{Radius=($radius * 0.7); Text="MODERATE"; Color=[System.Drawing.Color]::Yellow}
        )
        
        foreach ($label in $labelData) {
            $labelBrush = New-Object System.Drawing.SolidBrush($label.Color)
            $g.DrawString($label.Text, $labelFont, $labelBrush, $centerX + $label.Radius - 30, $centerY - 10)
            $labelBrush.Dispose()
        }
        
        $labelFont.Dispose()
    }
    
    # Draw ground and Mach reflection
    hidden [void] DrawMachReflection([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$centerX, [double]$centerY, [double]$radius, [double]$groundY) {
        # Draw ground
        $groundBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 60, 40, 20))
        $g.FillRectangle($groundBrush, 0, $groundY, $width, $height - $groundY)
        $groundBrush.Dispose()
        
        $groundLine = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 100, 80, 60), 3)
        $g.DrawLine($groundLine, 0, $groundY, $width, $groundY)
        $groundLine.Dispose()
        
        # Calculate if blast wave has reached ground
        $distanceToGround = $groundY - $centerY
        
        if ($radius -gt $distanceToGround) {
            # Incident wave reaches ground
            $incidentRadius = $radius
            
            # Draw incident wave
            $incidentPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 150, 100), 4)
            $g.DrawEllipse($incidentPen, $centerX - $incidentRadius, $centerY - $incidentRadius, $incidentRadius * 2, $incidentRadius * 2)
            $incidentPen.Dispose()
            
            # Calculate reflection point
            $intersectDist = [math]::Sqrt($incidentRadius * $incidentRadius - $distanceToGround * $distanceToGround)
            $reflectX1 = $centerX - $intersectDist
            $reflectX2 = $centerX + $intersectDist
            
            # Draw reflected wave (appears to come from mirror point below ground)
            $mirrorCenterY = $groundY + ($groundY - $centerY)
            $reflectedPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 200, 150), 3)
            $reflectedPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            $g.DrawEllipse($reflectedPen, $centerX - $incidentRadius, $mirrorCenterY - $incidentRadius, $incidentRadius * 2, $incidentRadius * 2)
            $reflectedPen.Dispose()
            
            # Mach stem (vertical shock wave along ground)
            if ($radius -gt $distanceToGround * 1.5) {
                $machHeight = $radius - $distanceToGround
                $machPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 100, 100), 6)
                $g.DrawLine($machPen, $centerX, $groundY, $centerX, $groundY - $machHeight)
                $machPen.Dispose()
                
                # Label
                $machFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $machBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
                $g.DrawString("MACH STEM", $machFont, $machBrush, $centerX + 10, $groundY - $machHeight/2)
                $machFont.Dispose()
                $machBrush.Dispose()
            }
            
            # Triple point (where incident, reflected, and Mach stem meet)
            if ($radius -gt $distanceToGround * 1.3) {
                $triplePointBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
                $g.FillEllipse($triplePointBrush, $reflectX2 - 6, $groundY - 6, 12, 12)
                $triplePointBrush.Dispose()
            }
        }
    }
    
    # Draw debris particles
    hidden [void] DrawDebrisField([System.Drawing.Graphics]$g, [double]$centerX, [double]$centerY, [System.Collections.ArrayList]$particles) {
        foreach ($particle in $particles) {
            $alpha = [int](255 * (1 - $particle.Age / 100.0))
            if ($alpha -gt 0) {
                $debrisColor = [System.Drawing.Color]::FromArgb($alpha, 100, 100, 100)
                $debrisBrush = New-Object System.Drawing.SolidBrush($debrisColor)
                
                # Tumbling debris
                $size = $particle.Size
                $g.FillRectangle($debrisBrush, $particle.X - $size/2, $particle.Y - $size/2, $size, $size)
                $debrisBrush.Dispose()
                
                # Smoke trail
                if ($particle.Age -lt 40) {
                    $trailAlpha = [int](100 * (1 - $particle.Age / 40.0))
                    $trailColor = [System.Drawing.Color]::FromArgb($trailAlpha, 80, 80, 80)
                    $trailBrush = New-Object System.Drawing.SolidBrush($trailColor)
                    $g.FillEllipse($trailBrush, $particle.X - 3, $particle.Y - 3, 6, 6)
                    $trailBrush.Dispose()
                }
            }
        }
    }
    
    # Render title overlay
    hidden [void] RenderTitle([System.Drawing.Graphics]$g, [int]$width, [int]$currentAct) {
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 200, 100))
        
        $actNames = @("", "✨ ACT 1: BLAST WAVE", "✨ ACT 2: OVERPRESSURE", "✨ ACT 3: MACH REFLECTION", "✨ ACT 4: MULTIPLE EXPLOSIONS")
        $titleText = "SHOW56: " + $actNames[$currentAct]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show56 {
    Write-Host "[Show56] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show56")) {
        $show = $Global:ShowManager.Shows["show56"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show56] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow56 class loaded (v3)" -ForegroundColor Green
