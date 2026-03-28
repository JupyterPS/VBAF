# ==============================================
# Show32 - Novo Nordisk Pulse (BaseShow)
# ==============================================

class KPIOrb {
    [float] $X; [float] $Y; [float] $DX; [float] $DY
    [System.Drawing.Color] $Color; [int] $Radius
    [System.Collections.ArrayList] $Trail

    KPIOrb([float]$x,[float]$y,[float]$dx,[float]$dy,[System.Drawing.Color]$color,[int]$radius) {
        $this.X = $x; $this.Y = $y; $this.DX = $dx; $this.DY = $dy
        $this.Color = $color; $this.Radius = $radius
        $this.Trail = [System.Collections.ArrayList]::new()
    }

    [void] Move([int]$width,[int]$height) {
        $this.Trail.Add(@{X=$this.X;Y=$this.Y}) | Out-Null
        if ($this.Trail.Count -gt 10) { $this.Trail.RemoveAt(0) }
        $this.X += $this.DX; $this.Y += $this.DY
        if ($this.X -lt $this.Radius -or $this.X -gt $width - $this.Radius) { $this.DX = -$this.DX }
        if ($this.Y -lt $this.Radius -or $this.Y -gt $height - $this.Radius) { $this.DY = -$this.DY }
    }
}

class Show32 : BaseShow {
    hidden [System.Collections.ArrayList] $KPIorbs = [System.Collections.ArrayList]::new()

    Show32([System.Windows.Forms.Panel]$panel) : base("show32", $panel) { }

    [void] OnStart() {
        Write-Host "🌊 [Show32] Novo Nordisk Pulse initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::Black
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Ticker messages
        $Show32Messages = @(
            "NOVO NORDISK PULSE - Innovative Cure 2030",
            "KPI Orbs - Bouncing analytics visualization",
            "Click to spawn new metrics tracker",
            "Real-time data flow simulation",
            "Pharmaceutical innovation dashboard"
        )
        $global:messages = $Show32Messages
        if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
        
        $this.SetupPaintEvent()
        $this.SetupMouseClick()
        $this.SetupVisibleChanged()
        
        Write-Host "✅ [Show32] Novo Nordisk Pulse ready!" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $w = $this.Panel.Width
        $h = $this.Panel.Height
        if ($w -le 0 -or $h -le 0) { return }
        
        # Auto-spawn orbs (limit 8)
        if ($this.KPIorbs.Count -lt 8) {
            $colors = @(
                [System.Drawing.Color]::Red, [System.Drawing.Color]::Green, [System.Drawing.Color]::Blue,
                [System.Drawing.Color]::Yellow, [System.Drawing.Color]::Magenta, [System.Drawing.Color]::Cyan
            )
            $color = $colors | Get-Random
            $x = Get-Random -Minimum 50 -Maximum ($w-50)
            $y = Get-Random -Minimum 50 -Maximum ($h-50)
            $dx = (Get-Random -Minimum -5 -Maximum 5); if ($dx -eq 0) { $dx = 2 }
            $dy = (Get-Random -Minimum -5 -Maximum 5); if ($dy -eq 0) { $dy = 2 }
            [void]$this.KPIorbs.Add([KPIOrb]::new($x, $y, $dx, $dy, $color, 20))
        }
        
        # Update all orbs
        foreach ($orb in $this.KPIorbs) {
            $orb.Move($w, $h)
        }
        
        # GC every 200 ticks
        if ($this.TickCount % 200 -eq 0) { [GC]::Collect() }
        
        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "🧹 [Show32] Novo Nordisk Pulse cleanup..." -ForegroundColor Yellow
        
        $this.KPIorbs.Clear()
        $this.Panel.Controls.Clear()
        
        Write-Host "✔️ [Show32] Cleanup complete!" -ForegroundColor Green
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $width = $s.Width; $height = $s.Height
            if ($width -le 0 -or $height -le 0) { return }
            $g.Clear([System.Drawing.Color]::Black)

            # Draw orb trails and orbs
            foreach ($orb in $self.KPIorbs) {
                # Trails
                for ($i = 1; $i -lt $orb.Trail.Count; $i++) {
                    $p1 = $orb.Trail[$i-1]; $p2 = $orb.Trail[$i]
                    $alpha = [int](150 * ($i / $orb.Trail.Count))
                    $pen = New-Object System.Drawing.Pen(
                        [System.Drawing.Color]::FromArgb($alpha, $orb.Color.R, $orb.Color.G, $orb.Color.B), 2)
                    $g.DrawLine($pen, [int]$p1.X, [int]$p1.Y, [int]$p2.X, [int]$p2.Y)
                    $pen.Dispose()
                }
                
                # Orb
                $brush = New-Object System.Drawing.SolidBrush($orb.Color)
                $g.FillEllipse($brush, [int]($orb.X-$orb.Radius), [int]($orb.Y-$orb.Radius),
                               $orb.Radius*2, $orb.Radius*2)
                $brush.Dispose()
            }

            # Title
            $text = "✨ INNOVATIVE CURE 2030"
            $font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $sz = $g.MeasureString($text, $font)
            $g.DrawString($text, $font, $brush, ($width-$sz.Width)/2, 20)
            $brush.Dispose(); $font.Dispose()
        }.GetNewClosure())
    }

    hidden [void] SetupMouseClick() {
        $self = $this
        $this.Panel.Add_MouseClick({
            param($sender, $e)
            if ($self.KPIorbs.Count -ge 10) { return }
            $colors = @(
                [System.Drawing.Color]::Red, [System.Drawing.Color]::Green, [System.Drawing.Color]::Blue,
                [System.Drawing.Color]::Yellow, [System.Drawing.Color]::Magenta, [System.Drawing.Color]::Cyan
            )
            $color = $colors | Get-Random
            $dx = (Get-Random -Minimum -5 -Maximum 5); if ($dx -eq 0) { $dx = 2 }
            $dy = (Get-Random -Minimum -5 -Maximum 5); if ($dy -eq 0) { $dy = 2 }
            [void]$self.KPIorbs.Add([KPIOrb]::new($e.X, $e.Y, $dx, $dy, $color, 20))
        }.GetNewClosure())
    }

    hidden [void] SetupVisibleChanged() {
        $self = $this
        $this.Panel.Add_VisibleChanged({
            param($s, $e)
            if (-not $self.Panel.Visible) {
                $self.KPIorbs.Clear()
                [GC]::Collect()
            }
        }.GetNewClosure())
    }
}

# Legacy compatibility
function Stop-Show32 {
    Write-Host "🛑 [Show32] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show32")) {
        $Global:ShowManager.Shows["show32"].Stop()
    }
}

Write-Host "✅ COMPLETE Show32 - Novo Nordisk Pulse (BaseShow)" -ForegroundColor Green
Write-Host "🌊 TreeView → Show32 → Click to spawn KPI orbs! ✨" -ForegroundColor Cyan

