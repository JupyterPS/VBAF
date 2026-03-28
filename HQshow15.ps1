# ===============================
# HQ Show15 — ROLLING BARREL LINE v1
# One hero barrel at a time
# ===============================

Write-Host "`n=> _____ HQshow15 (Rolling Barrel Line v1) ___________ <=`n" -ForegroundColor Cyan

class Show15 : BaseShow {
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $BarrelQueue
    hidden [hashtable] $CurrentBarrel

    Show15([System.Windows.Forms.Panel]$panel) : base("show15", $panel) {
        $this.State = @{
            TickCount      = 0
            CellarTemp     = 58
            CellarHumidity = 75
            TickerOffset   = 0

            Phase          = "Idle"   # Idle, Enter, Show, Exit
            ShowCounter    = 0        # counts ticks spent in Show phase
            SpotlightX     = 260      # where barrel stops
        }

        $this.BarrelQueue  = [System.Collections.ArrayList]::new()
        $this.CurrentBarrel = $null
    }

    [void] OnStart() {
        Write-Host "  🛢️ [Show15] Initializing Rolling Barrel Line..." -ForegroundColor Cyan

        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(35, 25, 20)

        $prop = $this.Panel.GetType().GetProperty(
            "DoubleBuffered",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }

        $Show15Messages = @(
            "🍷 ROLLING BARREL LINE - Showcasing great wines",
            "🛢️ Each barrel reveals what is resting inside",
            "🌡️ Temperature: 58°F | Humidity: 75% - Perfect conditions"
        )
        $Global:messages = $Show15Messages

        $this.InitializeBarrelQueue()

        $this.State.Phase       = "Enter"
        $this.State.ShowCounter = 0
        $this.LoadNextBarrel()

        $this.SetupPaintEvent()

        Write-Host "  ✅ [Show15] Ready with $($this.BarrelQueue.Count) barrels in queue" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount

        # Light “cellar conditions” drift (for ticker only)
        if ($tick % 50 -eq 0) {
            $tempChange = (Get-Random -Minimum -5 -Maximum 5) / 10.0
            $this.State.CellarTemp = [math]::Max(55, [math]::Min(62, $this.State.CellarTemp + $tempChange))

            $humidChange = Get-Random -Minimum -2 -Maximum 2
            $this.State.CellarHumidity = [math]::Max(70, [math]::Min(80, $this.State.CellarHumidity + $humidChange))
        }

        # Update ticker scroll
        $this.State.TickerOffset += 2
        if ($this.State.TickerOffset -gt 2000) {
            $this.State.TickerOffset = 0
        }

        # Update current barrel animation (simple state machine)
        if ($this.CurrentBarrel -ne $null) {
            switch ($this.State.Phase) {
"Enter" {
    $this.CurrentBarrel.X += $this.CurrentBarrel.Speed
    $this.CurrentBarrel.Angle += 0.4   # was 2

    if ($this.CurrentBarrel.X -ge $this.State.SpotlightX) {
        $this.CurrentBarrel.X = $this.State.SpotlightX
        $this.State.Phase = "Show"
        $this.State.ShowCounter = 0
    }
}
                "Show" {
                    $this.State.ShowCounter++
                    # gentle “breathing” vertical wobble
                   # $this.CurrentBarrel.OffsetY = [math]::Sin($tick * 0.1) * 0.3


                    # stay in Show for about 3–4 seconds (at ~20 fps → ~60–80 ticks)
                    if ($this.State.ShowCounter -ge 70) {
                        $this.State.Phase = "Exit"
                        $this.CurrentBarrel.Speed = 4
                    }
                }
"Exit" {
    $this.CurrentBarrel.X += $this.CurrentBarrel.Speed
    $this.CurrentBarrel.Angle += 0.6   # was 3

    if ($this.CurrentBarrel.X -gt $this.Panel.Width + 120) {
        $this.LoadNextBarrel()
    }
}
                default { }
            }
        }

        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "  🛑 [Show15] Cleaning up..." -ForegroundColor Yellow

        if ($this.BarrelQueue) { $this.BarrelQueue.Clear() }
        $this.CurrentBarrel = $null

        $this.Panel.Remove_Paint($null)
        $this.Panel.Controls.Clear()

        $this.State.TickCount    = 0
        $this.State.TickerOffset = 0
        $this.State.Phase        = "Idle"

        Write-Host "  ✅ [Show15] Cleanup complete" -ForegroundColor Green
    }

