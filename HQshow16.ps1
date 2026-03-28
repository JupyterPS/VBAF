# =================================================
# HQshow16.ps1 — Wine Bottling Line v3
# Converted to Game Machine Architecture
# =================================================
Write-Host "`n=> _____ HQshow16 (Bottling Line v3) _____ <=`n" -ForegroundColor Cyan

# ============================================
# Show16 - Inherits from BaseShow
# ============================================
class Show16 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Bottles
    hidden [System.Windows.Forms.Label] $CounterLabel
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    
    # ========================================
    # Constructor
    # ========================================
    Show16([System.Windows.Forms.Panel]$panel) : base("show16", $panel) {
        # Initialize state (replaces $Global:Show16Data)
        $this.State = @{
            Produced = 0
            Rejected = 0
            Shipped  = 0
        }
        $this.Bottles = [System.Collections.ArrayList]::new()
        
        # Initialize 12 bottles
        for ($i = 0; $i -lt 12; $i++) {
            $null = $this.Bottles.Add([PSCustomObject]@{
                x = - ((Get-Random -Minimum 0 -Maximum 400) + ($i * 40))
                speed = (Get-Random -Minimum 2 -Maximum 6)
                quality = (Get-Random -Minimum 60 -Maximum 99)
                state = "moving"
            })
        }
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host " 🍾 [Show16] Initializing Bottling Line..." -ForegroundColor Cyan
        
        $self = $this  # Capture for closures
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::White
        
        # Counter label (top-left)
        $this.CounterLabel = New-Object System.Windows.Forms.Label
        $this.CounterLabel.AutoSize = $true
        $this.CounterLabel.Font = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $this.CounterLabel.Location = New-Object System.Drawing.Point(8, 8)
        $this.CounterLabel.Text = "Produced: 0  |  Rejected: 0  |  Shipped: 0"
        $this.CounterLabel.BackColor = [System.Drawing.Color]::Transparent
        $this.Panel.Controls.Add($this.CounterLabel)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Setup paint event
        $this.SetupPaintEvent($self)
        
        # Setup animation timer
        $this.SetupAnimationTimer($self)
        
        Write-Host " ✅ [Show16] Bottling Line ready!" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Animation handled by dedicated timer for precise 80ms timing
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host " 🛑 [Show16] Cleaning up..." -ForegroundColor Yellow
        
        # Stop animation timer
        if ($this.AnimationTimer) {
            $this.AnimationTimer.Stop()
            $this.AnimationTimer.Dispose()
            $this.AnimationTimer = $null
        }
        
        # Remove paint event
        if ($this.Panel) {
            $this.Panel.Remove_Paint($null)
        }
        
        # Hide panel
        $this.Panel.Visible = $false
        
        Write-Host " ✅ [Show16] Cleanup complete (data preserved)!" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    hidden [void] SetupPaintEvent($self) {
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderBottlingLine($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }
    
    hidden [void] SetupAnimationTimer($self) {
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 80  # ~12 FPS for smooth conveyor
        $this.AnimationTimer.Add_Tick({
            if (-not $self.Panel.Visible) { return }
            
            $self.UpdateBottles()
            $self.Panel.Invalidate()
        }.GetNewClosure())
        $this.AnimationTimer.Start()
    }
    
    hidden [void] RenderBottlingLine([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Conveyor belt
        $beltY = [int]($height * 0.5)
        $beltHeight = 60
        
        # Belt background
        $g.FillRectangle([System.Drawing.Brushes]::DimGray, 0, $beltY, $width, $beltHeight)
        
        # Belt stripes
        $stripeSpacing = 40
        for ($sx = 0; $sx -lt $width; $sx += $stripeSpacing) {
            $g.FillRectangle([System.Drawing.Brushes]::Gray, $sx, $beltY, 20, $beltHeight)
        }
        
        # Quality control zone
        $inspectionX = $width - 150
        $g.FillRectangle([System.Drawing.Brushes]::LightYellow, $inspectionX, $beltY - 80, 100, 80)
        $g.DrawRectangle([System.Drawing.Pens]::Orange, $inspectionX, $beltY - 80, 100, 80)
        $g.DrawString("QC", [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold), 
            [System.Drawing.Brushes]::DarkOrange, $inspectionX + 30, $beltY - 60)
        
        # Draw bottles
        foreach ($b in $this.Bottles) {
            $this.RenderBottle($g, $b, $beltY, $width)
        }
        
        # Legend
        $g.DrawString("← Production Line →", [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Italic), 
            [System.Drawing.Brushes]::DarkSlateGray, 10, $beltY + $beltHeight + 10)
    }
    
    hidden [void] RenderBottle([System.Drawing.Graphics]$g, $bottle, [int]$beltY, [int]$width) {
        $bx = $bottle.x
        $by = $beltY - 30
        $bottleWidth = 18
        $bottleHeight = 44
        
        if ($bottle.state -eq "rejected") {
            $by += 20  # Fallen position
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::LightGray)
        } else {
            if ($bottle.quality -ge 85) {
                $col = [System.Drawing.Color]::FromArgb(50, 200, 50)  # Green
            } elseif ($bottle.quality -ge 70) {
                $col = [System.Drawing.Color]::FromArgb(200, 200, 50)  # Yellow
            } else {
                $col = [System.Drawing.Color]::FromArgb(200, 100, 50)  # Orange
            }
            $brush = New-Object System.Drawing.SolidBrush($col)
        }
        
        # Bottle body
        $g.FillRectangle($brush, $bx, $by + 8, $bottleWidth, $bottleHeight - 16)
        
        # Bottle neck
        $neckWidth = [int]($bottleWidth * 0.5)
        $neckX = $bx + ([int]($bottleWidth * 0.25))
        $g.FillRectangle($brush, $neckX, $by, $neckWidth, 12)
        
        # Bottle bottom
        $g.FillEllipse($brush, $bx, $by + $bottleHeight - 10, $bottleWidth, 10)
        
        # Bottle outline
        $g.DrawRectangle([System.Drawing.Pens]::Black, $bx, $by + 8, $bottleWidth, $bottleHeight - 16)
        $g.DrawRectangle([System.Drawing.Pens]::Black, $neckX, $by, $neckWidth, 12)
        
        # Quality label
        $qualityColor = if ($bottle.state -eq "rejected") { [System.Drawing.Brushes]::Red } else { [System.Drawing.Brushes]::Black }
        $g.DrawString("$($bottle.quality)%", [System.Drawing.Font]::new("Segoe UI", 8), 
            $qualityColor, $bx - 2, $by - 18)
        
        $brush.Dispose()
    }
    
    hidden [void] UpdateBottles() {
        $inspectionZone = $this.Panel.Width - 150
        
        foreach ($b in $this.Bottles) {
            # Move bottle
            $b.x += $b.speed * 1.0
            
            # Quality control
            if ($b.x -gt $inspectionZone -and $b.state -eq "moving") {
                $threshold = (Get-Random -Minimum 65 -Maximum 80)
                if ($b.quality -lt $threshold) {
                    $b.state = "rejected"
                    $this.State.Rejected++
                    $b.speed = 0
                }
            }
            
            # End of line
            if ($b.x -gt $this.Panel.Width + 40) {
                if ($b.state -eq "moving") {
                    $this.State.Shipped++
                }
                $this.ResetBottle($b)
                $this.State.Produced++
            }
            
            # Cleanup rejected bottles
            if ($b.state -eq "rejected" -and $b.x -gt $this.Panel.Width + 60) {
                $this.ResetBottle($b)
            }
        }
        
        # Update counter
        if ($this.CounterLabel) {
            $this.CounterLabel.Text = "Produced: $($this.State.Produced)  |  Rejected: $($this.State.Rejected)  |  Shipped: $($this.State.Shipped)"
        }
    }
    
    hidden [void] ResetBottle($bottle) {
        $bottle.x = -60
        $bottle.quality = Get-Random -Minimum 60 -Maximum 99
        $bottle.state = "moving"
        $bottle.speed = (Get-Random -Minimum 2 -Maximum 6)
    }
}

# ============================================
# Legacy Compatibility
# ============================================
function Stop-Show16 {
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show16")) {
        $Global:ShowManager.Shows["show16"].Stop()
    }
}

Write-Host "✅ HQshow16 class loaded (v3) - Wine Bottling Line" -ForegroundColor Green
