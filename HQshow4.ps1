# ====================================================
# HQshow4.ps1 — Quantum Computing Simulator v3
# Converted to Game Machine Architecture
# ZERO VISUAL CHANGES - Looks identical to V1
# ====================================================
Write-Host "`n=> _____ HQshow4 (Quantum Computing v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show4 - Inherits from BaseShow
# ============================================
class Show4 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Qubits
    hidden [System.Collections.ArrayList] $Entanglements
    hidden [System.Collections.ArrayList] $Gates
    hidden [System.Collections.ArrayList] $Particles
    
    # ========================================
    # Constructor
    # ========================================
    Show4([System.Windows.Forms.Panel]$panel) : base("show4", $panel) {
        $this.State = @{
            TickCount = 0
            MeasurementFlash = $null
            QuantumState = "Superposition"  # Superposition, Measuring, Collapsed
        }
        $this.Qubits = [System.Collections.ArrayList]::new()
        $this.Entanglements = [System.Collections.ArrayList]::new()
        $this.Gates = [System.Collections.ArrayList]::new()
        $this.Particles = [System.Collections.ArrayList]::new()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host " ⚛️ [Show4] Initializing Quantum Computing Simulator..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 20)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Update ticker messages
        $Show4Messages = @(
            "⚛️ QUANTUM COMPUTING SIMULATOR - Beyond Classical Limits",
            "🌀 Qubits exist in superposition of multiple states",
            "✨ Quantum entanglement enables instant correlation",
            "🎯 Measurement collapses the quantum wave function",
            "🚀 The future of AI computation - exponential power"
        )
        $Global:messages = $Show4Messages
        
        # Initialize qubits
        $this.InitializeQubits()
        $this.InitializeEntanglements()
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host " ✅ [Show4] Quantum Computing Simulator ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        # Update qubits
        foreach ($qubit in $this.Qubits) {
            # Spin rotation
            $qubit.SpinAngle += $qubit.SpinSpeed * 5
            if ($qubit.SpinAngle -gt 360) { $qubit.SpinAngle -= 360 }
            
            # Phase evolution
            if ($this.State.QuantumState -eq "Superposition") {
                $qubit.Phase += 0.5
                if ($qubit.Phase -gt 360) { $qubit.Phase -= 360 }
                
                $oscillation = [math]::Sin($tick * 0.05 + $qubit.Id) * 0.05
                $qubit.State0 = [math]::Max(0.1, [math]::Min(0.9, 0.5 + $oscillation))
                $qubit.State1 = 1 - $qubit.State0
            }
            
            # Update cloud particles
            foreach ($particle in $qubit.CloudParticles) {
                $particle.Angle += $particle.Speed
                if ($particle.Angle -gt 6.28) { $particle.Angle -= 6.28 }
            }
            
            $qubit.Pulse = [math]::Abs([math]::Sin($tick * 0.1 + $qubit.Id))
        }
        
        # Update entanglements
        foreach ($ent in $this.Entanglements) {
            $ent.PulsePhase += 0.15
            if ($ent.PulsePhase -gt 6.28) { $ent.PulsePhase -= 6.28 }
        }
        
        # Spawn quantum gates
        if ($tick % 60 -eq 0 -and $this.State.QuantumState -eq "Superposition") {
            $targetQubit = $this.Qubits | Get-Random
            $gateSymbols = @("H", "X", "Y", "Z", "T", "S")
            [void]$this.Gates.Add(@{
                X = $targetQubit.X
                Y = $targetQubit.Y - 40
                Symbol = $gateSymbols | Get-Random
                Life = 50
                Target = $targetQubit
            })
        }
        
        # Update gates
        $aliveGates = [System.Collections.ArrayList]::new()
        foreach ($gate in $this.Gates) {
            $gate.Life -= 1
            $gate.Y += 1
            
            if ($gate.Life -eq 25) {
                $temp = $gate.Target.State0
                $gate.Target.State0 = $gate.Target.State1
                $gate.Target.State1 = $temp
            }
            
            if ($gate.Life -gt 0) {
                [void]$aliveGates.Add($gate)
            }
        }
        $this.Gates = $aliveGates
        
        # Quantum state cycle
        if ($tick % 200 -eq 0) {
            $this.State.QuantumState = "Measuring"
            $this.State.MeasurementFlash = @{ Life = 50 }
        }
        
        if ($this.State.QuantumState -eq "Measuring" -and $tick % 220 -eq 0) {
            $this.State.QuantumState = "Collapsed"
            foreach ($qubit in $this.Qubits) {
                if ((Get-Random -Minimum 0 -Maximum 100) -lt ($qubit.State0 * 100)) {
                    $qubit.State0 = 1.0; $qubit.State1 = 0.0
                } else {
                    $qubit.State0 = 0.0; $qubit.State1 = 1.0
                }
            }
        }
        
        if ($this.State.QuantumState -eq "Collapsed" -and $tick % 250 -eq 0) {
            $this.State.QuantumState = "Superposition"
            foreach ($qubit in $this.Qubits) {
                $qubit.State0 = 0.5
                $qubit.State1 = 0.5
            }
        }
        
        # Update measurement flash
        if ($this.State.MeasurementFlash) {
            $this.State.MeasurementFlash.Life -= 1
            if ($this.State.MeasurementFlash.Life -le 0) {
                $this.State.MeasurementFlash = $null
            }
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host " 🛑 [Show4] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        $this.Qubits.Clear()
        $this.Entanglements.Clear()
        $this.Gates.Clear()
        $this.Particles.Clear()
        
        # Reset state
        $this.State.TickCount = 0
        $this.State.MeasurementFlash = $null
        $this.State.QuantumState = "Superposition"
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        Write-Host " ✅ [Show4] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    hidden [void] InitializeQubits() {
        $positions = @(
            @{X=150; Y=150}, @{X=300; Y=120}, @{X=450; Y=150}, @{X=550; Y=220},
            @{X=450; Y=290}, @{X=300; Y=320}, @{X=150; Y=290}, @{X=100; Y=220}
        )
        
        for ($i = 0; $i -lt 8; $i++) {
            $pos = $positions[$i]
            $qubit = @{
                Id = $i
                X = $pos.X
                Y = $pos.Y
                Radius = 25
                SpinAngle = Get-Random -Minimum 0 -Maximum 360
                SpinSpeed = 0.1 + (Get-Random -Minimum 0 -Maximum 50) / 100.0
                State0 = 0.5 + (Get-Random -Minimum -20 -Maximum 20) / 100.0
                State1 = 0.5 + (Get-Random -Minimum -20 -Maximum 20) / 100.0
                Phase = Get-Random -Minimum 0 -Maximum 360
                Color = [System.Drawing.Color]::FromArgb(100, 150, 255)
                Pulse = 0
                CloudParticles = [System.Collections.ArrayList]::new()
            }
            
            # Normalize probabilities
            $total = $qubit.State0 + $qubit.State1
            $qubit.State0 = $qubit.State0 / $total
            $qubit.State1 = $qubit.State1 / $total
            
            # Initialize cloud particles
            for ($p = 0; $p -lt 15; $p++) {
                [void]$qubit.CloudParticles.Add(@{
                    Angle = (Get-Random -Minimum 0 -Maximum 360) * [math]::PI / 180
                    Distance = Get-Random -Minimum 5 -Maximum 35
                    Speed = 0.02 + (Get-Random -Minimum 0 -Maximum 20) / 1000.0
                })
            }
            
            [void]$this.Qubits.Add($qubit)
        }
    }
    
    hidden [void] InitializeEntanglements() {
        $entanglementPairs = @(
            @(0, 1), @(1, 2), @(2, 3), @(3, 4), @(4, 5), @(5, 6), @(6, 7), @(7, 0)
        )
        
        foreach ($pair in $entanglementPairs) {
            [void]$this.Entanglements.Add(@{
                Qubit1 = $pair[0]
                Qubit2 = $pair[1]
                Strength = 0.5 + (Get-Random -Minimum 0 -Maximum 50) / 100.0
                PulsePhase = Get-Random -Minimum 0 -Maximum 360
            })
        }
    }
    
    # Setup paint event
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderScene($s, $e.Graphics)
        }.GetNewClosure())
    }
    
    # Main render method (EXACT V1 LOGIC)
    hidden [void] RenderScene([object]$sender, [System.Drawing.Graphics]$g) {
        $width = $sender.Width
        $height = $sender.Height
        
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Space background with stars
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(5, 5, 20),
            [System.Drawing.Color]::FromArgb(20, 10, 40)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Stars
        for ($i = 0; $i -lt 50; $i++) {
            $starX = ($i * 137) % $width
            $starY = ($i * 211) % $height
            $brightness = 150 + (($i * 73) % 100)
            $starBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($brightness, $brightness, $brightness))
            $g.FillEllipse($starBrush, $starX, $starY, 2, 2)
            $starBrush.Dispose()
        }
        
        # Draw entanglement lines
        foreach ($ent in $this.Entanglements) {
            $q1 = $this.Qubits[$ent.Qubit1]
            $q2 = $this.Qubits[$ent.Qubit2]
            
            $pulse = [math]::Abs([math]::Sin($ent.PulsePhase))
            $alpha = [int](50 + ($pulse * 100))
            $widthLine = 1 + ($pulse * 2)
            
            $entColor = [System.Drawing.Color]::FromArgb($alpha, 100, 255, 255)
            $entPen = New-Object System.Drawing.Pen($entColor, $widthLine)
            
            # Draw wavy line
            $midX = ($q1.X + $q2.X) / 2
            $midY = ($q1.Y + $q2.Y) / 2
            $wave = [math]::Sin($ent.PulsePhase) * 10
            
            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
            $path.AddBezier($q1.X, $q1.Y, $midX + $wave, $midY, $midX + $wave, $midY, $q2.X, $q2.Y)
            $g.DrawPath($entPen, $path)
            $path.Dispose()
            $entPen.Dispose()
        }
        
        # Draw qubits
        foreach ($qubit in $this.Qubits) {
            $x = $qubit.X
            $y = $qubit.Y
            $r = $qubit.Radius
            
            # Probability cloud
            foreach ($particle in $qubit.CloudParticles) {
                $px = $x + ($particle.Distance * [math]::Cos($particle.Angle))
                $py = $y + ($particle.Distance * [math]::Sin($particle.Angle))
                
                $alpha = [int](100 * ($qubit.State0 + $qubit.State1) / 2)
                $cloudColor = [System.Drawing.Color]::FromArgb($alpha, 150, 200, 255)
                $cloudBrush = New-Object System.Drawing.SolidBrush($cloudColor)
                $g.FillEllipse($cloudBrush, $px - 3, $py - 3, 6, 6)
                $cloudBrush.Dispose()
            }
            
            # Outer glow
            $glowSize = $r * 2
            $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 100, 200, 255))
            $g.FillEllipse($glowBrush, $x - $glowSize, $y - $glowSize, $glowSize * 2, $glowSize * 2)
            $glowBrush.Dispose()
            
            # Inner sphere (gradient)
            $spherePath = New-Object System.Drawing.Drawing2D.GraphicsPath
            $spherePath.AddEllipse($x - $r, $y - $r, $r * 2, $r * 2)
            $sphereBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($spherePath)
            $sphereBrush.CenterColor = [System.Drawing.Color]::FromArgb(200, 150, 220, 255)
            $sphereBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(200, 50, 100, 200))
            $g.FillPath($sphereBrush, $spherePath)
            $sphereBrush.Dispose()
            $spherePath.Dispose()
            
            # Spin indicator
            $spinAngleRad = $qubit.SpinAngle * [math]::PI / 180
            $spinX = $x + ($r * 0.7 * [math]::Cos($spinAngleRad))
            $spinY = $y + ($r * 0.7 * [math]::Sin($spinAngleRad))
            $spinPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), 2)
            $g.DrawLine($spinPen, $x, $y, $spinX, $spinY)
            $spinPen.Dispose()
            
            # Qubit label
            $labelFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $labelText = "Q$($qubit.Id)"
            $labelSize = $g.MeasureString($labelText, $labelFont)
            $g.DrawString($labelText, $labelFont, $labelBrush, $x - $labelSize.Width / 2, $y - $labelSize.Height / 2)
            $labelFont.Dispose()
            $labelBrush.Dispose()
            
            # State probabilities
            $stateFont = New-Object System.Drawing.Font("Consolas", 7)
            $stateBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 200, 255, 255))
            $stateText = "|0⟩:$([math]::Round($qubit.State0 * 100))% |1⟩:$([math]::Round($qubit.State1 * 100))%"
            $stateSize = $g.MeasureString($stateText, $stateFont)
            $g.DrawString($stateText, $stateFont, $stateBrush, $x - $stateSize.Width / 2, $y + $r + 5)
            $stateFont.Dispose()
            $stateBrush.Dispose()
        }
        
        # Quantum gates
        foreach ($gate in $this.Gates) {
            if ($gate.Life -gt 0) {
                $alpha = [math]::Min(255, $gate.Life * 5)
                $gateColor = [System.Drawing.Color]::FromArgb($alpha, 255, 200, 0)
                $gateBrush = New-Object System.Drawing.SolidBrush($gateColor)
                
                $gateFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $g.DrawString($gate.Symbol, $gateFont, $gateBrush, $gate.X - 10, $gate.Y - 10)
                $gateFont.Dispose()
                $gateBrush.Dispose()
            }
        }
        
        # Measurement flash
        if ($this.State.MeasurementFlash) {
            $flash = $this.State.MeasurementFlash
            $alpha = [math]::Min(255, $flash.Life * 10)
            
            $flashBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha / 3, 255, 255, 255))
            $g.FillRectangle($flashBrush, 0, 0, $width, $height)
            $flashBrush.Dispose()
            
            $flashFont = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
            $flashTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 255, 0))
            $flashText = "⚡ MEASUREMENT ⚡"
            $flashSize = $g.MeasureString($flashText, $flashFont)
            $g.DrawString($flashText, $flashFont, $flashTextBrush, ($width - $flashSize.Width) / 2, $height / 2)
            $flashFont.Dispose()
            $flashTextBrush.Dispose()
        }
        
        # Status info
        $statusFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $statusColor = switch ($this.State.QuantumState) {
            "Superposition" { [System.Drawing.Color]::FromArgb(150, 100, 255) }
            "Measuring" { [System.Drawing.Color]::FromArgb(255, 200, 0) }
            "Collapsed" { [System.Drawing.Color]::FromArgb(255, 100, 100) }
        }
        $statusBrush = New-Object System.Drawing.SolidBrush($statusColor)
        $statusText = "✨ STATE: $($this.State.QuantumState.ToUpper())"
        $g.DrawString($statusText, $statusFont, $statusBrush, 20, 20)
        $statusFont.Dispose()
        $statusBrush.Dispose()
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 180, 200, 255))
        $titleText = "✨ QUANTUM COMPUTING SIMULATOR"
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, $height - 40)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show4 {
    Write-Host "🛑 [Show4] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show4")) {
        $show = $Global:ShowManager.Shows["show4"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show4] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow4 class loaded (v3)" -ForegroundColor Green

