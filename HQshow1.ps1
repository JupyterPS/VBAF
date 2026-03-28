# ====================================================
# HQshow1.ps1 — Quantum Wave Simulator v3
# Converted to Game Machine Architecture
# ZERO VISUAL CHANGES - Looks identical to V1
# ====================================================

Write-Host "`n=> _____ HQshow1 (Quantum Wave v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show1 - Inherits from BaseShow
# ============================================
class Show1 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Particles
    hidden [System.Windows.Forms.Panel] $Canvas
    hidden [System.Windows.Forms.ComboBox] $WaveModeCombo
    hidden [System.Windows.Forms.CheckBox] $ShowMathCheck
    hidden [System.Windows.Forms.TrackBar] $SpeedTrack
    hidden [System.Windows.Forms.TrackBar] $AmpTrack
    
    # ========================================
    # Constructor
    # ========================================
    Show1([System.Windows.Forms.Panel]$panel) : base("show1", $panel) {
        # Initialize state (replaces $Global:Show1Data)
        $this.State = @{
            WaveMode    = "Sine"
            WaveOffset  = 0
            ShowMath    = $true
            TickCount   = 0
            Speed       = 4
            Amplitude   = 80
        }
        
        $this.Particles = [System.Collections.ArrayList]::new()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host "  🌊 [Show1] Initializing Quantum Wave Simulator..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::Black
        
        # Enable double buffering on main panel
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Create canvas
        $this.CreateCanvas()
        
        # Create control bar
        $this.CreateControls()
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host "  ✅ [Show1] Quantum Wave Simulator ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Update wave animation
        $this.State.WaveOffset += $this.State.Speed
        
        # Invalidate canvas to trigger repaint
        if ($this.Canvas -and $this.Canvas.Visible -and $this.Canvas.Width -gt 0) {
            $this.Canvas.Invalidate()
        }
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host "  🛑 [Show1] Cleaning up..." -ForegroundColor Yellow
        
        # Clear particles
        if ($this.Particles) {
            $this.Particles.Clear()
        }
        
        # Remove event handlers
        if ($this.WaveModeCombo) {
            $this.WaveModeCombo.Remove_SelectedIndexChanged($null)
        }
        if ($this.ShowMathCheck) {
            $this.ShowMathCheck.Remove_CheckedChanged($null)
        }
        if ($this.SpeedTrack) {
            $this.SpeedTrack.Remove_Scroll($null)
        }
        if ($this.AmpTrack) {
            $this.AmpTrack.Remove_Scroll($null)
        }
        if ($this.Canvas) {
            $this.Canvas.Remove_Paint($null)
        }
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset state
        $this.State.WaveOffset = 0
        $this.State.TickCount = 0
        
        Write-Host "  ✅ [Show1] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Create dedicated canvas for wave rendering
    hidden [void] CreateCanvas() {
        $this.Canvas = New-Object System.Windows.Forms.Panel
        $this.Canvas.Dock = 'Fill'
        $this.Canvas.BackColor = [System.Drawing.Color]::Black
        $this.Panel.Controls.Add($this.Canvas)
        
        # Enable double buffering on canvas
        $propCanvas = $this.Canvas.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($propCanvas) { $propCanvas.SetValue($this.Canvas, $true, $null) }
    }
    
    # Create bottom control bar (EXACT V1 LAYOUT)
    hidden [void] CreateControls() {
        $topBar = New-Object System.Windows.Forms.Panel
        $topBar.Dock = 'Bottom'
        $topBar.Height = 40
        $topBar.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
        $this.Panel.Controls.Add($topBar)
        
        # Wave mode label
        $lblMode = New-Object System.Windows.Forms.Label
        $lblMode.Text = "Type:"
        $lblMode.ForeColor = [System.Drawing.Color]::White
        $lblMode.Left = 10
        $lblMode.Top = 12
        $lblMode.AutoSize = $true
        $topBar.Controls.Add($lblMode)
        
        # Wave mode selector
        $this.WaveModeCombo = New-Object System.Windows.Forms.ComboBox
        $this.WaveModeCombo.DropDownStyle = 'DropDownList'
        $this.WaveModeCombo.Items.AddRange(@("Sine", "Cosine", "Square", "Triangle", "Sawtooth", "Composite"))
        $this.WaveModeCombo.SelectedIndex = 0
        $this.WaveModeCombo.Left = 70
        $this.WaveModeCombo.Width = 80
        $this.WaveModeCombo.Top = 8
        $topBar.Controls.Add($this.WaveModeCombo)
        
        # Show math checkbox
        $this.ShowMathCheck = New-Object System.Windows.Forms.CheckBox
        $this.ShowMathCheck.Text = "Show Math"
        $this.ShowMathCheck.Checked = $this.State.ShowMath
        $this.ShowMathCheck.Left = 165
        $this.ShowMathCheck.Top = 11
        $this.ShowMathCheck.ForeColor = [System.Drawing.Color]::White
        $topBar.Controls.Add($this.ShowMathCheck)
        
        # Speed label
        $lblSpeed = New-Object System.Windows.Forms.Label
        $lblSpeed.Text = "Speed:"
        $lblSpeed.ForeColor = [System.Drawing.Color]::White
        $lblSpeed.Left = 280
        $lblSpeed.Top = 12
        $lblSpeed.AutoSize = $true
        $topBar.Controls.Add($lblSpeed)
        
        # Speed control
        $this.SpeedTrack = New-Object System.Windows.Forms.TrackBar
        $this.SpeedTrack.Minimum = 1
        $this.SpeedTrack.Maximum = 10
        $this.SpeedTrack.Value = $this.State.Speed
        $this.SpeedTrack.Left = 335
        $this.SpeedTrack.Width = 100
        $this.SpeedTrack.Top = 5
        $this.SpeedTrack.Height = 30
        $this.SpeedTrack.TickStyle = 'None'
        $topBar.Controls.Add($this.SpeedTrack)
        
        # Amplitude label
        $lblAmp = New-Object System.Windows.Forms.Label
        $lblAmp.Text = "Amplitude:"
        $lblAmp.ForeColor = [System.Drawing.Color]::White
        $lblAmp.Left = 440
        $lblAmp.Top = 12
        $lblAmp.AutoSize = $true
        $topBar.Controls.Add($lblAmp)
        
        # Amplitude control
        $this.AmpTrack = New-Object System.Windows.Forms.TrackBar
        $this.AmpTrack.Minimum = 20
        $this.AmpTrack.Maximum = 150
        $this.AmpTrack.Value = $this.State.Amplitude
        $this.AmpTrack.Left = 530
        $this.AmpTrack.Width = 100
        $this.AmpTrack.Top = 5
        $this.AmpTrack.Height = 30
        $this.AmpTrack.TickStyle = 'None'
        $topBar.Controls.Add($this.AmpTrack)
        
        # Attach event handlers
        $this.AttachEventHandlers()
    }




    hidden [void] AttachEventHandlers() {
    # Capture the class instance so "$this" inside handlers doesn't become the sender
    $self = $this

    # Wave mode change
    $this.WaveModeCombo.Add_SelectedIndexChanged({
        param($sender, $args)
        if ($null -ne $sender.SelectedItem) {
            $self.State['WaveMode'] = $sender.SelectedItem.ToString()
            if ($self.Canvas) { $self.Canvas.Invalidate() }
        }
    }.GetNewClosure())

    # Show math toggle
    $this.ShowMathCheck.Add_CheckedChanged({
        param($sender, $args)
        $self.State['ShowMath'] = [bool]$sender.Checked
        if ($self.Canvas) { $self.Canvas.Invalidate() }
    }.GetNewClosure())

    # Speed change
    $this.SpeedTrack.Add_Scroll({
        param($sender, $args)
        $self.State['Speed'] = [int]$sender.Value
        # No invalidate needed unless you want immediate visual response
    }.GetNewClosure())

    # Amplitude change
    $this.AmpTrack.Add_Scroll({
        param($sender, $args)
        $self.State['Amplitude'] = [int]$sender.Value
        if ($self.Canvas) { $self.Canvas.Invalidate() }
    }.GetNewClosure())
}
    hidden [void] SetupPaintEvent() {
    $self = $this   # capture your custom object
    $this.Canvas.Add_Paint({
        param($s, $e)
        $self.RenderWave($e.Graphics, $s.Width, $s.Height)
    }.GetNewClosure())}
    
    # Render wave (EXACT V1 LOGIC)
    hidden [void] RenderWave([System.Drawing.Graphics]$g, [int]$w, [int]$h) {
        $g.SmoothingMode = 'AntiAlias'
        $g.Clear([System.Drawing.Color]::Black)
        
        $mid = $h / 2
        $A = $this.State.Amplitude
        $k = 1 / 30
        $phase = $this.State.WaveOffset / 30
        $points = @()
        $mode = $this.State.WaveMode
        
        # Generate wave points
        for ($x = 0; $x -lt $w; $x += 2) {
            $y = $mid
            
            switch ($mode) {
                "Sine" {
                    $y = $mid + $A * [math]::Sin($k * $x + $phase)
                }
                "Cosine" {
                    $y = $mid + $A * [math]::Cos($k * $x + $phase)
                }
                "Square" {
                    $y = $mid + $A * [math]::Sign([math]::Sin($k * $x + $phase))
                }
                "Triangle" {
                    $val = ((($x + $phase * 30) / 60) % 2)
                    $y = $mid + $A * (2 * [math]::Abs($val - 1) - 1)
                }
                "Sawtooth" {
                    $y = $mid + $A * ((($x + $phase * 30) / 60) % 2 - 1)
                }
                "Composite" {
                    $y = $mid + ($A * 0.75) * [math]::Sin($k * $x + $phase) + ($A * 0.375) * [math]::Sin(2 * $k * $x + $phase)
                }
                default {
                    $y = $mid + $A * [math]::Sin($k * $x + $phase)
                }
            }
            
            $points += New-Object System.Drawing.Point($x, [int]$y)
            
            # Spawn particles
            if (($x % 80 -eq 0) -and ($this.Particles.Count -lt 50)) {
                $newParticle = @{
                    X = $x
                    Y = $y
                    Alpha = 255
                    VX = (Get-Random -Minimum -1 -Maximum 2)
                }
                [void]$this.Particles.Add($newParticle)
            }
        }
        
        # Draw glowing wave
        if ($points.Count -gt 1) {
            # Glow layers
            for ($i = 0; $i -lt 3; $i++) {
                $alpha = 30 + ($i * 30)
                $widthPen = [float](4 - $i)
                $colorPen = [System.Drawing.Color]::FromArgb($alpha, 100, 150, 255)
                $pen = New-Object System.Drawing.Pen($colorPen, $widthPen)
                $g.DrawLines($pen, $points)
                $pen.Dispose()
            }
            
            # Main wave line
            $mainPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 0, 200, 255), 2)
            $g.DrawLines($mainPen, $points)
            $mainPen.Dispose()
        }
        
        # Animate particles
        $this.UpdateParticles($g, $w)
        
        # Math overlay
        if ($this.State.ShowMath) {
            $this.RenderMathOverlay($g, $w, $h, $mid, $A, $mode)
        }
        
        # FPS/Mode indicator
        $fontFPS = New-Object System.Drawing.Font("Consolas", 9)
        $g.DrawString("Mode: $mode", $fontFPS, [System.Drawing.Brushes]::Gray, $w - 150, 10)
        $fontFPS.Dispose()
    }
    
    # Update and render particles
    hidden [void] UpdateParticles([System.Drawing.Graphics]$g, [int]$w) {
        $remove = @()
        
        foreach ($p in $this.Particles) {
            $alpha = [math]::Max(0, $p.Alpha)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 200, 100))
            $g.FillEllipse($brush, [int]$p.X - 2, [int]$p.Y - 2, 4, 4)
            $brush.Dispose()
            
            $p.X += $p.VX
            $p.Alpha -= 5
            
            if (($p.Alpha -le 0) -or ($p.X -lt 0) -or ($p.X -gt $w)) {
                $remove += $p
            }
        }
        
        foreach ($r in $remove) {
            [void]$this.Particles.Remove($r)
        }
    }
    
    # Render math overlay (EXACT V1)
    hidden [void] RenderMathOverlay([System.Drawing.Graphics]$g, [int]$w, [int]$h, [double]$mid, [double]$A, [string]$mode) {
        $fontTitle = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $fontMath = New-Object System.Drawing.Font("Consolas", 11)
        $fontLabel = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        
        $g.DrawString("✨ Quantum Wave Function", $fontTitle, [System.Drawing.Brushes]::Cyan, 20, 20)
        
        # Equation
        $equation = "ψ(x,t) = A · sin(kx − ωt)"
        switch ($mode) {
            "Cosine"    { $equation = "ψ(x,t) = A · cos(kx − ωt)" }
            "Square"    { $equation = "ψ(x,t) = A · sgn(sin(kx − ωt))" }
            "Triangle"  { $equation = "ψ(x,t) = A · triangle(kx − ωt)" }
            "Sawtooth"  { $equation = "ψ(x,t) = A · sawtooth(kx − ωt)" }
            "Composite" { $equation = "ψ(x,t) = A·sin(kx−ωt) + A/2·sin(2kx−ωt)" }
        }
        
        $g.DrawString($equation, $fontMath, [System.Drawing.Brushes]::White, 20, 50)
        
        # Amplitude indicator
        if ($mid - $A - 25 -gt 80) {
            $g.DrawString("Amplitude", $fontLabel, [System.Drawing.Brushes]::Yellow, 20, $mid - $A - 25)
            $arrowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 2)
            $g.DrawLine($arrowPen, 20, $mid, 20, $mid - $A)
            $arrowPen.Dispose()
        }
        
        # Wavelength indicator
        if ($mid + $A + 25 -lt $h - 50) {
            $waveLen = 188
            $wavePen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gray, 1)
            $g.DrawLine($wavePen, 100, $mid + $A + 20, 288, $mid + $A + 20)
            $wavePen.Dispose()
            $g.DrawString("λ (Wavelength)", $fontLabel, [System.Drawing.Brushes]::White, 120, $mid + $A + 25)
        }
        
        $fontTitle.Dispose()
        $fontMath.Dispose()
        $fontLabel.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Functions
# ============================================

# Keep this for ShowD integration
function Stop-Show1 {
    Write-Host "🛑 [Show1] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show1")) {
        $show = $Global:ShowManager.Shows["show1"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show1] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow1 class loaded (v3)" -ForegroundColor Green

