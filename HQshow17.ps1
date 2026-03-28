# =================================================
# HQshow17.ps1 — Vineyard Growth v3
# Wine Company - Full Vineyard Animation
# =================================================
Write-Host "`n=> _____ HQshow17 (Vineyard v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show17 - Inherits from BaseShow
# ============================================
class Show17 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $VineProducts
    hidden [System.Windows.Forms.Label] $WeatherLabel
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    hidden [int] $TickCount = 0
    
    # ========================================
    # Constructor
    # ========================================
    Show17([System.Windows.Forms.Panel]$panel) : base("show17", $panel) {
        $this.State = @{
            Season = 0
            Weather = "☀️"
            CloudX = 0
            SunX = 0
        }
        $this.VineProducts = [System.Collections.ArrayList]::new()
        
        # Initialize 3 vine types
        $null = $this.VineProducts.Add([PSCustomObject]@{
            Name="Red"; Growth=0.5; Color=[System.Drawing.Brushes]::DarkRed
            Leaves = @(); Grapes = @()
        })
        $null = $this.VineProducts.Add([PSCustomObject]@{
            Name="White"; Growth=0.5; Color=[System.Drawing.Brushes]::Goldenrod
            Leaves = @(); Grapes = @()
        })
        $null = $this.VineProducts.Add([PSCustomObject]@{
            Name="Rosé"; Growth=0.5; Color=[System.Drawing.Brushes]::HotPink
            Leaves = @(); Grapes = @()
        })
        
        # Pre-generate vine elements
        foreach ($vine in $this.VineProducts) {
            for ($i = 0; $i -lt 10; $i++) {
                $vine.Leaves += @{
                    OffsetX = Get-Random -Minimum -20 -Maximum 20
                    OffsetY = Get-Random -Minimum 40 -Maximum 120
                    Width = 14 + (Get-Random -Minimum 0 -Maximum 8)
                    Height = 8 + (Get-Random -Minimum 0 -Maximum 6)
                }
            }
            for ($i = 0; $i -lt 15; $i++) {
                $vine.Grapes += @{
                    OffsetX = Get-Random -Minimum -12 -Maximum 12
                    OffsetY = Get-Random -Minimum 20 -Maximum 60
                    Radius = 4 + (Get-Random -Minimum 0 -Maximum 3)
                }
            }
        }
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host " 🍷 [Show17] Initializing Vineyard..." -ForegroundColor Cyan
        
        $self = $this  # Capture for closures
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(245, 240, 230)
        
        # Weather label
        $this.WeatherLabel = New-Object System.Windows.Forms.Label
        $this.WeatherLabel.AutoSize = $true
        $this.WeatherLabel.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $this.WeatherLabel.Location = New-Object System.Drawing.Point(8,8)
        $this.WeatherLabel.Text = "✨ Weather: ☀️"
        $this.WeatherLabel.BackColor = [System.Drawing.Color]::Transparent
        $this.Panel.Controls.Add($this.WeatherLabel)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Setup paint event
        $this.SetupPaintEvent($self)
        
        # Setup animation timer (500ms)
        $this.SetupAnimationTimer($self)
        
        Write-Host " ✅ [Show17] Vineyard ready!" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        # Animation handled by 500ms dedicated timer
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host " 🛑 [Show17] Cleaning up..." -ForegroundColor Yellow
        
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
        
        Write-Host " ✅ [Show17] Cleanup complete!" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    hidden [void] SetupPaintEvent($self) {
        $this.Panel.Add_Paint({
            param($s, $e)
            try {
                $self.RenderVineyard($e.Graphics, $s.Width, $s.Height)
            } catch {
                # Silent paint fail
            }
        }.GetNewClosure())
    }
    
    hidden [void] SetupAnimationTimer($self) {
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 500  # Original timing preserved
        $this.AnimationTimer.Add_Tick({
            if (-not $self.Panel.Visible) { return }
            
            $self.TickCount++
            $self.UpdateVineyard()
            $self.Panel.Invalidate()
        }.GetNewClosure())
        $this.AnimationTimer.Start()
    }
    
    hidden [void] RenderVineyard([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $skyHeight = [int]($height * 0.375)
        
        # Sky and ground
        $g.FillRectangle([System.Drawing.Brushes]::LightSkyBlue, 0, 0, $width, $skyHeight)
        $g.FillRectangle([System.Drawing.Brushes]::DarkOliveGreen, 0, $skyHeight, $width, $height - $skyHeight)
        
        # Sun animation
        $sunX = $this.State.SunX % $width
        $g.FillEllipse([System.Drawing.Brushes]::Gold, $sunX, 40, 40, 40)
        
        # Clouds
        for ($i=0; $i -lt 3; $i++) {
            $cx = ($this.State.CloudX + ($i * 120)) % $width
            $cy = 30 + ($i * 10)
            $g.FillEllipse([System.Drawing.Brushes]::White, $cx, $cy, 60, 30)
            $g.FillEllipse([System.Drawing.Brushes]::White, $cx + 20, $cy - 10, 50, 30)
        }
        
        # Trellis
        $trellisY = $skyHeight + 30
        $penBrown = New-Object System.Drawing.Pen([System.Drawing.Color]::SaddleBrown, 3)
        $g.DrawLine($penBrown, 20, $trellisY, $width - 20, $trellisY)
        $penBrown.Dispose()
        
        $cols = $this.VineProducts.Count
        if ($cols -eq 0) { return }
        $spacing = [math]::Floor(($width - 80) / $cols)
        $pulse = [Math]::Sin([DateTime]::Now.Millisecond / 100.0)
        
        # Render vines
        for ($i=0; $i -lt $cols; $i++) {
            $vine = $this.VineProducts[$i]
            $x = 40 + ($i * $spacing)
            $stemHeight = 80 + [math]::Round($vine.Growth * 140)
            
            # Season color
            $seasonColor = switch ($this.State.Season) {
                0 { [System.Drawing.Color]::LightGreen }
                1 { [System.Drawing.Color]::Orange }
                2 { [System.Drawing.Color]::Purple }
                default { [System.Drawing.Color]::Gray }
            }
            $brush = New-Object System.Drawing.SolidBrush($seasonColor)
            
            # Vine stems
            for ($seg=0; $seg -lt 6; $seg++) {
                $sx = $x + (10 * [math]::Sin(($seg + $vine.Growth * 3 + $pulse) * 0.7))
                $sy = $trellisY - ($seg * ($stemHeight / 6))
                $size = 6 + ($pulse * 2)
                $g.FillEllipse($brush, $sx - $size/2, $sy - $size/2, $size, $size)
            }
            $brush.Dispose()
            
            # Leaves
            $leafCount = [math]::Max(1,[math]::Min(10, [math]::Round(1 + $vine.Growth * 9)))
            $leafBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Green)
            for ($l=0; $l -lt $leafCount; $l++) {
                $leaf = $vine.Leaves[$l]
                $lx = $x + $leaf.OffsetX
                $ly = $trellisY - ($leaf.OffsetY * ($stemHeight / 120.0))
                $g.FillEllipse($leafBrush, $lx, $ly, $leaf.Width, $leaf.Height)
            }
            $leafBrush.Dispose()
            
            # Grapes
            $grapeCount = [math]::Max(0,[math]::Min(15, [math]::Round(($vine.Growth * 15) - 2)))
            for ($gidx=0; $gidx -lt $grapeCount; $gidx++) {
                $grape = $vine.Grapes[$gidx]
                $gx = $x + $grape.OffsetX
                $gy = $trellisY - $grape.OffsetY
                $r = $grape.Radius
                $g.FillEllipse($vine.Color, $gx, $gy, $r*2, $r*2)
            }
            
            # Label
            $labelText = "$($vine.Name): {0:P0}" -f $vine.Growth
            $labelFont = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
            $g.DrawString($labelText, $labelFont, $labelBrush, $x+10, $trellisY+10)
            $labelFont.Dispose()
            $labelBrush.Dispose()
        }
        
        # Season display
        $seasonText = switch ($this.State.Season) {0{"✨ Spring"} 1{"✨ Summer"} 2{"✨ Harvest"} default{"?"}}
        $seasonFont = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $seasonBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        $g.DrawString("Season: $seasonText", $seasonFont, $seasonBrush, $width-160, 6)
        $seasonFont.Dispose()
        $seasonBrush.Dispose()
    }
    
    hidden [void] UpdateVineyard() {
        # Cloud/Sun movement
        $this.State.CloudX = ($this.State.CloudX + 4) % 10000
        $this.State.SunX = ($this.State.SunX + 2) % 10000
        
        # Season change
        if ($this.TickCount % 50 -eq 0) {
            if ((Get-Random -Minimum 0 -Maximum 100) -lt 10) {
                $this.State.Season = ($this.State.Season + 1) % 3
            }
        }
        
        # Weather change
        if ($this.TickCount % 5 -eq 0) {
            $r = Get-Random -Minimum 0 -Maximum 100
            $this.State.Weather = if ($r -lt 60) { "☀️" } elseif ($r -lt 85) { "⛅" } else { "🌧️" }
            if ($this.WeatherLabel) {
                $this.WeatherLabel.Text = "Weather: $($this.State.Weather)"
            }
        }
        
        # Growth calculation
        $weatherFactor = switch ($this.State.Weather) {
            "☀️" { 1.05 }
            "⛅" { 1.02 }
            "🌧️" { 0.95 }
            default { 1.0 }
        }
        $seasonFactor = switch ($this.State.Season) {
            0 { 0.02 }
            1 { 0.04 }
            2 { -0.03 }
            default { 0 }
        }
        
        foreach ($vine in $this.VineProducts) {
            $delta = (((Get-Random -Minimum 0 -Maximum 13) - 5) / 100.0) * $seasonFactor * 10
            $newGrowth = $vine.Growth + ($delta * $weatherFactor)
            $vine.Growth = [math]::Max(0, [math]::Min(1, $newGrowth))
        }
    }
}

# ============================================
# Legacy Compatibility
# ============================================
function Stop-Show17 {
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show17")) {
        $Global:ShowManager.Shows["show17"].Stop()
    }
}

Write-Host "✅ HQshow17 class loaded (v3) - Vineyard Growth" -ForegroundColor Green

