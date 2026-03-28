# ==============================================
# Show14 - Terroir Canvas (GM3, Wine Company)
# ==============================================

Write-Host "`n=> _____ HQshow14 (Terroir Canvas, GM3) ___________ <=`n" -ForegroundColor Cyan

class Show14 : BaseShow {
    hidden [System.Collections.ArrayList] $Regions
    hidden [System.Collections.ArrayList] $Particles
    hidden [hashtable] $State

    Show14([System.Windows.Forms.Panel]$panel) : base("show14", $panel) {
        $this.Regions   = [System.Collections.ArrayList]::new()
        $this.Particles = [System.Collections.ArrayList]::new()
        $this.State = @{
            TickCount      = 0
            HighlightIndex = -1
            Wind           = 0
        }
        $this.InitializeRegions()
    }

    [void] OnStart() {
        Write-Host "  🍷 [Show14] Terroir Canvas initializing..." -ForegroundColor Magenta

        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(15, 10, 20)

        # Double buffering
        $prop = $this.Panel.GetType().GetProperty(
            "DoubleBuffered",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }

        $Global:messages = @(
            "🌍 Terroir Canvas - Where the land writes the wine",
            "🪨 Soil, climate, and elevation shape every glass",
            "🌬️ Cool slopes favor fresh acidity and fine aromatics",
            "☀️ Warm valleys give ripe fruit and generous body"
        )

        $this.SetupEvents()

        Write-Host "  ✅ [Show14] Terroir Canvas ready (GM3)!" -ForegroundColor Green
    }

    [void] OnUpdate() {
        if (-not $this.Panel.Visible -or $this.Panel.Width -le 0 -or $this.Panel.Height -le 0) { return }

        $this.State.TickCount++

        # gentle wind for particle drift
        $this.State.Wind = [math]::Sin($this.State.TickCount * 0.02) * 0.3

        # update particles only every 2nd tick
        if ($this.State.TickCount % 2 -eq 0) {
            $this.UpdateParticles()
        }

        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "  🛑 [Show14] Terroir Canvas cleanup..." -ForegroundColor Yellow

        $this.Regions.Clear()
        $this.Particles.Clear()

        $this.Panel.Remove_Paint($null)
        $this.Panel.Remove_MouseClick($null)
        $this.Panel.Controls.Clear()

        $this.State.TickCount      = 0
        $this.State.HighlightIndex = -1

        Write-Host "  ✅ [Show14] Stopped (GM3)" -ForegroundColor Green
    }

    # ---------- INITIAL DATA ----------

    hidden [void] InitializeRegions() {
        $this.Regions.Clear()

        [void]$this.Regions.Add(@{
            Name   = "Cool Hillside"
            X      = 180
            Y      = 180
            Soil   = "Limestone, shale"
            Climate = "Cool nights, long ripening"
            Style  = "High acidity, fine aromatics"
            Color  = [System.Drawing.Color]::FromArgb(150, 180, 230)
        })
        [void]$this.Regions.Add(@{
            Name   = "River Valley"
            X      = 380
            Y      = 260
            Soil   = "Alluvial gravel"
            Climate = "Moderate, misty mornings"
            Style  = "Juicy fruit, silky texture"
            Color  = [System.Drawing.Color]::FromArgb(200, 170, 120)
        })
        [void]$this.Regions.Add(@{
            Name   = "High Plateau"
            X      = 580
            Y      = 180
            Soil   = "Rocky, low fertility"
            Climate = "Sunny days, cool nights"
            Style  = "Structured reds, deep color"
            Color  = [System.Drawing.Color]::FromArgb(170, 80, 90)
        })
        [void]$this.Regions.Add(@{
            Name   = "Coastal Breeze"
            X      = 260
            Y      = 340
            Soil   = "Sandy, well-drained"
            Climate = "Sea breeze, mild seasons"
            Style  = "Salt-tinged whites, bright and light"
            Color  = [System.Drawing.Color]::FromArgb(150, 210, 200)
        })
    }

