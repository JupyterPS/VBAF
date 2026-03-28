# ===============================
# HQshow52.ps1 — Electromagnetic Spectrum Explorer v3
# Wave Physics Theater: The Rainbow of Energy
# Converted to Game Machine Architecture
# ===============================

Write-Host "`n=> _____ HQshow52 (EM Spectrum Explorer v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show52 - Inherits from BaseShow
# ============================================
class Show52 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Photons
    hidden [array] $SpectrumBands
    hidden [int] $TickCounter
    
    # ========================================
    # Constructor
    # ========================================
    Show52([System.Windows.Forms.Panel]$panel) : base("show52", $panel) {
        # Initialize state
        $this.State = @{
            TimeStep = 0
            CurrentBand = 0  # 0=Overview, 1-7=Individual bands
            ActTimer = 0
            WaveAnimPhase = 0
        }
        
        # Initialize collections
        $this.Photons = [System.Collections.ArrayList]::new()
        
        # Define spectrum bands
        $this.SpectrumBands = @(
            @{Name="✨ Radio";      Color=[System.Drawing.Color]::FromArgb(255, 255, 100, 100); Wavelength="1m - 1km";    Frequency="300 MHz - 3 kHz";   Energy="10⁻⁹ eV"; Apps="Broadcasting, WiFi, Radar"},
            @{Name="✨ Microwave";  Color=[System.Drawing.Color]::FromArgb(255, 255, 150, 100); Wavelength="1mm - 1m";     Frequency="300 GHz - 300 MHz"; Energy="10⁻⁶ eV"; Apps="Cooking, Satellite, 5G"},
            @{Name="✨ Infrared";   Color=[System.Drawing.Color]::FromArgb(255, 255, 100, 50);  Wavelength="700nm - 1mm";  Frequency="430 THz - 300 GHz"; Energy="10⁻³ eV"; Apps="Heat sensors, Remote control"},
            @{Name="✨ Visible";    Color=[System.Drawing.Color]::FromArgb(255, 150, 255, 150); Wavelength="400-700 nm";   Frequency="750-430 THz";       Energy="2-3 eV";  Apps="Human vision, Photography"},
            @{Name="✨ Ultraviolet";Color=[System.Drawing.Color]::FromArgb(255, 150, 150, 255); Wavelength="10-400 nm";    Frequency="30 PHz - 750 THz";  Energy="3-100 eV";Apps="Sterilization, Tanning"},
            @{Name="✨ X-ray";      Color=[System.Drawing.Color]::FromArgb(255, 200, 200, 255); Wavelength="0.01-10 nm";   Frequency="30 EHz - 30 PHz";   Energy="100 eV - 100 keV"; Apps="Medical imaging, Security"},
            @{Name="✨ Gamma";      Color=[System.Drawing.Color]::FromArgb(255, 255, 200, 255); Wavelength="<0.01 nm";     Frequency=">30 EHz";           Energy=">100 keV"; Apps="Cancer treatment, Astronomy"}
        )
        
        $this.TickCounter = 0
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  🌈 [Show52] Initializing EM Spectrum Explorer..." -ForegroundColor Cyan
        
        # Clear and setup panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::Black
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { 
            $prop.SetValue($this.Panel, $true, $null)
        }
        
        # Update ticker messages
        $Show52Messages = @(
            "✨ ELECTROMAGNETIC SPECTRUM EXPLORER - All Forms of Light",
            "✨ Radio waves: Longest wavelength, lowest energy",
            "✨ Infrared: Feel the heat, invisible warmth",
            "✨ Visible: The narrow band humans can see (ROYGBIV)",
            "✨ X-rays & Gamma rays: Highest energy, medical & astronomy"
        )
        $Global:messages = $Show52Messages
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host "  ✅ [Show52] EM spectrum bands and photon engine ready" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM (~50ms)
    [void] OnUpdate() {
        $this.TickCounter++
        $this.State.TimeStep++
        $this.State.ActTimer++
        $this.State.WaveAnimPhase += 0.15
        
        if ($this.State.WaveAnimPhase -gt 6.28) {
            $this.State.WaveAnimPhase -= 6.28
        }
        
        # Spawn and update photons in individual band mode
        if ($this.State.CurrentBand -gt 0) {
            if ($this.State.TimeStep % 10 -eq 0) {
                [void]$this.Photons.Add(@{
                    X = Get-Random -Minimum 50 -Maximum 600
                    Y = Get-Random -Minimum 100 -Maximum 300
                    Age = 0
                    VX = (Get-Random -Minimum -2 -Maximum 3)
                    VY = (Get-Random -Minimum -2 -Maximum 3)
                })
            }
            
            $this.UpdatePhotons()
        }
        
        # Band transitions (cycle through overview and all 7 bands)
        if ($this.State.ActTimer -gt 150) {
            $this.State.CurrentBand++
            if ($this.State.CurrentBand -gt 7) { 
                $this.State.CurrentBand = 0 
            }
            $this.State.ActTimer = 0
            $this.Photons.Clear()
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [Show52] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        if ($this.Photons) { $this.Photons.Clear() }
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.ActTimer = 0
        $this.State.CurrentBand = 0
        $this.State.WaveAnimPhase = 0
        $this.TickCounter = 0
        
        Write-Host "  ✅ [Show52] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Update photons (movement and removal)
    hidden [void] UpdatePhotons() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        foreach ($photon in $this.Photons) {
            $photon.X += $photon.VX
            $photon.Y += $photon.VY
            $photon.Age++
            
            if ($photon.Age -gt 50 -or $photon.X -lt 0 -or $photon.X -gt 700) {
                [void]$toRemove.Add($photon)
            }
        }
        
        foreach ($rem in $toRemove) {
            [void]$this.Photons.Remove($rem)
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
        $g.Clear([System.Drawing.Color]::Black)
        
        if ($this.State.CurrentBand -eq 0) {
            $this.DrawOverviewMode($g, $width, $height)
        } else {
            $this.DrawBandMode($g, $width, $height)
        }
        
        # Band indicator
        $this.DrawBandIndicator($g, $width)
    }
    
    # Draw overview mode (all bands)
    hidden [void] DrawOverviewMode([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $centerY = $height / 2
        $spectrumHeight = 100
        $spectrumY = $centerY - $spectrumHeight/2
        $bandWidth = $width / 7
        
        # Draw all spectrum bands
        for ($i = 0; $i -lt 7; $i++) {
            $band = $this.SpectrumBands[$i]
            $xStart = $i * $bandWidth
            
            $bandBrush = New-Object System.Drawing.SolidBrush($band.Color)
            $g.FillRectangle($bandBrush, $xStart, $spectrumY, $bandWidth, $spectrumHeight)
            $bandBrush.Dispose()
            
            # Band label
            $lblFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $lblBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $lblSize = $g.MeasureString($band.Name, $lblFont)
            $g.DrawString($band.Name, $lblFont, $lblBrush, $xStart + ($bandWidth - $lblSize.Width)/2, $spectrumY + $spectrumHeight/2 - $lblSize.Height/2)
            $lblFont.Dispose()
            $lblBrush.Dispose()
        }
        
        # Scales
        $this.DrawScales($g, $width, $spectrumY, $spectrumHeight)
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $titleText = "✨ THE ELECTROMAGNETIC SPECTRUM"
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width)/2, 60)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Info
        $infoFont = New-Object System.Drawing.Font("Consolas", 10)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("All electromagnetic waves travel at c = 3×10⁸ m/s", $infoFont, $infoBrush, 20, $height - 80)
        $g.DrawString("Relationship: c = λf  |  Energy: E = hf", $infoFont, $infoBrush, 20, $height - 60)
        $g.DrawString("Only VISIBLE light can be seen by human eyes!", $infoFont, $infoBrush, 20, $height - 40)
        $infoFont.Dispose()
        $infoBrush.Dispose()
    }
    
    # Draw scales for overview mode
    hidden [void] DrawScales([System.Drawing.Graphics]$g, [int]$width, [double]$spectrumY, [int]$spectrumHeight) {
        # Wavelength scale
        $scaleFont = New-Object System.Drawing.Font("Consolas", 8)
        $scaleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("← Longer Wavelength (λ)", $scaleFont, $scaleBrush, 20, $spectrumY - 30)
        $g.DrawString("Shorter Wavelength (λ) →", $scaleFont, $scaleBrush, $width - 200, $spectrumY - 30)
        $scaleFont.Dispose()
        $scaleBrush.Dispose()
        
        # Frequency scale
        $scaleFont2 = New-Object System.Drawing.Font("Consolas", 8)
        $scaleBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("← Lower Frequency (f)", $scaleFont2, $scaleBrush2, 20, $spectrumY + $spectrumHeight + 20)
        $g.DrawString("Higher Frequency (f) →", $scaleFont2, $scaleBrush2, $width - 200, $spectrumY + $spectrumHeight + 20)
        $scaleFont2.Dispose()
        $scaleBrush2.Dispose()
        
        # Energy scale
        $energyFont = New-Object System.Drawing.Font("Consolas", 8)
        $energyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Magenta)
        $g.DrawString("← Lower Energy (E)", $energyFont, $energyBrush, 20, $spectrumY + $spectrumHeight + 45)
        $g.DrawString("Higher Energy (E) →", $energyFont, $energyBrush, $width - 200, $spectrumY + $spectrumHeight + 45)
        $energyFont.Dispose()
        $energyBrush.Dispose()
    }
    
    # Draw individual band mode
    hidden [void] DrawBandMode([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $bandIndex = $this.State.CurrentBand - 1
        $band = $this.SpectrumBands[$bandIndex]
        $centerY = $height / 2
        
        # Background glow
        $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, $band.Color.R, $band.Color.G, $band.Color.B))
        $g.FillRectangle($glowBrush, 0, 0, $width, $height)
        $glowBrush.Dispose()
        
        # Draw animated wave
        $this.DrawAnimatedWave($g, $width, $centerY, $bandIndex, $band.Color)
        
        # Draw photons
        $this.DrawPhotons($g, $bandIndex)
        
        # Band title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush($band.Color)
        $titleText = $band.Name.ToUpper() + "WAVES"
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width)/2, 30)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Info panel
        $this.DrawBandInfo($g, $band)
        
        # Math equations
        $this.DrawMathEquations($g, $height)
        
        # Special effects for specific bands
        if ($bandIndex -eq 3) {
            # Visible light - rainbow
            $this.DrawVisibleSpectrum($g, $width, $height)
        } elseif ($bandIndex -eq 5 -or $bandIndex -eq 6) {
            # X-ray/Gamma - penetration
            $this.DrawPenetration($g, $width, $height, $bandIndex)
        }
    }
    
    # Draw animated wave
    hidden [void] DrawAnimatedWave([System.Drawing.Graphics]$g, [int]$width, [double]$centerY, [int]$bandIndex, [System.Drawing.Color]$color) {
        $wavePoints = New-Object 'System.Collections.Generic.List[System.Drawing.Point]'
        
        # Wavelength determines cycles
        $cyclesInView = switch ($bandIndex) {
            0 { 2 }   # Radio
            1 { 3 }   # Microwave
            2 { 5 }   # IR
            3 { 8 }   # Visible
            4 { 12 }  # UV
            5 { 20 }  # X-ray
            6 { 30 }  # Gamma
        }
        
        $amplitude = 80
        $wavelength = $width / $cyclesInView
        $phase = $this.State.WaveAnimPhase
        
        for ($xPix = 0; $xPix -lt $width; $xPix += 2) {
            $yVal = $centerY + $amplitude * [math]::Sin(2 * [math]::PI * $xPix / $wavelength + $phase)
            $wavePoints.Add((New-Object System.Drawing.Point($xPix, [int]$yVal)))
        }
        
        if ($wavePoints.Count -gt 1) {
            $waveArray = $wavePoints.ToArray()
            
            # Glow layers
            for ($i = 0; $i -lt 4; $i++) {
                $alpha = 60 + ($i * 30)
                $glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, $color.R, $color.G, $color.B), (6 - $i))
                $g.DrawLines($glowPen, $waveArray)
                $glowPen.Dispose()
            }
            
            # Main wave
            $mainPen = New-Object System.Drawing.Pen($color, 3)
            $g.DrawLines($mainPen, $waveArray)
            $mainPen.Dispose()
        }
    }
    
    # Draw photons
    hidden [void] DrawPhotons([System.Drawing.Graphics]$g, [int]$bandIndex) {
        foreach ($photon in $this.Photons) {
            $pAlpha = [int](200 * (1 - $photon.Age / 50.0))
            if ($pAlpha -gt 0) {
                $pColor = [System.Drawing.Color]::FromArgb($pAlpha, 255, 255, 255)
                $pBrush = New-Object System.Drawing.SolidBrush($pColor)
                
                # Size based on energy (gamma=tiny, radio=large)
                $pSize = 8 - $bandIndex
                $g.FillEllipse($pBrush, $photon.X - $pSize/2, $photon.Y - $pSize/2, $pSize, $pSize)
                $pBrush.Dispose()
            }
        }
    }
    
    # Draw band info panel
    hidden [void] DrawBandInfo([System.Drawing.Graphics]$g, [hashtable]$band) {
        $infoFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        
        $yPos = 100
        $g.DrawString("Wavelength: " + $band.Wavelength, $infoFont, $infoBrush, 20, $yPos)
        $yPos += 30
        $g.DrawString("Frequency: " + $band.Frequency, $infoFont, $infoBrush, 20, $yPos)
        $yPos += 30
        $g.DrawString("Energy: " + $band.Energy, $infoFont, $infoBrush, 20, $yPos)
        $yPos += 50
        
        $g.DrawString("Applications:", $infoFont, $infoBrush, 20, $yPos)
        $yPos += 30
        
        $appFont = New-Object System.Drawing.Font("Segoe UI", 8)
        $g.DrawString($band.Apps, $appFont, $infoBrush, 20, $yPos)
        $appFont.Dispose()
        
        $infoFont.Dispose()
        $infoBrush.Dispose()
    }
    
    # Draw math equations
    hidden [void] DrawMathEquations([System.Drawing.Graphics]$g, [int]$height) {
        $mathFont = New-Object System.Drawing.Font("Consolas", 10)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("c = λf = 3×10⁸ m/s", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("E = hf = hc/λ", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("h = 6.626×10⁻³⁴ J·s (Planck constant)", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }
    
    # Draw visible spectrum rainbow
    hidden [void] DrawVisibleSpectrum([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $rainbowY = $height - 150
        $rainbowHeight = 30
        $colors = @(
            [System.Drawing.Color]::FromArgb(148, 0, 211),    # Violet
            [System.Drawing.Color]::FromArgb(75, 0, 130),     # Indigo
            [System.Drawing.Color]::FromArgb(0, 0, 255),      # Blue
            [System.Drawing.Color]::FromArgb(0, 255, 0),      # Green
            [System.Drawing.Color]::FromArgb(255, 255, 0),    # Yellow
            [System.Drawing.Color]::FromArgb(255, 127, 0),    # Orange
            [System.Drawing.Color]::FromArgb(255, 0, 0)       # Red
        )
        
        $stripWidth = ($width - 40) / 7
        for ($i = 0; $i -lt 7; $i++) {
            $rainbowBrush = New-Object System.Drawing.SolidBrush($colors[$i])
            $g.FillRectangle($rainbowBrush, 20 + ($i * $stripWidth), $rainbowY, $stripWidth, $rainbowHeight)
            $rainbowBrush.Dispose()
        }
        
        # Labels
        $rainbowFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $rainbowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("R O Y G B I V", $rainbowFont, $rainbowBrush, $width/2 - 70, $rainbowY + 40)
        $g.DrawString("400nm ← → 700nm", $rainbowFont, $rainbowBrush, $width/2 - 80, $rainbowY + 60)
        $rainbowFont.Dispose()
        $rainbowBrush.Dispose()
    }
    
    # Draw penetration visualization
    hidden [void] DrawPenetration([System.Drawing.Graphics]$g, [int]$width, [int]$height, [int]$bandIndex) {
        $materials = @("Paper", "Skin", "Bone", "Lead")
        $yStart = $height - 150
        $barWidth = 60
        
        # Penetration values
        $penetration = if ($bandIndex -eq 5) { @(100, 80, 40, 10) } else { @(100, 90, 70, 30) }
        
        for ($i = 0; $i -lt 4; $i++) {
            $barHeight = $penetration[$i]
            $barColor = [System.Drawing.Color]::FromArgb(150, 200 - ($i * 40), 100, 200)
            $barBrush = New-Object System.Drawing.SolidBrush($barColor)
            $g.FillRectangle($barBrush, $width - 300 + ($i * 70), $yStart + (100 - $barHeight), $barWidth, $barHeight)
            $barBrush.Dispose()
            
            # Label
            $matFont = New-Object System.Drawing.Font("Consolas", 8)
            $matBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString($materials[$i], $matFont, $matBrush, $width - 295 + ($i * 70), $yStart + 105)
            $matFont.Dispose()
            $matBrush.Dispose()
        }
        
        # Title
        $penTitle = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $penBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("Penetration Power →", $penTitle, $penBrush, $width - 300, $yStart - 25)
        $penTitle.Dispose()
        $penBrush.Dispose()
    }
    
    # Draw band indicator
    hidden [void] DrawBandIndicator([System.Drawing.Graphics]$g, [int]$width) {
        $indicatorFont = New-Object System.Drawing.Font("Segoe UI", 10)
        $indicatorBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        
        if ($this.State.CurrentBand -eq 0) {
            $g.DrawString("OVERVIEW MODE", $indicatorFont, $indicatorBrush, $width - 180, 20)
        } else {
            $g.DrawString("Band $($this.State.CurrentBand) of 7", $indicatorFont, $indicatorBrush, $width - 150, 20)
        }
        
        $indicatorFont.Dispose()
        $indicatorBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show52 {
    Write-Host "[Show52] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show52")) {
        $show = $Global:ShowManager.Shows["show52"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show52] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow52 class loaded (v3)" -ForegroundColor Green

