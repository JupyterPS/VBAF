# ==============================================
# Show33 - Novo Nordisk Global Impact (BaseShow)
# ==============================================

class ImpactParticle {
    [float]$X; [float]$Y
    [float]$DX; [float]$DY
    [int]$Life
    [System.Drawing.Color]$Color
    [int]$Size

    ImpactParticle([float]$x,[float]$y,[float]$dx,[float]$dy,[System.Drawing.Color]$color,[int]$size) {
        $this.X = $x; $this.Y = $y; $this.DX = $dx; $this.DY = $dy
        $this.Color = $color; $this.Size = $size
        $this.Life = Get-Random -Minimum 40 -Maximum 100
    }

    [void] Move() {
        $this.X += $this.DX
        $this.Y += $this.DY
        $this.Life--
    }

    [bool] IsAlive() { return ($this.Life -gt 0) }
}

class Show33 : BaseShow {
    hidden [System.Collections.ArrayList] $Particles = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $BaseRegions = [System.Collections.ArrayList]::new()
    hidden [System.Windows.Forms.Label] $TickerLabel
    hidden [int] $TickerIndex = 0
    hidden [int] $TickerTickCount = 0      # <<< NEW: controls ticker speed
    hidden [float] $DriftAngle = 0
    hidden [float] $DriftSpeed = 0.025
    hidden [float] $DriftAmplitude = 100
    hidden [System.Collections.ArrayList] $CachedRegions = [System.Collections.ArrayList]::new()
    
    hidden [string[]] $Messages = @(
        "Novo Nordisk: Changing lives through innovation",
        "Every light on this map represents human impact", 
        "Science that reaches people, not just numbers",
        "Partnership, care, and progress across continents",
        "✨ The Human Impact of Novo Nordisk"
    )

    Show33([System.Windows.Forms.Panel]$panel) : base("show33", $panel) {
        $this.InitializeRegions()
    }

    [void] OnStart() {
        Write-Host "🌍 [Show33] Novo Nordisk Global Impact initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 25)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Create ticker label
        $this.TickerLabel = New-Object System.Windows.Forms.Label
        $this.TickerLabel.AutoSize = $false
        $this.TickerLabel.Width = 800
        $this.TickerLabel.Height = 28
        $this.TickerLabel.ForeColor = [System.Drawing.Color]::White
        $this.TickerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $this.TickerLabel.BackColor = [System.Drawing.Color]::Transparent
        $this.TickerLabel.Location = New-Object System.Drawing.Point(16, 16)
        $this.TickerLabel.Text = $this.Messages[0]
        $this.Panel.Controls.Add($this.TickerLabel)
        
        # Ticker messages integration
        $global:messages = $this.Messages
        if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
        
        $this.SetupPaintEvent()
        $this.SetupVisibleChanged()
        
        Write-Host "✅ [Show33] Global Impact ready!" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $width = $this.Panel.Width
        $height = $this.Panel.Height
        if ($width -le 0 -or $height -le 0) { return }
        
        # Drift update
        $this.DriftAngle += $this.DriftSpeed
        $shiftX = [math]::Sin($this.DriftAngle) * $this.DriftAmplitude
        $this.CachedRegions.Clear()
        
        foreach ($region in $this.BaseRegions) {
            [void]$this.CachedRegions.Add(@{
                X = $region.X + $shiftX
                Y = $region.Y
                Label = $region.Label
            })
        }
        
        # Emit new particles (cap 40)
        if ($this.Particles.Count -lt 40) {
            $region = $this.CachedRegions | Get-Random
            $dx = ((Get-Random -Minimum -10 -Maximum 10) / 50.0)
            $dy = ((Get-Random -Minimum -10 -Maximum 10) / 50.0)
            $color = [System.Drawing.Color]::FromArgb(200, 100+(Get-Random -Minimum 0 -Maximum 155), 180, 255)
            [void]$this.Particles.Add([ImpactParticle]::new($region.X, $region.Y, $dx, $dy, $color, 6))
        }
        
        # Update particles
        $alive = [System.Collections.ArrayList]::new()
        foreach ($particle in $this.Particles) {
            $particle.Move()
            if ($particle.IsAlive()) { [void]$alive.Add($particle) }
        }
        $this.Particles.Clear()
        foreach ($p in $alive) { [void]$this.Particles.Add($p) }
        
        # Update ticker (slower)
        $this.TickerTickCount++
        # Change message every 60 updates (adjust 60 for slower/faster)
        if ($this.TickerTickCount -ge 60) {
            $this.TickerTickCount = 0
            $this.TickerIndex++
            if ($this.TickerIndex -ge $this.Messages.Count) { $this.TickerIndex = 0 }
            $this.TickerLabel.Text = $this.Messages[$this.TickerIndex]
        }
        
        # GC every 200 ticks
        if ($this.TickCount % 200 -eq 0) { 
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
        }
        
        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "🛑 [Show33] Global Impact cleanup..." -ForegroundColor Yellow
        
        $this.Particles.Clear()
        $this.CachedRegions.Clear()
        if ($this.TickerLabel) {
            $this.Panel.Controls.Remove($this.TickerLabel)
            $this.TickerLabel.Dispose()
            $this.TickerLabel = $null
        }
        
        Write-Host "✔️ [Show33] Cleanup complete!" -ForegroundColor Green
    }