    # -----------------------------
    # Barrel queue and state
    # -----------------------------
    hidden [void] InitializeBarrelQueue() {
        $wineTypes = @(
            @{Varietal="Cabernet Sauvignon"; Vintage=2020},
            @{Varietal="Merlot";             Vintage=2021},
            @{Varietal="Pinot Noir";         Vintage=2021},
            @{Varietal="Chardonnay";         Vintage=2022},
            @{Varietal="Syrah";              Vintage=2020},
            @{Varietal="Zinfandel";          Vintage=2021},
            @{Varietal="Sauvignon Blanc";    Vintage=2022},
            @{Varietal="Malbec";             Vintage=2020},
            @{Varietal="Riesling";           Vintage=2022},
            @{Varietal="Tempranillo";        Vintage=2021}
        )

        foreach ($w in $wineTypes) {
            [void]$this.BarrelQueue.Add($w)
        }
    }

hidden [void] LoadNextBarrel() {
    if ($this.BarrelQueue.Count -eq 0) {
        $this.InitializeBarrelQueue()
    }

    $next = $this.BarrelQueue[0]
    $this.BarrelQueue.RemoveAt(0)

    $this.CurrentBarrel = @{
        Varietal = $next.Varietal
        Vintage  = $next.Vintage
        X        = -140
        Y        = 250
        Width    = 130
        Height   = 70
        Speed    = 3
        OffsetY  = 0
        Angle    = 0    # <<< NEW
    }

    $this.State.Phase = "Enter"
    $this.State.ShowCounter = 0
}

    # -----------------------------
    # Events and rendering
    # -----------------------------
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderScene($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }

    hidden [void] RenderScene([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        if ($width -le 0 -or $height -le 0) { return }

        # Background – warm hall
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(45, 30, 22),
            [System.Drawing.Color]::FromArgb(25, 18, 14)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()

        # Simple floor
        $floorY = 200
        $floorBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, $floorY),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(70, 50, 35),
            [System.Drawing.Color]::FromArgb(35, 25, 18)
        )
        $g.FillRectangle($floorBrush, 0, $floorY, $width, $height - $floorY)
        $floorBrush.Dispose()

        # Soft central light
        $centerPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $centerPath.AddEllipse($width/2 - 260, 40, 520, 260)
        $centerGlow = New-Object System.Drawing.Drawing2D.PathGradientBrush($centerPath)
        $centerGlow.CenterColor = [System.Drawing.Color]::FromArgb(60, 255, 220, 160)
        $centerGlow.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        $g.FillEllipse($centerGlow, $width/2 - 260, 40, 520, 260)
        $centerGlow.Dispose()
        $centerPath.Dispose()

        # Conveyor line hint (a simple stripe under the barrel path)
        $lineY = 260
        $lineBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 40, 30, 25))
        $g.FillRectangle($lineBrush, 0, $lineY + 40, $width, 6)
        $lineBrush.Dispose()

        # Draw the current barrel
        if ($this.CurrentBarrel -ne $null) {
            $this.RenderBarrel($g, $this.CurrentBarrel)
            if ($this.State.Phase -eq "Show") {
                $this.RenderBarrelCard($g, $this.CurrentBarrel, $width)
            }
        }

        # Bottom ticker
        $this.RenderTicker($g, $width, $height)

        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 195, 145, 90))
        $titleText = "✨ ROLLING BARREL LINE"
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }

