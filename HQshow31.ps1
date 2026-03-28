# ============================================
# HQshow31.ps1 - Novo Nordisk Company Show
# ============================================
Write-Host "`n=> _____ HQshow31 (Novo Nordisk) ___________ <=`n" -ForegroundColor Cyan

class Show31 : BaseShow {
    # ========================================
    # Private Properties
    # ========================================
    hidden [System.Collections.ArrayList] $Particles = [System.Collections.ArrayList]::new()   # soft background particles
    hidden [System.Collections.ArrayList] $Rockets   = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $ExplosionParticles = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $FinalLetters = [System.Collections.ArrayList]::new()

    hidden [string[]] $Letters = @("N","o","v","o"," ","N","o","r","d","i","s","k")
    hidden [int]   $LetterIndex = 0
    hidden [int]   $LetterTickCounter = 0
    hidden [int]   $FrameCount = 0
    hidden [int]   $TickCount  = 0

    hidden [System.Drawing.Bitmap]   $Buffer = $null
    hidden [System.Drawing.Graphics] $BufferGraphics = $null

    # ========================================
    # Constructor
    # ========================================
    Show31([System.Windows.Forms.Panel]$panel) : base("show31", $panel) {
        # constructor body can stay empty; initialization is in OnStart()
    }

    # ========================================
    # Lifecycle Methods
    # ========================================

    [void] OnStart() {
        Write-Host "  🧬 [Show31] Initializing Novo Nordisk visualization..." -ForegroundColor Cyan

        if ($this.Panel.Width -le 0 -or $this.Panel.Height -le 0) {
            Write-Host "  ⚠️ Panel has no size! Width=$($this.Panel.Width), Height=$($this.Panel.Height)" -ForegroundColor Red
            Write-Host "  🔧 Forcing default panel size 650x410..." -ForegroundColor Yellow
            $this.Panel.Size = New-Object System.Drawing.Size(650, 410)
        }

        Write-Host "  📐 Panel size: $($this.Panel.Width) x $($this.Panel.Height)" -ForegroundColor DarkCyan

        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 20, 30)

        # Double buffering on the panel itself (extra safety)
        $prop = $this.Panel.GetType().GetProperty(
            "DoubleBuffered",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }

        # Simple mouse‑click rocket launcher
        $self = $this
        $this.Panel.Add_MouseClick({
            param($sender, $e)
            $self.LaunchMouseRocket($e.X, $e.Y)
        }.GetNewClosure())

        # Company metrics and static UI
       # $metrics = $this.GetCompanyMetrics()
       # $this.CreateHeader($metrics)
       # $this.CreateMetricsDisplay($metrics)

        # Reset dynamic state
        $this.Particles.Clear()
        $this.Rockets.Clear()
        $this.ExplosionParticles.Clear()
        $this.FinalLetters.Clear()
        $this.LetterIndex = 0
        $this.LetterTickCounter = 0
        $this.FrameCount = 0
        $this.TickCount  = 0

        # Initialize background particles
        $this.InitializeParticles()

        # Create off‑screen buffer
        if ($this.Panel.Width -gt 0 -and $this.Panel.Height -gt 0) {
            $this.Buffer = New-Object System.Drawing.Bitmap($this.Panel.Width, $this.Panel.Height)
            $this.BufferGraphics = [System.Drawing.Graphics]::FromImage($this.Buffer)
            $this.BufferGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            Write-Host "  🎨 Buffer created: $($this.Panel.Width)x$($this.Panel.Height)" -ForegroundColor DarkCyan
        } else {
            Write-Host "  ❌ Cannot create buffer - panel has no size!" -ForegroundColor Red
        }

