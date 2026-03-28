# ====================================================
# HQshow60.ps1 — Matter Waves (de Broglie) COMPLETE
# ====================================================

Write-Host "`n=> _____ HQshow60 (Matter Waves) COMPLETE ___________ <=`n" -ForegroundColor Cyan

class Show60 : BaseShow {
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Electrons
    hidden [System.Collections.ArrayList] $DiffractionPattern
    hidden [System.Collections.ArrayList] $TunnelParticles
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    
    Show60([System.Windows.Forms.Panel]$panel) : base("show60", $panel) {
        $this.State = @{
            TimeStep = 0; Act = 1; ActTimer = 0; WavePhase = 0; WavePacketSpread = 0
        }
        
        $this.Electrons = [System.Collections.ArrayList]::new()
        $this.DiffractionPattern = [System.Collections.ArrayList]::new()
        $this.TunnelParticles = [System.Collections.ArrayList]::new()
        
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 50
        
        $self = $this
        $this.AnimationTimer.Add_Tick({ $self.OnUpdate() }.GetNewClosure())
    }
    
    [void] OnStart() {
        Write-Host "  ⚛️ [Show60] Initializing Matter Waves..." -ForegroundColor Cyan
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 15)
        
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        $this.SetupPaintEvent()
        
        $this.State.TimeStep = 0; $this.State.Act = 1; $this.State.ActTimer = 0; $this.State.WavePhase = 0
        $this.Electrons.Clear(); $this.DiffractionPattern.Clear(); $this.TunnelParticles.Clear()
        
        $this.AnimationTimer.Start()
        