    hidden [void] InitializeRegions() {
        $regions = @(
            @{ X = 140; Y = 240; Label = "North America" },
            @{ X = 190; Y = 290; Label = "South America" },
            @{ X = 250; Y = 210; Label = "Europe" },
            @{ X = 300; Y = 230; Label = "Africa" },
            @{ X = 360; Y = 200; Label = "Middle East" },
            @{ X = 400; Y = 180; Label = "Asia" },
            @{ X = 440; Y = 260; Label = "Australia" }
        )
        foreach ($region in $regions) {
            [void]$this.BaseRegions.Add($region)
        }
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            try {
                $g = $e.Graphics
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $width = $s.Width
                $height = $s.Height
                if ($width -le 0 -or $height -le 0) { return }

                # Background gradient
                $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                    (New-Object System.Drawing.Point(0,0)),
                    (New-Object System.Drawing.Point(0,$height)),
                    [System.Drawing.Color]::FromArgb(10,15,25),
                    [System.Drawing.Color]::FromArgb(25,35,55)
                )
                $g.FillRectangle($bgBrush, 0, 0, $width, $height)
                $bgBrush.Dispose()

                # Draw regions
                $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40,120,200), 2)
                foreach ($region in $self.CachedRegions) {
                    $g.DrawEllipse($pen, $region.X-25, $region.Y-15, 50, 30)
                }
                $pen.Dispose()

                # Draw particles
                foreach ($p in $self.Particles) {
                    if ($p.IsAlive()) {
                        $alpha = [int](255 * ($p.Life / 100.0))
                        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, $p.Color.R, $p.Color.G, $p.Color.B))
                        $g.FillEllipse($brush, [int]$p.X, [int]$p.Y, $p.Size, $p.Size)
                        $brush.Dispose()
                    }
                }

                # Draw labels
                foreach ($region in $self.CachedRegions) {
                    $fnt = New-Object System.Drawing.Font("Segoe UI", 9)
                    $txtBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180,220,235,255))
                    $g.DrawString($region.Label, $fnt, $txtBrush, $region.X+30, $region.Y-5)
                    $txtBrush.Dispose(); $fnt.Dispose()
                }

                # Title
                $titleFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
                $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,230,240,255))
                $title = "✨ Novo Nordisk Global Reach"
                $tw = $g.MeasureString($title, $titleFont).Width
                $g.DrawString($title, $titleFont, $titleBrush, ($width/2 - $tw/2), $height - 50)
                $titleBrush.Dispose(); $titleFont.Dispose()
            }
            catch {
                # Silent fail in paint
            }
        }.GetNewClosure())
    }

    hidden [void] SetupVisibleChanged() {
        $self = $this
        $this.Panel.Add_VisibleChanged({
            param($s, $e)
            if (-not $self.Panel.Visible) {
                $self.Particles.Clear()
                [GC]::Collect()
            }
        }.GetNewClosure())
    }
}

# Legacy compatibility
function Stop-Show33 {
    Write-Host "🛑 [Show33] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show33")) {
        $Global:ShowManager.Shows["show33"].Stop()
    }
}

Write-Host "✅ COMPLETE Show33 - Novo Nordisk Global Impact (BaseShow)" -ForegroundColor Green