hidden [void] RenderBarrel([System.Drawing.Graphics]$g, [hashtable]$b) {
    $x = [int]$b.X
$y = [int]$b.Y
    $w = [int]$b.Width
    $h = [int]$b.Height
    $angle = [float]$b.Angle

    # Compute center
    $cx = $x + $w / 2.0
    $cy = $y + $h / 2.0

    # Save transform
    $oldTransform = $g.Transform.Clone()

    # Move origin to center and rotate
    $g.TranslateTransform($cx, $cy)
    $g.RotateTransform($angle)
    $g.TranslateTransform(-$cx, -$cy)

    # --- draw barrel in rotated space ---

    # Shadow
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 0, 0, 0))
    $g.FillEllipse($shadowBrush, $x - 8, $y + $h - 2, $w + 16, 14)
    $shadowBrush.Dispose()

    # Barrel body
    $bodyBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        [System.Drawing.Point]::new($x, $y),
        [System.Drawing.Point]::new($x + $w, $y),
        [System.Drawing.Color]::FromArgb(170, 120, 70),
        [System.Drawing.Color]::FromArgb(110, 80, 45)
    )
    $g.FillRectangle($bodyBrush, $x, $y, $w, $h)
    $bodyBrush.Dispose()

    # Ends
    $endBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(135, 95, 60))
    $g.FillEllipse($endBrush, $x - 14, $y, 28, $h)
    $g.FillEllipse($endBrush, $x + $w - 14, $y, 28, $h)
    $endBrush.Dispose()

    # Hoops
    $bandPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(170, 110, 110, 110), 4)
    $g.DrawLine($bandPen, $x, $y + 12,    $x + $w, $y + 12)
    $g.DrawLine($bandPen, $x, $y + $h/2,  $x + $w, $y + $h/2)
    $g.DrawLine($bandPen, $x, $y + $h-12, $x + $w, $y + $h-12)
    $bandPen.Dispose()

    # Highlight
    $highlightPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 240, 240, 240), 1)
    $g.DrawLine($highlightPen, $x + 4, $y + 11, $x + $w - 4, $y + 11)
    $highlightPen.Dispose()

    # Wood grain
    $grainPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 70, 50, 25), 1)
    for ($i = 1; $i -lt 6; $i++) {
        $gx = $x + ($i * $w / 6)
        $g.DrawLine($grainPen, $gx, $y + 3, $gx, $y + $h - 3)
    }
    $grainPen.Dispose()

    # Restore transform
    $g.Transform = $oldTransform
    $oldTransform.Dispose()
}


    hidden [void] RenderBarrelCard([System.Drawing.Graphics]$g, [hashtable]$b, [int]$width) {
        $cardWidth  = 260
        $cardHeight = 90
        $cardX = [int]([math]::Min([math]::Max($b.X + $b.Width/2 - $cardWidth/2, 20), $width - $cardWidth - 20))
        $cardY = 120

        $bg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 40, 28, 20))
        $g.FillRectangle($bg, $cardX, $cardY, $cardWidth, $cardHeight)
        $bg.Dispose()

        $border = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(190, 160, 115, 70), 2)
        $g.DrawRectangle($border, $cardX, $cardY, $cardWidth, $cardHeight)
        $border.Dispose()

        $titleFont  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 190, 110))
        $titleText  = "$($b.Varietal) $($b.Vintage)"
        $g.DrawString($titleText, $titleFont, $titleBrush, $cardX + 12, $cardY + 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()

        $detailFont  = New-Object System.Drawing.Font("Segoe UI", 8)
        $detailBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 215, 195))
        $details = @(
            "Contents: $($b.Varietal)",
            "Vintage:  $($b.Vintage)",
            "Stage:    Barrel aging"
        )
        $y = $cardY + 36
        foreach ($line in $details) {
            $g.DrawString($line, $detailFont, $detailBrush, $cardX + 12, $y)
            $y += 18
        }
        $detailFont.Dispose()
        $detailBrush.Dispose()
    }

    hidden [void] RenderTicker([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $tickerHeight = 32
        $tickerY = $height - $tickerHeight - 4

        $bg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 40, 28, 20))
        $g.FillRectangle($bg, 0, $tickerY, $width, $tickerHeight)
        $bg.Dispose()

        $border = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(170, 160, 115, 70), 2)
        $g.DrawRectangle($border, 0, $tickerY, $width - 1, $tickerHeight - 1)
        $border.Dispose()

        $tempIcon = if ($this.State.CellarTemp -gt 60) { "⚠️" } elseif ($this.State.CellarTemp -lt 55) { "❄️" } else { "✓" }
        $tickerText = "🍷 BARREL LINE: 🌡️ $($this.State.CellarTemp)°F $tempIcon • 💧 Humidity: $($this.State.CellarHumidity)% • Each barrel reveals its story..."

        $font  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 215, 195))

        $size = $g.MeasureString($tickerText, $font)
        $x = $width - $this.State.TickerOffset

        $g.DrawString($tickerText, $font, $brush, $x, $tickerY + 6)
        $g.DrawString($tickerText, $font, $brush, $x + $size.Width, $tickerY + 6)

        $font.Dispose()
        $brush.Dispose()
    }
}

function Stop-Show15 {
    Write-Host "[Show15] Stop called (Rolling Barrel Line v1)" -ForegroundColor Yellow

    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show15")) {
        $show = $Global:ShowManager.Shows["show15"]
        $show.Stop()
    }

    Write-Host "✅ [Show15] Stopped" -ForegroundColor Green
}