        Write-Host "  ✅ [Show60] Matter Waves ready" -ForegroundColor Green
    }
    
    [void] OnUpdate() {
        $this.State.TimeStep += 1
        $this.State.ActTimer += 1
        $this.State.WavePhase += 0.2
        
        if ($this.State.WavePhase -gt 6.28) { $this.State.WavePhase = 0 }
        
        if ($this.State.ActTimer -gt 220) {
            $this.State.Act++
            if ($this.State.Act -gt 4) { $this.State.Act = 1 }
            $this.State.ActTimer = 0; $this.State.TimeStep = 0; $this.State.WavePhase = 0
            $this.Electrons.Clear(); $this.DiffractionPattern.Clear(); $this.TunnelParticles.Clear()
        }
        
        if ($this.Panel -and $this.Panel.Visible -and $this.Panel.Width -gt 0) {
            $this.Panel.Invalidate()
        }
    }
    
    [void] OnStop() {
        Write-Host "  [Show60] Cleaning up..." -ForegroundColor Yellow
        
        if ($this.AnimationTimer) { $this.AnimationTimer.Stop() }
        if ($this.Electrons) { $this.Electrons.Clear() }
        if ($this.DiffractionPattern) { $this.DiffractionPattern.Clear() }
        if ($this.TunnelParticles) { $this.TunnelParticles.Clear() }
        
        $this.Panel.Controls.Clear()
        $this.State.TimeStep = 0; $this.State.Act = 1; $this.State.ActTimer = 0; $this.State.WavePhase = 0
        
        Write-Host "  [Show60] Cleanup complete" -ForegroundColor Green
    }
    
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderQuantumMechanics($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }
    
    hidden [void] RenderQuantumMechanics([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($width -le 0 -or $height -le 0) { return }
        
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(5, 5, 15), [System.Drawing.Color]::FromArgb(15, 10, 25)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        $this.DrawQuantumFoam($g, $width, $height)
        
        $currentAct = $this.State.Act
        $phase = $this.State.WavePhase
        
        switch ($currentAct) {
            1 { $this.RenderWaveParticleDuality($g, $width, $height, $phase) }
            2 { $this.RenderElectronDiffraction($g, $width, $height, $phase) }
            3 { $this.RenderQuantumTunneling($g, $width, $height, $phase) }
            4 { $this.RenderUncertaintyPrinciple($g, $width, $height, $phase) }
        }
        
        $this.RenderTitle($g, $width, $currentAct)
    }
    
    hidden [void] DrawQuantumFoam([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $foamRandom = New-Object System.Random(42)
        for ($i = 0; $i -lt 80; $i++) {
            $foamX = $foamRandom.Next(0, $width)
            $foamY = $foamRandom.Next(0, $height)
            $foamAlpha = $foamRandom.Next(30, 80)
            $foamColor = [System.Drawing.Color]::FromArgb($foamAlpha, 100, 150, 255)
            $foamBrush = New-Object System.Drawing.SolidBrush($foamColor)
            $g.FillEllipse($foamBrush, $foamX, $foamY, 2, 2)
            $foamBrush.Dispose()
        }
    }
    
    hidden [void] RenderTitle([System.Drawing.Graphics]$g, [int]$width, [int]$currentAct) {
        $actNames = @("", "ACT 1/4", "ACT 2/4", "ACT 3/4", "ACT 4/4")
        $actName = $actNames[$currentAct]
        
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 255, 255))
        
        $g.DrawString("✨ MATTER WAVES - de Broglie", $titleFont, $titleBrush, 20, 20)
        
        $actFont = New-Object System.Drawing.Font("Segoe UI", 10)
        $g.DrawString($actName, $actFont, $titleBrush, $width - 100, 20)
        
        $titleFont.Dispose()
        $actFont.Dispose()
        $titleBrush.Dispose()
    }
    
    hidden [void] RenderWaveParticleDuality([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        $particles = @(
            @{Name="Electron"; Mass=9.1e-31; Velocity=1e6; Y=150; Color=[System.Drawing.Color]::FromArgb(255, 100, 150, 255)},
            @{Name="Proton"; Mass=1.67e-27; Velocity=1e5; Y=250; Color=[System.Drawing.Color]::FromArgb(255, 255, 100, 100)},
            @{Name="Baseball"; Mass=0.145; Velocity=40; Y=350; Color=[System.Drawing.Color]::FromArgb(255, 200, 200, 200)}
        )
        
        $h = 6.626e-34
        
        foreach ($particle in $particles) {
            $momentum = $particle.Mass * $particle.Velocity
            $wavelength = $h / $momentum
            
            $displayWavelength = 60
            if ($wavelength -lt 1e-9) { 
                if ($wavelength -gt 1e-15) { $displayWavelength = 40 } 
                else { $displayWavelength = 20 }
            }
            
            $particleX = 150 + ($this.State.TimeStep % 400)
            
            $this.DrawElectronParticle($g, $particleX, $particle.Y, $true, $phase, $displayWavelength)
            
            $infoX = 450
            $infoY = $particle.Y - 40
            
            $infoFont = New-Object System.Drawing.Font("Consolas", 8)
            $infoBrush = New-Object System.Drawing.SolidBrush($particle.Color)
            $g.DrawString($particle.Name, $infoFont, $infoBrush, $infoX, $infoY)
            $g.DrawString("v = $($particle.Velocity) m/s", $infoFont, $infoBrush, $infoX, $infoY + 15)
            
            $lambdaStr = "very small"
            if ($wavelength -gt 1e-9) {
                $lambdaStr = "$([math]::Round($wavelength * 1e9, 2)) nm"
            } elseif ($wavelength -gt 1e-12) {
                $lambdaStr = "$([math]::Round($wavelength * 1e12, 2)) pm"
            } else {
                $lambdaStr = "$($wavelength.ToString('E2')) m"
            }
            $g.DrawString("λ = $lambdaStr", $infoFont, $infoBrush, $infoX, $infoY + 30)
            
            $infoFont.Dispose()
            $infoBrush.Dispose()
        }
        
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("WAVE-PARTICLE DUALITY", $titleFont, $titleBrush, 20, 60)
        $g.DrawString("Everything has wave properties!", $titleFont, $titleBrush, 20, 85)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        $mathFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("de Broglie wavelength: λ = h/p = h/(mv)", $mathFont, $mathBrush, 20, $height - 80)
        $g.DrawString("h = 6.626×10⁻³⁴ J·s (Planck's constant)", $mathFont, $mathBrush, 20, $height - 60)
        $g.DrawString("Nobel Prize 1929: Louis de Broglie", $mathFont, $mathBrush, 20, $height - 40)
        $mathFont.Dispose()
        $mathBrush.Dispose()
    }

    hidden [void] DrawElectronParticle([System.Drawing.Graphics]$g, [double]$x, [double]$y, [bool]$showWave, [double]$wavePhase, [double]$wavelength) {
        $electronBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 100, 150, 255))
        $g.FillEllipse($electronBrush, $x - 8, $y - 8, 16, 16)
        $electronBrush.Dispose()
        
        $chargeFont = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
        $chargeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("-", $chargeFont, $chargeBrush, $x - 4, $y - 6)
        $chargeFont.Dispose()
        $chargeBrush.Dispose()
        
        if ($showWave) {
            for ($i = -3; $i -le 3; $i++) {
                $waveX = $x + ($i * $wavelength / 4)
                $waveY = $y + 30 * [math]::Sin(2 * [math]::PI * $i / 4 + $wavePhase)
                
                $waveAlpha = [int](150 * (1 - [math]::Abs($i) / 3.0))
                $waveColor = [System.Drawing.Color]::FromArgb($waveAlpha, 100, 255, 200)
                $waveBrush = New-Object System.Drawing.SolidBrush($waveColor)
                $g.FillEllipse($waveBrush, $waveX - 3, $waveY - 3, 6, 6)
                $waveBrush.Dispose()
            }
        }
    }

    hidden [void] RenderElectronDiffraction([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        $gunX = 80; $gunY = 250
        
        $gunBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gray)
        $g.FillRectangle($gunBrush, $gunX - 30, $gunY - 15, 30, 30)
        $gunBrush.Dispose()
        
        $gunFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $gunLblBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $g.DrawString("e⁻ GUN", $gunFont, $gunLblBrush, $gunX - 28, $gunY - 5)
        $gunFont.Dispose()
        $gunLblBrush.Dispose()
        
        $slitX = 300; $slit1Y = 200; $slit2Y = 280; $slitHeight = 20
        
        $barrierBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 80, 80, 80))
        $g.FillRectangle($barrierBrush, $slitX, 150, 10, $slit1Y - 150)
        $g.FillRectangle($barrierBrush, $slitX, $slit1Y + $slitHeight, 10, $slit2Y - ($slit1Y + $slitHeight))
        $g.FillRectangle($barrierBrush, $slitX, $slit2Y + $slitHeight, 10, 400 - ($slit2Y + $slitHeight))
        $barrierBrush.Dispose()
        
        $slitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 2)
        $g.DrawRectangle($slitPen, $slitX, $slit1Y, 10, $slitHeight)
        $g.DrawRectangle($slitPen, $slitX, $slit2Y, 10, $slitHeight)
        $slitPen.Dispose()
        
        if ($this.State.TimeStep % 15 -eq 0) {
            [void]$this.Electrons.Add(@{X = $gunX; Y = $gunY; VX = 3; VY = (Get-Random -Minimum -1 -Maximum 2) * 0.5; Age = 0; Detected = $false})
        }
        
        $electronsToRemove = [System.Collections.ArrayList]::new()
        foreach ($electron in $this.Electrons) {
            $electron.X += $electron.VX
            $electron.Y += $electron.VY
            $electron.Age += 1
            
            if ($electron.X -gt 550 -and -not $electron.Detected) {
                $electron.Detected = $true
                [void]$this.DiffractionPattern.Add(@{Y = $electron.Y; Age = 0})
            }
            
            if ($electron.X -lt 550) { $this.DrawElectronParticle($g, $electron.X, $electron.Y, $false, $phase, 40) }
            
            if ($electron.X -gt 600 -or $electron.Age -gt 200) { [void]$electronsToRemove.Add($electron) }
        }
        
        foreach ($e in $electronsToRemove) { [void]$this.Electrons.Remove($e) }
        
        $patternToRemove = [System.Collections.ArrayList]::new()
        foreach ($det in $this.DiffractionPattern) {
            $det.Age += 1
            if ($det.Age -gt 100) { [void]$patternToRemove.Add($det) }
        }
        foreach ($p in $patternToRemove) { [void]$this.DiffractionPattern.Remove($p) }
        
        $this.DrawDiffractionIntensity($g, 570, 150, 250, $this.DiffractionPattern)
        
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Lime)
        $g.DrawString("ELECTRON DIFFRACTION", $titleFont, $titleBrush, 20, 60)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
    
    hidden [void] RenderQuantumTunneling([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        $barrierX = 300; $barrierY = 150; $barrierWidth = 80; $barrierHeight = 250; $particleEnergy = 0.4
        
        $this.DrawPotentialBarrier($g, $barrierX, $barrierY, $barrierWidth, $barrierHeight, $particleEnergy)
        
        if ($this.State.TimeStep % 20 -eq 0) {
            [void]$this.TunnelParticles.Add(@{X = 100; Y = $barrierY + ($barrierHeight * (1 - $particleEnergy)); VX = 2.5; VY = 0; Age = 0; State = "approaching"})
        }
        
        $tunnelToRemove = [System.Collections.ArrayList]::new()
        foreach ($particle in $this.TunnelParticles) {
            $particle.Age += 1
            
            if ($particle.State -eq "approaching") {
                $particle.X += $particle.VX
                if ($particle.X -ge $barrierX) {
                    if ((Get-Random) -lt 0.3) { $particle.State = "tunneling" } else { $particle.State = "reflected"; $particle.VX = -$particle.VX }
                }
            }
            elseif ($particle.State -eq "tunneling") {
                $particle.X += $particle.VX * 0.5
                if ($particle.X -ge $barrierX + $barrierWidth) { $particle.State = "transmitted" }
            }
            elseif ($particle.State -eq "transmitted" -or $particle.State -eq "reflected") {
                $particle.X += $particle.VX
            }
            
            $particleColor = [System.Drawing.Color]::FromArgb(255, 100, 150, 255)
            if ($particle.State -eq "tunneling") { $particleColor = [System.Drawing.Color]::FromArgb(180, 255, 100, 255) }
            elseif ($particle.State -eq "transmitted") { $particleColor = [System.Drawing.Color]::FromArgb(255, 100, 255, 100) }
            elseif ($particle.State -eq "reflected") { $particleColor = [System.Drawing.Color]::FromArgb(255, 255, 100, 100) }
            
            $pBrush = New-Object System.Drawing.SolidBrush($particleColor)
            $g.FillEllipse($pBrush, $particle.X - 6, $particle.Y - 6, 12, 12)
            $pBrush.Dispose()
            
            if ($particle.X -lt 0 -or $particle.X -gt 650 -or $particle.Age -gt 300) { [void]$tunnelToRemove.Add($particle) }
        }
        
        foreach ($t in $tunnelToRemove) { [void]$this.TunnelParticles.Remove($t) }
        
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Magenta)
        $g.DrawString("QUANTUM TUNNELING", $titleFont, $titleBrush, 20, 60)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
    
    hidden [void] RenderUncertaintyPrinciple([System.Drawing.Graphics]$g, [int]$width, [int]$height, [double]$phase) {
        $spread1 = 0.2; $spread2 = 0.6
        
        $packet1X = 200; $packet1Y = 180
        $this.DrawWavePacket($g, $packet1X, $packet1Y, 150, $spread1, $phase)
        
        $label1Font = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $label1Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("NARROW: Small Δx", $label1Font, $label1Brush, $packet1X + 200, $packet1Y - 30)
        $label1Font.Dispose()
        $label1Brush.Dispose()
        
        $packet2X = 200; $packet2Y = 350
        $this.DrawWavePacket($g, $packet2X, $packet2Y, 150, $spread2, $phase)
        
        $label2Font = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
        $label2Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
        $g.DrawString("WIDE: Large Δx", $label2Font, $label2Brush, $packet2X + 200, $packet2Y - 30)
        $label2Font.Dispose()
        $label2Brush.Dispose()
        
        $hbarFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $hbarBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 100, 255))
        $g.DrawString("Δx · Δp ≥ ℏ/2", $hbarFont, $hbarBrush, 480, 100)
        $hbarFont.Dispose()
        $hbarBrush.Dispose()
        
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 100, 255))
        $g.DrawString("HEISENBERG UNCERTAINTY", $titleFont, $titleBrush, 20, 60)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
    
    hidden [void] DrawWavePacket([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$width, [double]$spread, [double]$phase) {
        $numPoints = 60
        
        for ($i = 0; $i -lt $numPoints; $i++) {
            $t = ($i / [double]$numPoints) - 0.5
            $xi = $x + $t * $width
            
            $envelope = [Math]::Exp(-($t * $t) / (2 * $spread * $spread))
            $wave = [Math]::Sin(20 * $t + $phase)
            $amplitude = $envelope * $wave * 40
            
            $yi = $y + $amplitude
            
            $alpha = [int]($envelope * 200)
            $waveColor = [System.Drawing.Color]::FromArgb($alpha, 100, 200, 255)
            $waveBrush = New-Object System.Drawing.SolidBrush($waveColor)
            $g.FillEllipse($waveBrush, $xi - 2, $yi - 2, 4, 4)
            $waveBrush.Dispose()
        }
    }
    
    hidden [void] DrawDiffractionIntensity([System.Drawing.Graphics]$g, [double]$screenX, [double]$screenY, [double]$screenHeight, [System.Collections.ArrayList]$detections) {
        $screenPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3)
        $g.DrawLine($screenPen, $screenX, $screenY, $screenX, $screenY + $screenHeight)
        $screenPen.Dispose()
        
        foreach ($det in $detections) {
            $detAlpha = [int](200 * (1 - $det.Age / 100.0))
            if ($detAlpha -gt 0) {
                $detColor = [System.Drawing.Color]::FromArgb($detAlpha, 255, 255, 100)
                $detBrush = New-Object System.Drawing.SolidBrush($detColor)
                $g.FillEllipse($detBrush, $screenX - 8, $det.Y - 2, 16, 4)
                $detBrush.Dispose()
            }
        }
    }
    
    hidden [void] DrawPotentialBarrier([System.Drawing.Graphics]$g, [double]$x, [double]$y, [double]$width, [double]$height, [double]$energy) {
        $barrierBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 150, 100, 100))
        $g.FillRectangle($barrierBrush, $x, $y, $width, $height)
        $barrierBrush.Dispose()
        
        $barrierPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 3)
        $g.DrawRectangle($barrierPen, $x, $y, $width, $height)
        $barrierPen.Dispose()
        
        $energyY = $y + $height - ($energy * $height)
        $energyPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
        $energyPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        $g.DrawLine($energyPen, 50, $energyY, 650, $energyY)
        $energyPen.Dispose()
    } 
}

# Legacy compatibility
function Stop-Show60 {
    Write-Host "[Show60] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show60")) {
        $Global:ShowManager.Shows["show60"].Stop()
    }
}

Write-Host "✅ COMPLETE Show60 - Matter Waves (de Broglie)" -ForegroundColor Green
Write-Host "⚛️ All 4 quantum mechanics acts ready!" -ForegroundColor Cyan
 