    hidden [void] SetupEvents() {
        $self = $this

        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderCanvas($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())

        $this.Panel.Add_MouseClick({
            param($sender, $e)

            # find clicked region
            $index = -1
            for ($i = 0; $i -lt $self.Regions.Count; $i++) {
                $r = $self.Regions[$i]
                $dx = $e.X - $r.X
                $dy = $e.Y - $r.Y
                if (($dx*$dx + $dy*$dy) -lt 40*40) { $index = $i; break }
            }
            $self.State.HighlightIndex = $index

            if ($index -ge 0) {
                $region = $self.Regions[$index]
                for ($i = 0; $i -lt 20; $i++) {
                    [void]$self.Particles.Add(@{
                        X    = [double]$region.X
                        Y    = [double]$region.Y
                        VX   = (Get-Random -Minimum -10 -Maximum 10) / 20.0
                        VY   = (Get-Random -Minimum -10 -Maximum 10) / 20.0
                        Life = 50 + (Get-Random -Minimum 0 -Maximum 40)
                        Color = $region.Color
                        Size  = 2 + (Get-Random -Minimum 0 -Maximum 3)
                    })
                }
            }

            $self.Panel.Invalidate()
        }.GetNewClosure())
    }

    # ---------- UPDATE PARTICLES ----------

    hidden [void] UpdateParticles() {
        if ($this.Particles.Count -lt 40 -and $this.Regions.Count -gt 0) {
            $region = $this.Regions | Get-Random
            [void]$this.Particles.Add(@{
                X    = [double]$region.X
                Y    = [double]$region.Y
                VX   = (Get-Random -Minimum -5 -Maximum 5) / 30.0 + $this.State.Wind
                VY   = (Get-Random -Minimum -5 -Maximum 5) / 30.0
                Life = 80
                Color = $region.Color
                Size  = 2
            })
        }

        $alive = [System.Collections.ArrayList]::new()
        foreach ($p in $this.Particles) {
            $p.X   += $p.VX
            $p.Y   += $p.VY
            $p.Life -= 1
            if ($p.Life -gt 0) { [void]$alive.Add($p) }
        }
        $this.Particles = $alive
    }

    # ---------- RENDERING ----------