        Write-Host "  ✅ [Show31] Novo Nordisk + Rockets ready" -ForegroundColor Green
    }

    [void] OnStop() {
        Write-Host "  🛑 [Show31] Cleaning up..." -ForegroundColor Yellow

        if ($this.BufferGraphics) {
            $this.BufferGraphics.Dispose()
            $this.BufferGraphics = $null
        }
        if ($this.Buffer) {
            $this.Buffer.Dispose()
            $this.Buffer = $null
        }

        $this.Particles.Clear()
        $this.Rockets.Clear()
        $this.ExplosionParticles.Clear()
        $this.FinalLetters.Clear()

        try {
            $this.Panel.Remove_MouseClick($null)
        } catch {}

        $this.Panel.Controls.Clear()

        Write-Host "  ✅ [Show31] Cleanup complete" -ForegroundColor Green
    }

    [void] OnUpdate() {
        if (-not $this.Buffer -or -not $this.BufferGraphics) {
            if ($this.Panel.Width -gt 0 -and $this.Panel.Height -gt 0) {
                $this.Buffer = New-Object System.Drawing.Bitmap($this.Panel.Width, $this.Panel.Height)
                $this.BufferGraphics = [System.Drawing.Graphics]::FromImage($this.Buffer)
                $this.BufferGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                Write-Host "  🔧 Buffer recreated in Update()" -ForegroundColor Yellow
            } else {
                return
            }
        }

        $this.FrameCount++
        $this.TickCount++

        if ($this.FrameCount % 60 -eq 0) {
            Write-Host "  🎬 Frame $($this.FrameCount): Part=$($this.Particles.Count), Rockets=$($this.Rockets.Count), Explosions=$($this.ExplosionParticles.Count), Letters=$($this.FinalLetters.Count)" -ForegroundColor DarkGray
        }

        # 1) Update soft background particles
        foreach ($particle in $this.Particles) {
            if (-not $particle) { continue }
            $particle.X += $particle.VX
            $particle.Y += $particle.VY

            if ($particle.X -lt 0 -or $particle.X -gt $this.Panel.Width) {
                $particle.VX *= -1
            }
            if ($particle.Y -lt 0 -or $particle.Y -gt $this.Panel.Height) {
                $particle.VY *= -1
            }
        }

        # 2) Update rockets and explosions
        $this.UpdateRocketsAndExplosions()

        # 3) Update letter sequence
        $this.UpdateLetters()

        # 4) Render the full frame
        $this.RenderFrame()
    }

    # ========================================
    # Static UI
    # ========================================

    hidden [hashtable] GetCompanyMetrics() {
        # Simple inline metrics; replace with domain model lookup if you have one
        return @{
            Name          = "Novo Nordisk"
            Location      = "Bagsværd, Denmark"
            EmployeeCount = "~63,000"
            CustomerCount = "Global healthcare partners"
        }
    }

    hidden [void] CreateHeader([hashtable]$metrics) {
        $header = New-Object System.Windows.Forms.Label
        $header.Text = "$($metrics.Name)"
        $header.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $header.ForeColor = [System.Drawing.Color]::White
        $header.BackColor = [System.Drawing.Color]::Transparent
        $header.AutoSize = $true
        $header.Location = New-Object System.Drawing.Point(20, 20)
        $this.Panel.Controls.Add($header)
    }

    hidden [void] CreateMetricsDisplay([hashtable]$metrics) {
        $metricsLabel = New-Object System.Windows.Forms.Label
        $metricsLabel.Text = @"
📍 Location: $($metrics.Location)
👥 Employees: $($metrics.EmployeeCount)
🤝 Customers: $($metrics.CustomerCount)
"@
        $metricsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
        $metricsLabel.ForeColor = [System.Drawing.Color]::LightGray
        $metricsLabel.BackColor = [System.Drawing.Color]::Transparent
        $metricsLabel.AutoSize = $true
        $metricsLabel.Location = New-Object System.Drawing.Point(20, 60)
        $this.Panel.Controls.Add($metricsLabel)
    }

    # ========================================
    # Background Particles
    # ========================================

    hidden [void] InitializeParticles() {
        $random = New-Object System.Random
        $this.Particles.Clear()

        for ($i = 0; $i -lt 50; $i++) {
            $particle = @{
                X     = $random.Next(0, [Math]::Max(1, $this.Panel.Width))
                Y     = $random.Next(0, [Math]::Max(1, $this.Panel.Height))
                VX    = $random.Next(-2, 3)
                VY    = $random.Next(-2, 3)
                Size  = $random.Next(3, 8)
                Color = [System.Drawing.Color]::FromArgb(
                    $random.Next(100, 255),
                    100,
                    200,
                    255
                )
            }
            $this.Particles.Add($particle) | Out-Null
        }

        Write-Host "  🎨 [Show31] Created $($this.Particles.Count) background particles" -ForegroundColor DarkCyan
    }

    # ========================================
    # Rockets & Explosions (adapted from old Show31)
    # ========================================

    hidden [void] LaunchMouseRocket([int]$targetX, [int]$targetY) {
        if ($this.Rockets.Count -ge 5) { return }

        $startY = $this.Panel.Height - 10
        $dx = [int](($targetX - ($this.Panel.Width / 2)) / 40)
        $dy = - (Get-Random -Minimum 7 -Maximum 12)
        $color = [System.Drawing.Color]::FromArgb(
            255,
            (Get-Random -Minimum 100 -Maximum 255),
            (Get-Random -Minimum 100 -Maximum 255),
            (Get-Random -Minimum 100 -Maximum 255)
        )

        $rocket = @{
            X        = [float]($this.Panel.Width / 2)
            Y        = [float]$startY
            DX       = [float]$dx
            DY       = [float]$dy
            Color    = $color
            Life     = Get-Random -Minimum 30 -Maximum 60
            Exploded = $false
            Trail    = New-Object System.Collections.ArrayList
            Letter   = $null
            IsLetter = $false
        }
        $this.Rockets.Add($rocket) | Out-Null
    }

    hidden [void] LaunchLetterRocket([string]$letter, [int]$index) {
        $w = $this.Panel.Width
        $h = $this.Panel.Height

        $x = ($w / ($this.Letters.Length + 1)) * ($index + 1)
        $y = $h - 10
        $dy = - (Get-Random -Minimum 7 -Maximum 10)
        $color = [System.Drawing.Color]::FromArgb(
            255,
            (Get-Random -Minimum 100 -Maximum 255),
            (Get-Random -Minimum 100 -Maximum 255),
            (Get-Random -Minimum 100 -Maximum 255)
        )

        $rocket = @{
            X        = [float]$x
            Y        = [float]$y
            DX       = 0.0
            DY       = [float]$dy
            Color    = $color
            Life     = Get-Random -Minimum 30 -Maximum 60
            Exploded = $false
            Trail    = New-Object System.Collections.ArrayList
            Letter   = $letter
            IsLetter = $true
        }
        $this.Rockets.Add($rocket) | Out-Null
    }

    hidden [void] UpdateRocketsAndExplosions() {
        $newRockets = New-Object System.Collections.ArrayList

        foreach ($r in $this.Rockets) {
            if (-not $r) { continue }

            # Move rocket & add trail
            $null = $r.Trail.Add(@{ X = $r.X; Y = $r.Y })
            if ($r.Trail.Count -gt 8) { $r.Trail.RemoveAt(0) }

            $r.DY += 0.2
            $r.X  += $r.DX
            $r.Y  += $r.DY
            $r.Life--

            $alive = ($r.Life -gt 0) -and (-not $r.Exploded)

            if ($alive) {
                $null = $newRockets.Add($r)
            } else {
                if (-not $r.Exploded) {
                    $r.Exploded = $true
                    if ($r.IsLetter -and $r.Letter -ne " ") {
                        # Add final letter sprite
                        $letterEntry = @{
                            Letter = $r.Letter
                            X      = $r.X - 10
                            Y      = 20
                            Color  = $r.Color
                            Alpha  = 0
                        }
                        $this.FinalLetters.Add($letterEntry) | Out-Null
                    } else {
                        # Regular explosion -> particles
                        $count = Get-Random -Minimum 6 -Maximum 8
                        for ($i = 0; $i -lt $count; $i++) {
                            $angle = 2 * [Math]::PI * ($i / $count)
                            $speed = Get-Random -Minimum 2 -Maximum 6
                            $dx = [Math]::Cos($angle) * $speed
                            $dy = [Math]::Sin($angle) * $speed
                            $size = Get-Random -Minimum 2 -Maximum 5
                            $colorPart = [System.Drawing.Color]::FromArgb(
                                255,
                                (Get-Random -Minimum 100 -Maximum 255),
                                (Get-Random -Minimum 100 -Maximum 255),
                                (Get-Random -Minimum 100 -Maximum 255)
                            )
                            $p = @{
                                X          = [float]$r.X
                                Y          = [float]$r.Y
                                DX         = [float]$dx
                                DY         = [float]$dy
                                Life       = Get-Random -Minimum 20 -Maximum 50
                                InitialLife = $null
                                Color      = $colorPart
                                Size       = $size
                            }
                            $p.InitialLife = $p.Life
                            $this.ExplosionParticles.Add($p) | Out-Null
                        }
                    }
                }
            }
        }

        $this.Rockets = $newRockets

        # Update explosion particles with fade
        $newExplosions = New-Object System.Collections.ArrayList
        foreach ($p in $this.ExplosionParticles) {
            if (-not $p) { continue }
            $p.DY += 0.3
            $p.DX += (((Get-Random -Minimum 0 -Maximum 100)/1000.0) - 0.05)
            $p.X  += $p.DX
            $p.Y  += $p.DY
            $p.Life--

            if ($p.Life -gt 0) {
                $null = $newExplosions.Add($p)
            }
        }
        $this.ExplosionParticles = $newExplosions

        if ($this.ExplosionParticles.Count -gt 50) {
            $this.ExplosionParticles = [System.Collections.ArrayList](@($this.ExplosionParticles | Select-Object -Last 50))
        }
    }

    hidden [System.Drawing.Color] GetFadedColor($p) {
        $alpha = [int](255 * ($p.Life / [double]$p.InitialLife))
        if ($alpha -lt 0) { $alpha = 0 }
        return [System.Drawing.Color]::FromArgb($alpha, $p.Color.R, $p.Color.G, $p.Color.B)
    }

    # ========================================
    # Letter sequence
    # ========================================

    hidden [void] UpdateLetters() {
        # Launch next letter roughly every 25 ticks
        if ($this.LetterIndex -lt $this.Letters.Length) {
            $this.LetterTickCounter++
            if ($this.LetterTickCounter -ge 25) {
                $this.LetterTickCounter = 0
                $letter = $this.Letters[$this.LetterIndex]
                if ($letter -ne " ") {
                    $this.LaunchLetterRocket($letter, $this.LetterIndex)
                }
                $this.LetterIndex++
            }
        }

        # Fade‑in and slight motion for final letters
        foreach ($fl in $this.FinalLetters) {
            if (-not $fl) { continue }
            if ($fl.Alpha -lt 255) { $fl.Alpha += 5 }
        }
    }

    # ========================================
    # Rendering
    # ========================================

    hidden [void] RenderFrame() {
        if (-not $this.BufferGraphics -or -not $this.Buffer) {
            return
        }

        $g = $this.BufferGraphics
        $w = $this.Panel.Width
        $h = $this.Panel.Height

        $g.Clear($this.Panel.BackColor)

        # Background particles
        foreach ($particle in $this.Particles) {
            if ($particle -and $particle.Color) {
                $brush = New-Object System.Drawing.SolidBrush($particle.Color)
                $g.FillEllipse(
                    $brush,
                    [float]$particle.X,
                    [float]$particle.Y,
                    [float]$particle.Size,
                    [float]$particle.Size
                )
                $brush.Dispose()
            }
        }

        # Rocket trails and bodies
        foreach ($r in $this.Rockets) {
            if (-not $r) { continue }

            # Trail lines
            for ($i = 1; $i -lt $r.Trail.Count; $i++) {
                $p1 = $r.Trail[$i-1]
                $p2 = $r.Trail[$i]
                $alpha = [int](100 * ($i / [double]$r.Trail.Count))
                $tailColor = [System.Drawing.Color]::FromArgb($alpha, $r.Color.R, $r.Color.G, $r.Color.B)
                $pen = New-Object System.Drawing.Pen($tailColor, 2)
                $g.DrawLine($pen, [int]$p1.X, [int]$p1.Y, [int]$p2.X, [int]$p2.Y)
                $pen.Dispose()
            }

            # Core line
            $penR = New-Object System.Drawing.Pen($r.Color, 2)
            $g.DrawLine(
                $penR,
                [int]$r.X, [int]$r.Y,
                [int]($r.X - $r.DX), [int]($r.Y - $r.DY)
            )
            $penR.Dispose()
        }

        # Explosion particles
        foreach ($p in $this.ExplosionParticles) {
            if (-not $p) { continue }
            $brush = New-Object System.Drawing.SolidBrush($this.GetFadedColor($p))
            $g.FillEllipse($brush, [int]$p.X, [int]$p.Y, $p.Size, $p.Size)
            $brush.Dispose()
        }

        # Final letters
        foreach ($fl in $this.FinalLetters) {
            if (-not $fl) { continue }

            $alpha = $fl.Alpha
            if ($alpha -gt 255) { $alpha = 255 }

            $angleX = [Math]::Sin(($this.TickCount / 200.0) + ($fl.X)) * 6
            $drawX = $fl.X + $angleX

            $colorWithAlpha = [System.Drawing.Color]::FromArgb(
                $alpha,
                $fl.Color.R,
                $fl.Color.G,
                $fl.Color.B
            )
            $brush = New-Object System.Drawing.SolidBrush($colorWithAlpha)
            $font  = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
            $g.DrawString($fl.Letter, $font, $brush, [int]$drawX, [int]$fl.Y)
            $brush.Dispose()
            $font.Dispose()
        }

        # Swap buffer into panel
        $oldImage = $this.Panel.BackgroundImage
        $this.Panel.BackgroundImage = $this.Buffer.Clone()
        if ($oldImage) { $oldImage.Dispose() }
    }

    # Legacy method (kept for compatibility)
    hidden [void] RenderParticles([System.Drawing.Graphics]$graphics) {
        # not used with buffer approach
    }
}

function Stop-Show31 {
    Write-Host "🛑 [Show31] Stopping Novo Nordisk show..." -ForegroundColor Yellow

    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("Show31")) {
        $show = $Global:ShowManager.Shows["Show31"]
        $show.Stop()
    }

    Write-Host "✅ [Show31] Stopped and cleaned" -ForegroundColor Green
}

Write-Host "✅ HQshow31 class loaded" -ForegroundColor Green

