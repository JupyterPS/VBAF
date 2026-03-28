# ====================================================
# HQshow55.ps1 — Ocean Waves v3 (GM Architecture)
# PART 1: Class Definition & Core Methods
# ====================================================

Write-Host "`n=> _____ HQshow55 (Ocean Waves v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show55 - Inherits from BaseShow
# ============================================
class Show55 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $WaterParticles
    
    # ========================================
    # Constructor
    # ========================================
    Show55([System.Windows.Forms.Panel]$panel) : base("show55", $panel) {
        # Initialize state (replaces $Global:Show55Data)
        $this.State = @{
            TimeStep = 0
            Act = 1  # 1=Deep Water, 2=Shallow Water, 3=Wave Breaking, 4=Tsunami
            ActTimer = 0
            WavePhase = 0
            BreakingWave = @{X=0; Height=0; IsBroken=$false}
            TsunamiWave = @{X=0; Height=0; Speed=0}
        }
        
        $this.WaterParticles = [System.Collections.ArrayList]::new()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host "  🌊 [Show55] Initializing Ocean Waves Physics Theater..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 30, 50)
        
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
        $this.WaterParticles.Clear()
        
        Write-Host "  ✅ [Show55] Ocean Waves ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Update animation state
        $this.State.TimeStep += 1
        $this.State.ActTimer += 1
        $this.State.WavePhase += 0.1
        
        if ($this.State.WavePhase -gt 6.28) {
            $this.State.WavePhase = 0
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
            $this.WaterParticles.Clear()
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
        Write-Host "  🛑 [Show55] Cleaning up..." -ForegroundColor Yellow
        
        # Clear particles
        if ($this.WaterParticles) {
            $this.WaterParticles.Clear()
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
        
        Write-Host "  ✅ [Show55] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Paint Event Setup
    # ========================================
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderOcean($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }
    
    # ========================================
    # Main Rendering Method
    # ========================================
    hidden [void] RenderOcean([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        # Sky/water background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(135, 206, 235),
            [System.Drawing.Color]::FromArgb(10, 30, 50)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        $currentAct = $this.State.Act
        $phase = $this.State.WavePhase
        
        # Route to appropriate act renderer
        switch ($currentAct) {
            1 { $this.RenderDeepWater($g, $width, $height, $phase) }
            2 { $this.RenderShallowWater($g, $width, $height, $phase) }
            3 { $this.RenderBreakingWaves($g, $width, $height, $phase) }
            4 { $this.RenderTsunami($g, $width, $height, $phase) }
        }
        
        # Title overlay
        $this.RenderTitle($g, $width, $currentAct)
    }
    
    # ========================================
    # ACT 1: Deep Water Waves
    # ========================================
    hidden [void] RenderDeepWater([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        $surfaceY = 250
        $wavelength = 150
        $amplitude = 30
        $depth = 200
        
        # Draw deep ocean floor (flat)
        $this.DrawSeafloor($g, $width, 600, 0, 0, $depth, $depth)
        
        # Draw wave surface
        $this.DrawOceanSurface($g, $width, $surfaceY, $wavelength, $amplitude, $phase, 1.0)
        
        # Draw water particles with circular orbits at different depths
        $particleDepths = @(20, 50, 80, 120, 160)
        foreach ($d in $particleDepths) {
            $particleY = $surfaceY + $d
            
            # Orbit radius decreases exponentially with depth
            $orbitRadius = $amplitude * [math]::Exp(-2 * [math]::PI * $d / $wavelength)
            
            if ($orbitRadius -gt 2) {
                for ($px = 100; $px -lt 600; $px += 150) {
                    $particlePhase = $phase + (2 * [math]::PI * $px / $wavelength)
                    $this.DrawWaterParticle($g, $px, $particleY, $orbitRadius, $particlePhase, $false, 1.0)
                }
            }
        }
        
        # Depth indicator
        $depthPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
        $depthPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        $g.DrawLine($depthPen, 50, $surfaceY, 50, $surfaceY + $depth)
        $depthPen.Dispose()
        
        $depthFont = New-Object System.Drawing.Font("Consolas", 10)
        $depthBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Depth = $depth m", $depthFont, $depthBrush, 55, $surfaceY + $depth/2)
        $depthFont.Dispose()
        $depthBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("DEEP WATER WAVES", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Depth > λ/2 (wavelength/2)", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Circular particle orbits", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Orbit size decreases with depth", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 8)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Wave speed: c = √(gλ/2π)  (dispersion!)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Orbit radius: r(z) = A·exp(-kz)", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Open ocean: wind-driven waves", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # ACT 2: Shallow Water Waves
    # ========================================
    hidden [void] RenderShallowWater([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        $surfaceY = 280
        $wavelength = 150
        $amplitude = 25
        $depth = 40
        
        # Draw shallow seafloor
        $this.DrawSeafloor($g, $width, 600, 0, 0, $depth, $depth)
        
        # Shallow water wave (more peaked)
        $this.DrawOceanSurface($g, $width, $surfaceY, $wavelength, $amplitude, $phase, 0.3)
        
        # Draw water particles with elliptical orbits
        $particleDepths = @(10, 20, 30)
        foreach ($d in $particleDepths) {
            $particleY = $surfaceY + $d
            
            # In shallow water, vertical motion dominates
            $horizontalRadius = $amplitude * 0.6
            $ellipseRatio = 0.3 + (0.5 * $d / $depth)
            
            for ($px = 100; $px -lt 600; $px += 150) {
                $particlePhase = $phase + (2 * [math]::PI * $px / $wavelength)
                $this.DrawWaterParticle($g, $px, $particleY, $horizontalRadius, $particlePhase, $true, $ellipseRatio)
            }
        }
        
        # Depth indicator
        $depthPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
        $depthPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        $g.DrawLine($depthPen, 50, $surfaceY, 50, $surfaceY + $depth)
        $depthPen.Dispose()
        
        $depthFont = New-Object System.Drawing.Font("Consolas", 10)
        $depthBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Depth = $depth m", $depthFont, $depthBrush, 55, $surfaceY + $depth/2)
        $depthFont.Dispose()
        $depthBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("SHALLOW WATER WAVES", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Depth < λ/20 (wavelength/20)", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Elliptical particle orbits", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Waves feel the bottom!", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 9)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Wave speed: c = √(gh)  (depth-dependent!)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Speed decreases as depth decreases", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Near shore, coastal areas", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # ACT 3: Wave Breaking on Shore
    # ========================================
    hidden [void] RenderBreakingWaves([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        $surfaceY = 280
        $wavelength = 120
        $amplitude = 35
        
        # Draw sloping seafloor (continental shelf)
        $this.DrawSeafloor($g, $width, 600, 200, 550, 180, -20)
        
        # Multiple waves at different stages
        $basePositions = @(100, 250, 400, 550)
        $wavePositions = $basePositions | ForEach-Object { 
            ($_ + ($this.State.TimeStep * 2)) % 700 
        }
        
        foreach ($waveX in $wavePositions) {
            # Determine depth at this position
            if ($waveX -lt 200) {
                $localDepth = 180
                $breakingProgress = 0
            } elseif ($waveX -lt 350) {
                $ratio = ($waveX - 200) / 150
                $localDepth = 180 - ($ratio * 150)
                $breakingProgress = $ratio * 0.5
            } elseif ($waveX -lt 550) {
                $ratio = ($waveX - 350) / 200
                $localDepth = 30 - ($ratio * 50)
                $breakingProgress = 0.5 + ($ratio * 0.5)
            } else {
                $localDepth = -20
                $breakingProgress = 1.0
            }
            
            # Draw wave getting steeper and breaking
            if ($breakingProgress -gt 0.7) {
                # Breaking wave with foam
                $this.DrawBreakingWave($g, $waveX, (40 + $breakingProgress * 20), $breakingProgress)
            } else {
                # Regular wave
                $waveHeight = $amplitude * (1 + $breakingProgress * 0.8)
                $waveY = $surfaceY - $localDepth/2 - $waveHeight
                
                $waveBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 80, 180, 240))
                $g.FillEllipse($waveBrush, $waveX - 30, $waveY, 60, $waveHeight)
                $waveBrush.Dispose()
            }
        }
        
        # Beach/shore
        $beachBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 220, 200, 160))
        $beachPoints = @(
            [System.Drawing.Point]::new(500, 600),
            [System.Drawing.Point]::new(700, 600),
            [System.Drawing.Point]::new(700, 450),
            [System.Drawing.Point]::new(550, 400)
        )
        $g.FillPolygon($beachBrush, $beachPoints)
        $beachBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("WAVE BREAKING", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Bottom slows wave base", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Top overtakes bottom", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Wave collapses forward!", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 9)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Breaking criterion: H/h > 0.78 (wave height/depth)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Bottom friction + shoaling = breaking", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Surfing, beach erosion", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }

    # ========================================
    # ACT 4: Tsunami Formation
    # ========================================
    hidden [void] RenderTsunami([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        # Tsunami travels across ocean
        $tsunamiX = ($this.State.TimeStep * 4) % 700
        $surfaceY = 300
        
        # Ocean depth profile (deep to shallow)
        $this.DrawSeafloor($g, $width, 600, 450, 600, 250, 20)
        
        # Determine tsunami characteristics based on position
        if ($tsunamiX -lt 450) {
            # Deep ocean - fast, low amplitude
            $tsunamiHeight = 8
            $tsunamiWidth = 200
            $tsunamiSpeed = 800
        } else {
            # Approaching shore - slows down, grows
            $shoreRatio = ($tsunamiX - 450) / 150
            $tsunamiHeight = 8 + ($shoreRatio * 80)
            $tsunamiWidth = 200 - ($shoreRatio * 100)
            $tsunamiSpeed = 800 - ($shoreRatio * 700)
        }
        
        # Draw normal ocean surface
        $this.DrawOceanSurface($g, $width, $surfaceY, 180, 12, $phase, 1.0)
        
        # Draw tsunami wave
        $tsunamiPoints = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
        for ($x = [int]($tsunamiX - $tsunamiWidth); $x -le ($tsunamiX + $tsunamiWidth); $x += 5) {
            if ($x -ge 0 -and $x -le $width) {
                $dist = [math]::Abs($x - $tsunamiX)
                $waveProfile = $tsunamiHeight * [math]::Exp(-($dist * $dist) / (2 * $tsunamiWidth * $tsunamiWidth / 4))
                $y = $surfaceY - $waveProfile
                $tsunamiPoints.Add([System.Drawing.Point]::new($x, [int]$y))
            }
        }
        
        if ($tsunamiPoints.Count -gt 1) {
            $tsunamiPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 100, 100), 4)
            $g.DrawLines($tsunamiPen, $tsunamiPoints.ToArray())
            $tsunamiPen.Dispose()
        }
        
        # Warning indicators
        if ($tsunamiX -gt 400) {
            $warningFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $warningBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
            $g.DrawString("⚠️ TSUNAMI WARNING ⚠️", $warningFont, $warningBrush, $width/2 - 120, 150)
            $warningFont.Dispose()
            $warningBrush.Dispose()
        }
        
        # Speed/height labels
        $labelFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
        $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Speed: ~$([int]$tsunamiSpeed) km/h", $labelFont, $labelBrush, $tsunamiX - 60, $surfaceY - $tsunamiHeight - 40)
        $g.DrawString("Height: ~$([int]$tsunamiHeight) m", $labelFont, $labelBrush, $tsunamiX - 60, $surfaceY - $tsunamiHeight - 20)
        $labelFont.Dispose()
        $labelBrush.Dispose()
        
        # Info text
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("TSUNAMI FORMATION", $infoFont, $infoBrush, 20, 60)
        $g.DrawString("Very long wavelength (100+ km)", $infoFont, $infoBrush, 20, 85)
        $g.DrawString("Deep ocean: Fast, barely visible", $infoFont, $infoBrush, 20, 110)
        $g.DrawString("Shallow water: Slows, grows tall!", $infoFont, $infoBrush, 20, 135)
        $infoFont.Dispose()
        $infoBrush.Dispose()
        
        # Math overlay
        $mathFont = New-Object System.Drawing.Font("Consolas", 9)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("Deep ocean speed: c = √(gh) ≈ 800 km/h (depth=5km)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("Energy conserved: Wave slows + grows approaching shore", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Caused by earthquakes, landslides, volcanic eruptions", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # ========================================
    # Rendering Utility Methods
    # ========================================
    
    # Draw water particle orbit
    hidden [void] DrawWaterParticle([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$radius, [double]$phase, [bool]$isElliptical, [double]$ellipseRatio) {
        if ($isElliptical) {
            $particleX = $x + $radius * [math]::Cos($phase)
            $particleY = $y + $radius * $ellipseRatio * [math]::Sin($phase)
        } else {
            $particleX = $x + $radius * [math]::Cos($phase)
            $particleY = $y + $radius * [math]::Sin($phase)
        }
        
        # Draw particle
        $particleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 200, 255))
        $g.FillEllipse($particleBrush, $particleX - 4, $particleY - 4, 8, 8)
        $particleBrush.Dispose()
        
        # Draw orbit path
        if ($isElliptical) {
            $orbitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 150, 220, 255), 1)
            $orbitPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
            $g.DrawEllipse($orbitPen, $x - $radius, $y - $radius * $ellipseRatio, $radius * 2, $radius * 2 * $ellipseRatio)
            $orbitPen.Dispose()
        } else {
            $orbitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 150, 220, 255), 1)
            $orbitPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dot
            $g.DrawEllipse($orbitPen, $x - $radius, $y - $radius, $radius * 2, $radius * 2)
            $orbitPen.Dispose()
        }
    }
    
    # Draw ocean wave surface
    hidden [void] DrawOceanSurface([System.Drawing.Graphics]$g, [int]$width, [double]$surfaceY, [double]$wavelength, [double]$amplitude, [double]$phase, [double]$depthRatio) {
        $points = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
        
        for ($x = 0; $x -le $width; $x += 2) {
            $k = 2 * [math]::PI / $wavelength
            $waveHeight = $amplitude * [math]::Sin($k * $x - $phase)
            
            if ($depthRatio -lt 0.5) {
                $waveHeight = $waveHeight + $amplitude * 0.3 * [math]::Sin(2 * $k * $x - 2 * $phase)
            }
            
            $yPos = $surfaceY - $waveHeight
            $points.Add([System.Drawing.Point]::new($x, [int]$yPos))
        }
        
        $points.Add([System.Drawing.Point]::new($width, 600))
        $points.Add([System.Drawing.Point]::new(0, 600))
        
        if ($points.Count -gt 2) {
            $waterBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                [System.Drawing.Point]::new(0, $surfaceY),
                [System.Drawing.Point]::new(0, 600),
                [System.Drawing.Color]::FromArgb(180, 50, 150, 200),
                [System.Drawing.Color]::FromArgb(200, 20, 80, 120)
            )
            $g.FillPolygon($waterBrush, $points.ToArray())
            $waterBrush.Dispose()
            
            $surfacePoints = $points.ToArray()[0..($points.Count-3)]
            $surfacePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 150, 220, 255), 3)
            $g.DrawLines($surfacePen, $surfacePoints)
            $surfacePen.Dispose()
        }
    }
    
    # Draw seafloor profile
    hidden [void] DrawSeafloor([System.Drawing.Graphics]$g, [int]$width, [double]$floorY, [double]$slopeStart, [double]$slopeEnd, [double]$deepDepth, [double]$shallowDepth) {
        $points = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
        
        for ($x = 0; $x -le $width; $x += 5) {
            if ($x -lt $slopeStart) {
                $depth = $deepDepth
            } elseif ($x -gt $slopeEnd) {
                $depth = $shallowDepth
            } elseif ($slopeEnd -eq $slopeStart) {
                $depth = $deepDepth
            } else {
                $ratio = ($x - $slopeStart) / ($slopeEnd - $slopeStart)
                $depth = $deepDepth + $ratio * ($shallowDepth - $deepDepth)
            }
            
            $yPos = $floorY - $depth
            $points.Add([System.Drawing.Point]::new($x, [int]$yPos))
        }
        
        $points.Add([System.Drawing.Point]::new($width, 600))
        $points.Add([System.Drawing.Point]::new(0, 600))
        
        if ($points.Count -gt 2) {
            $floorBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 80, 60, 40))
            $g.FillPolygon($floorBrush, $points.ToArray())
            $floorBrush.Dispose()
            
            $floorPoints = $points.ToArray()[0..($points.Count-3)]
            $floorPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 120, 90, 60), 2)
            $g.DrawLines($floorPen, $floorPoints)
            $floorPen.Dispose()
        }
    }
    
    # Draw breaking wave with foam
    hidden [void] DrawBreakingWave([System.Drawing.Graphics]$g, [double]$x, [double]$waveHeight, [double]$breakingProgress) {
        $crestX = $x + 40
        $crestY = 250 - $waveHeight
        
        # Draw curling wave
        $curlRadius = 30 + ($breakingProgress * 20)
        $curlBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 80, 180, 230))
        $g.FillEllipse($curlBrush, $crestX - $curlRadius, $crestY - $curlRadius/2, $curlRadius * 2, $curlRadius)
        $curlBrush.Dispose()
        
        # Draw foam/spray
        $foamRandom = New-Object System.Random($x)
        for ($i = 0; $i -lt 20; $i++) {
            $foamX = $crestX + $foamRandom.Next(-40, 60)
            $foamY = $crestY + $foamRandom.Next(-30, 30)
            $foamSize = $foamRandom.Next(3, 10)
            
            $foamAlpha = [int](180 * $breakingProgress)
            $foamColor = [System.Drawing.Color]::FromArgb($foamAlpha, 255, 255, 255)
            $foamBrush = New-Object System.Drawing.SolidBrush($foamColor)
            $g.FillEllipse($foamBrush, $foamX, $foamY, $foamSize, $foamSize)
            $foamBrush.Dispose()
        }
    }
    
    # Render title overlay
    hidden [void] RenderTitle([System.Drawing.Graphics]$g, [int]$width, [int]$currentAct) {
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
        
        $actNames = @("", "✨ ACT 1: DEEP WATER", "✨ ACT 2: SHALLOW WATER", "✨ ACT 3: BREAKING WAVES", "✨ ACT 4: TSUNAMI")
        $titleText = "SHOW55: " + $actNames[$currentAct]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show55 {
    Write-Host "[Show55] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show55")) {
        $show = $Global:ShowManager.Shows["show55"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show55] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow55 class loaded (v3)" -ForegroundColor Green