    hidden [void] RenderCanvas([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        if ($width -le 0 -or $height -le 0) { return }

        # background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0,0), [System.Drawing.Point]::new(0,$height),
            [System.Drawing.Color]::FromArgb(15, 10, 25),
            [System.Drawing.Color]::FromArgb(35, 20, 40)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()

        # contour lines
        $contourPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(50, 120, 100, 160), 1)
        for ($i = 0; $i -lt 6; $i++) {
            $y = 120 + $i * 50
            $g.DrawBezier(
                $contourPen,
                40,  $y,
                200, $y-20,
                500, $y+20,
                $width-40, $y
            )
        }
        $contourPen.Dispose()

        # connections
        $linkPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70, 200, 200, 220), 1)
        for ($i = 0; $i -lt $this.Regions.Count; $i++) {
            for ($j = $i+1; $j -lt $this.Regions.Count; $j++) {
                $r1 = $this.Regions[$i]
                $r2 = $this.Regions[$j]
                $g.DrawLine($linkPen, $r1.X, $r1.Y, $r2.X, $r2.Y)
            }
        }
        $linkPen.Dispose()

        # terroir circles
        for ($i = 0; $i -lt $this.Regions.Count; $i++) {
            $region = $this.Regions[$i]
            $isHighlight = ($i -eq $this.State.HighlightIndex)

            $baseSize = 40
            $pulse = 1.0
            if ($isHighlight) {
                $pulse = 1.1 + 0.1 * [math]::Sin($this.State.TickCount * 0.1)
            }
            $radius = $baseSize * $pulse

            $alphaFill = 140
            if ($isHighlight) { $alphaFill = 220 }

            $fillColor = [System.Drawing.Color]::FromArgb(
                $alphaFill,
                $region.Color.R, $region.Color.G, $region.Color.B
            )
            $fillBrush = New-Object System.Drawing.SolidBrush($fillColor)
            $g.FillEllipse($fillBrush, $region.X - $radius/2, $region.Y - $radius/2, $radius, $radius)
            $fillBrush.Dispose()

            $penWidth = 1
            if ($isHighlight) { $penWidth = 2 }
            $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(220, 255, 255, 255), $penWidth)
            $g.DrawEllipse($borderPen, $region.X - $radius/2, $region.Y - $radius/2, $radius, $radius)
            $borderPen.Dispose()

            # name
            $nameFont  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $nameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(240, 240, 240))
            $ts = $g.MeasureString($region.Name, $nameFont)
            $g.DrawString($region.Name, $nameFont, $nameBrush, $region.X - $ts.Width/2, $region.Y - $radius/2 - 18)
            $nameFont.Dispose(); $nameBrush.Dispose()
        }

        # particles
        foreach ($p in $this.Particles) {
            $alpha = [int]( ($p.Life / 120.0) * 180 )
            if ($alpha -lt 10) { continue }
            $color = [System.Drawing.Color]::FromArgb($alpha, $p.Color.R, $p.Color.G, $p.Color.B)
            $brush = New-Object System.Drawing.SolidBrush($color)
            $g.FillEllipse($brush, $p.X - $p.Size/2, $p.Y - $p.Size/2, $p.Size, $p.Size)
            $brush.Dispose()
        }

        # info panel (moved to top-right)
        if ($this.State.HighlightIndex -ge 0 -and $this.State.HighlightIndex -lt $this.Regions.Count) {
            $r = $this.Regions[$this.State.HighlightIndex]

            $panelW = 320
            $panelH = 110
            $panelX = $width - $panelW - 40
            $panelY = 30

            $panelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210, 20, 20, 30))
            $g.FillRectangle($panelBrush, $panelX, $panelY, $panelW, $panelH)
            $panelBrush.Dispose()

            $borderPen = New-Object System.Drawing.Pen($r.Color, 2)
            $g.DrawRectangle($borderPen, $panelX, $panelY, $panelW, $panelH)
            $borderPen.Dispose()

            $titleFont  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $titleBrush = New-Object System.Drawing.SolidBrush($r.Color)
            $g.DrawString($r.Name, $titleFont, $titleBrush, $panelX+14, $panelY+10)
            $titleFont.Dispose(); $titleBrush.Dispose()

            $textFont  = New-Object System.Drawing.Font("Segoe UI", 9)
            $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 230, 230))
            $lines = @(
                "Soil: $($r.Soil)",
                "Climate: $($r.Climate)",
                "Style: $($r.Style)"
            )
            $yy = $panelY + 35
            foreach ($line in $lines) {
                $g.DrawString($line, $textFont, $textBrush, $panelX+14, $yy)
                $yy += 20
            }
            $textFont.Dispose(); $textBrush.Dispose()
        }

        # title
        $titleFont2  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 235, 220))
        $g.DrawString("✨ Terroir Canvas", $titleFont2, $titleBrush2, 20, 20)
        $titleFont2.Dispose(); $titleBrush2.Dispose()

        $subFont  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
        $subBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 210, 200))
        $g.DrawString("Touch the land to read the wine.", $subFont, $subBrush, 20, 45)
        $subFont.Dispose(); $subBrush.Dispose()
    }
}

function Stop-Show14 {
    Write-Host "[Show14] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show14")) {
        $Global:ShowManager.Shows["show14"].Stop()
    }
}

Write-Host "✅ Show14 - Terroir Canvas (GM3, fixed) loaded!" -ForegroundColor Green
