# ====================================================
# HQshow3.ps1 — Nonlinear Waves & Solitons Theater v3
# Converted to Game Machine Architecture
# ZERO VISUAL CHANGES - Looks identical to V1
# ====================================================
Write-Host "`n=> _____ HQshow3 (Nonlinear Waves v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show3 - Inherits from BaseShow
# ============================================
class Show3 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [hashtable[]] $LinearPackets
    hidden [hashtable[]] $FourierHarmonics
    
    # ========================================
    # Constructor
    # ========================================
    Show3([System.Windows.Forms.Panel]$panel) : base("show3", $panel) {
        # Initialize state (replaces $Global:Show3Data)
        $this.State = @{
            TimeStep = 0
            Act = 1
            ActTimer = 0
            Soliton1 = @{X=100; Amplitude=50; Velocity=2.0; Width=30}
            Soliton2 = @{X=550; Amplitude=40; Velocity=-1.5; Width=35}
            LinearPulse = @{X=100; Amplitude=50; Width=30}
            NonlinearPulse = @{X=100; Amplitude=50; Width=30}
        }
        $this.LinearPackets = @()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host " 🌀 [Show3] Initializing Nonlinear Waves & Solitons Theater..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 10, 20)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Update ticker messages
        $Show3Messages = @(
            "🌀 NONLINEAR WAVES & SOLITONS - Beyond Linear Theory",
            "💫 Linear waves disperse and spread with time",
            "⚡ Nonlinearity balances dispersion → Solitons!",
            "🌊 Solitons: Waves that maintain their shape",
            "💥 Watch solitons collide and emerge unchanged!"
        )
        $Global:messages = $Show3Messages
        
        # Initialize linear pulse packets
        $this.LinearPackets = @()
        for ($k = -10; $k -le 10; $k++) {
            if ($k -ne 0) {
                $this.LinearPackets += @{
                    K = $k * 0.05
                    Amplitude = 50 * [math]::Exp(-[math]::Pow($k * 0.05, 2) / 0.01)
                    Phase = 0
                }
            }
        }
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host " ✅ [Show3] Nonlinear Waves & Solitons Theater ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Update animation state (replaces timer tick)
        $this.State.TimeStep += 0.15
        $this.State.ActTimer += 1
        
        # Update linear packets
        foreach ($packet in $this.LinearPackets) {
            $omega = $packet.K - [math]::Pow($packet.K, 3) / 6.0
            $packet.Phase += $omega * 0.1
            if ($packet.Phase -gt 6.28) { $packet.Phase -= 6.28 }
        }
        
        # Update solitons
        $this.State.Soliton1.X += $this.State.Soliton1.Velocity
        $this.State.Soliton2.X += $this.State.Soliton2.Velocity
        
        if ($this.State.Soliton1.X -gt 700) { $this.State.Soliton1.X = -50 }
        if ($this.State.Soliton2.X -lt -50) { $this.State.Soliton2.X = 700 }
        
        # Update nonlinear pulse
        $this.State.NonlinearPulse.X += 1.5
        if ($this.State.NonlinearPulse.X -gt 700) { $this.State.NonlinearPulse.X = 50 }
        
        # Act transitions
        if ($this.State.ActTimer -gt 200) {
            $this.State.Act++
            if ($this.State.Act -gt 4) { $this.State.Act = 1 }
            $this.State.ActTimer = 0
            
            $this.State.LinearPulse.X = 100
            $this.State.NonlinearPulse.X = 100
            $this.State.Soliton1.X = 100
            $this.State.Soliton2.X = 550
            $this.State.TimeStep = 0
            
            foreach ($packet in $this.LinearPackets) {
                $packet.Phase = 0
            }
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host " 🛑 [Show3] Cleaning up..." -ForegroundColor Yellow
        
        # Reset packets
        $this.LinearPackets = @()
        
        # Reset state
        $this.State.TimeStep = 0
        $this.State.ActTimer = 0
        $this.State.Act = 1
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        Write-Host " ✅ [Show3] Cleanup complete" -ForegroundColor Green
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
    
    # Main render method (EXACT V1 LOGIC)
    hidden [void] RenderScene([object]$sender, [System.Drawing.Graphics]$g) {
        $width = $sender.Width
        $height = $sender.Height
        
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Deep space background
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(5, 10, 20),
            [System.Drawing.Color]::FromArgb(15, 20, 40)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Stars background
        for ($i = 0; $i -lt 40; $i++) {
            $starX = ($i * 157) % $width
            $starY = ($i * 223) % ($height - 100)
            $brightness = 100 + (($i * 67) % 150)
            $starBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($brightness, $brightness, $brightness))
            $g.FillEllipse($starBrush, $starX, $starY + 60, 2, 2)
            $starBrush.Dispose()
        }
        
        $act = $this.State.Act
        $centerY = $height / 2
        $t = $this.State.TimeStep
        
        # === ACT 1: LINEAR DISPERSION ===
        if ($act -eq 1) {
            $pointsList = New-Object System.Collections.ArrayList
            
            for ($x = 0; $x -lt $width; $x += 2) {
                $y = 0
                
                foreach ($packet in $this.LinearPackets) {
                    $groupVel = 1.0 - [math]::Pow($packet.K, 2) / 2.0
                    $xShifted = $x - $this.State.LinearPulse.X - $groupVel * $t * 20
                    $y += $packet.Amplitude * [math]::Exp(-[math]::Pow($xShifted, 2) / 2000.0) * [math]::Cos($packet.K * $xShifted - $packet.Phase * 2)
                }
                
                [void]$pointsList.Add((New-Object System.Drawing.Point($x, [int]($centerY + $y))))
            }
            
            $points = $pointsList.ToArray()
            
            if ($points.Count -gt 1) {
                for ($i = 0; $i -lt 3; $i++) {
                    $alpha = 50 + ($i * 40)
                    $glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 255, 100, 100), (4 - $i))
                    $g.DrawLines($glowPen, $points)
                    $glowPen.Dispose()
                }
            }
            
            $spreadFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $spreadBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 255, 150, 150))
            $g.DrawString("← SPREADING →", $spreadFont, $spreadBrush, $width / 2 - 80, $centerY - 100)
            $spreadFont.Dispose()
            $spreadBrush.Dispose()
            
            $mathFont = New-Object System.Drawing.Font("Consolas", 8)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString("LINEAR: ∂u/∂t + c∂u/∂x + β∂³u/∂x³ = 0", $mathFont, $mathBrush, 20, $height - 60)
            $g.DrawString("Dispersion → Wave packet spreads over time", $mathFont, $mathBrush, 20, $height - 40)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        }
        
        # === ACT 2: NONLINEAR WAVE ===
        elseif ($act -eq 2) {
            $points = @()
            
            for ($x = 0; $x -lt $width; $x += 2) {
                $xShifted = $x - $this.State.NonlinearPulse.X
                $envelope = $this.State.NonlinearPulse.Amplitude * [math]::Exp(-[math]::Pow($xShifted, 2) / [math]::Pow($this.State.NonlinearPulse.Width, 2))
                $nonlinearShift = $envelope * 0.3 * [math]::Sin($xShifted / 20.0)
                $y = $envelope + $nonlinearShift
                
                $points += New-Object System.Drawing.Point($x, [int]($centerY + $y))
            }
            
            if ($points.Count -gt 1) {
                for ($i = 0; $i -lt 3; $i++) {
                    $alpha = 50 + ($i * 40)
                    $glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 255, 200, 100), (4 - $i))
                    $g.DrawLines($glowPen, $points)
                    $glowPen.Dispose()
                }
            }
            
            $arrowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
            $arrowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
            $g.DrawLine($arrowPen, $this.State.NonlinearPulse.X - 20, $centerY - 80, $this.State.NonlinearPulse.X + 30, $centerY - 80)
            $arrowPen.Dispose()
            
            $steepFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $steepBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            $g.DrawString("STEEPENING", $steepFont, $steepBrush, $this.State.NonlinearPulse.X - 30, $centerY - 110)
            $steepFont.Dispose()
            $steepBrush.Dispose()
            
            $mathFont = New-Object System.Drawing.Font("Consolas", 8)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $g.DrawString("NONLINEAR: ∂u/∂t + u∂u/∂x = 0  (Burgers without viscosity)", $mathFont, $mathBrush, 20, $height - 60)
            $g.DrawString("Wave peaks travel faster → Steepening", $mathFont, $mathBrush, 20, $height - 40)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        }
        
        # === ACT 3: SINGLE SOLITON ===
        elseif ($act -eq 3) {
            $soliton = $this.State.Soliton1
            $points = @()
            
            for ($x = 0; $x -lt $width; $x += 2) {
                $xShifted = ($x - $soliton.X) / $soliton.Width
                $coshVal = [math]::Cosh($xShifted)
                $sechSq = 1.0 / ($coshVal * $coshVal)
                $y = $soliton.Amplitude * $sechSq
                
                $points += New-Object System.Drawing.Point($x, [int]($centerY + $y))
            }
            
            if ($points.Count -gt 1) {
                for ($i = 0; $i -lt 4; $i++) {
                    $alpha = 60 + ($i * 40)
                    $glowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 100, 255, 100), (5 - $i))
                    $g.DrawLines($glowPen, $points)
                    $glowPen.Dispose()
                }
            }
            
            $arrowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 3)
            $arrowPen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
            $g.DrawLine($arrowPen, $soliton.X, $centerY - 80, $soliton.X + 60, $centerY - 80)
            $arrowPen.Dispose()
            
            $velFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $velBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
            $g.DrawString("v = constant", $velFont, $velBrush, $soliton.X + 10, $centerY - 110)
            $velFont.Dispose()
            $velBrush.Dispose()
            
            $labelFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 100, 255, 100))
            $g.DrawString("  NO SPREADING!", $labelFont, $labelBrush, $width / 2 - 100, 80)
            $labelFont.Dispose()
            $labelBrush.Dispose()
            
            $mathFont = New-Object System.Drawing.Font("Consolas", 8)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Cyan)
            $g.DrawString("KdV EQUATION: ∂u/∂t + 6u∂u/∂x + ∂³u/∂x³ = 0", $mathFont, $mathBrush, 20, $height - 70)
            $g.DrawString("Soliton solution: u(x,t) = -2κ²sech²[κ(x-4κ²t)]", $mathFont, $mathBrush, 20, $height - 50)
            $g.DrawString("Balance: Nonlinearity ⚖ Dispersion → Stable wave", $mathFont, $mathBrush, 20, $height - 30)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        }
        
        # === ACT 4: SOLITON COLLISION ===
        elseif ($act -eq 4) {
            $s1 = $this.State.Soliton1
            $s2 = $this.State.Soliton2
            $points = @()
            
            for ($x = 0; $x -lt $width; $x += 2) {
                $x1Shifted = ($x - $s1.X) / $s1.Width
                $cosh1 = [math]::Cosh($x1Shifted)
                $sech1Sq = 1.0 / ($cosh1 * $cosh1)
                $y1 = $s1.Amplitude * $sech1Sq
                
                $x2Shifted = ($x - $s2.X) / $s2.Width
                $cosh2 = [math]::Cosh($x2Shifted)
                $sech2Sq = 1.0 / ($cosh2 * $cosh2)
                $y2 = $s2.Amplitude * $sech2Sq
                
                $yCombined = $y1 + $y2
                $points += New-Object System.Drawing.Point($x, [int]($centerY + $yCombined))
            }
            
            if ($points.Count -gt 1) {
                for ($i = 0; $i -lt 4; $i++) {
                    $alpha = 60 + ($i * 40)
                    $color = [System.Drawing.Color]::FromArgb($alpha, 100 + $i * 30, 200 - $i * 20, 255 - $i * 30)
                    $glowPen = New-Object System.Drawing.Pen($color, (5 - $i))
                    $g.DrawLines($glowPen, $points)
                    $glowPen.Dispose()
                }
            }
            
            $arrow1Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 100, 255), 3)
            $arrow1Pen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
            $g.DrawLine($arrow1Pen, $s1.X, $centerY - 90, $s1.X + 50, $centerY - 90)
            $arrow1Pen.Dispose()
            
            $arrow2Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 100, 255, 255), 3)
            $arrow2Pen.StartCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
            $g.DrawLine($arrow2Pen, $s2.X - 50, $centerY - 90, $s2.X, $centerY - 90)
            $arrow2Pen.Dispose()
            
            $distance = [math]::Abs($s1.X - $s2.X)
            if ($distance -lt 100) {
                $collisionFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $collisionBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 0))
                $g.DrawString("  COLLISION!", $collisionFont, $collisionBrush, $width / 2 - 100, 80)
                $collisionFont.Dispose()
                $collisionBrush.Dispose()
            }
            
            $mathFont = New-Object System.Drawing.Font("Consolas", 8)
            $mathBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
            $g.DrawString("REMARKABLE: Solitons pass through each other!", $mathFont, $mathBrush, 20, $height - 70)
            $g.DrawString("Each emerges with same shape, speed, amplitude", $mathFont, $mathBrush, 20, $height - 50)
            $g.DrawString("Only phase shift: Δφ = ln(A₁/A₂)", $mathFont, $mathBrush, 20, $height - 30)
            $mathFont.Dispose()
            $mathBrush.Dispose()
        }
        
        # === TITLE & ACT INFO ===
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 255, 200))
        
        $actNames = @("", "✨ ACT 1: LINEAR DISPERSION", "✨ ACT 2: NONLINEARITY", "✨ ACT 3: SOLITON", "✨ ACT 4: COLLISION")
        $titleText = "SHOW3: " + $actNames[$act]
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show3 {
    Write-Host "🛑 [Show3] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show3")) {
        $show = $Global:ShowManager.Shows["show3"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show3] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow3 class loaded (v3)" -ForegroundColor Green
