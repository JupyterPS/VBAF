# ==============================================
# Show13 - Flavor Constellation (BaseShow)
# ==============================================

class Show13 : BaseShow {
    hidden [System.Collections.ArrayList] $Wines = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $Connections = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $Stars = [System.Collections.ArrayList]::new()
    hidden [int] $TickCount = 0
    hidden [double] $PulsePhase = 0.0
    hidden [hashtable] $SelectedWine = $null

    Show13([System.Windows.Forms.Panel]$panel) : base("show13", $panel) { }

    [void] OnStart() {
        Write-Host "🌌 [Show13] Flavor Constellation initializing..." -ForegroundColor DarkMagenta

        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 15)

        # Enable double buffering for smoother animation
$prop = $this.Panel.GetType().GetProperty(
    "DoubleBuffered",
    [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
)
if ($prop) { $prop.SetValue($this.Panel, $true, $null) }


        $Global:messages = @(
            "🌌 Flavor Constellation - Wines as celestial characters",
            "⭐ Each star tells its own story in the night sky",
            "✨ Connections reveal family resemblances",
            "🌹 Bright and joyful • 🍷 Deep and contemplative",
            "🌠 Discover your perfect wine moment"
        )

        $this.InitializeConstellation()
        $this.SetupPaintEvent()
        $this.SetupMouseHandler()

        Write-Host "✅ [Show13] $($this.Wines.Count) wine stars shining" -ForegroundColor Green
    }
<#
[void] OnUpdate() {
    if (-not $this.Panel.Visible -or $this.Panel.Width -le 0 -or $this.Panel.Height -le 0) { return }

    $this.TickCount++

    # Only update and repaint every 5th tick (adjust 3–8 to taste)
    if ($this.TickCount % 5 -ne 0) { return }

    $this.PulsePhase += 0.01
    $this.Panel.Invalidate()
}
#>

[void] OnUpdate() {
    if (-not $this.Panel.Visible -or $this.Panel.Width -le 0 -or $this.Panel.Height -le 0) { return }

    $this.TickCount++

    # Update every 2nd tick (instead of 5)
    if ($this.TickCount % 2 -ne 0) { return }

    $this.PulsePhase += 0.02   # a bit faster so pulsing is visible
    $this.Panel.Invalidate()
}


    [void] OnStop() {
        Write-Host "🛑 [Show13] Flavor Constellation cleanup..." -ForegroundColor Yellow

        $this.Wines.Clear()
        $this.Connections.Clear()
        $this.Stars.Clear()
        $this.SelectedWine = $null

        $this.Panel.Remove_Paint($null)
        $this.Panel.Remove_MouseClick($null)
        $this.Panel.Controls.Clear()

        $this.TickCount = 0
        $this.PulsePhase = 0.0

        Write-Host "✔️ [Show13] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] InitializeConstellation() {
        $this.Wines.Clear()
        $this.Connections.Clear()
        $this.Stars.Clear()

        $wineCharacters = @(
            @{Name="Rosé Joyeux"; Fruit=85; Body=25; Color=[System.Drawing.Color]::FromArgb(255,180,200); Personality="Bright summer laughter"},
            @{Name="Sauv Blanc";  Fruit=90; Body=20; Color=[System.Drawing.Color]::FromArgb(220,230,255); Personality="Garden freshness"},
            @{Name="Pinot Grigio";Fruit=75; Body=30; Color=[System.Drawing.Color]::FromArgb(240,230,200); Personality="Crisp morning walks"},
            @{Name="Chard Or";    Fruit=60; Body=55; Color=[System.Drawing.Color]::FromArgb(255,240,180); Personality="Golden sunset sails"},
            @{Name="Pinot Noir";  Fruit=70; Body=45; Color=[System.Drawing.Color]::FromArgb(200,120,100); Personality="Autumn forest whispers"},
            @{Name="Merlot Velours";Fruit=65;Body=65; Color=[System.Drawing.Color]::FromArgb(180,100,90); Personality="Cozy fireside evenings"},
            @{Name="Cab Sauv";    Fruit=50; Body=85; Color=[System.Drawing.Color]::FromArgb(120,60,50); Personality="Deep winter power"},
            @{Name="Syrah Épice"; Fruit=45; Body=90; Color=[System.Drawing.Color]::FromArgb(100,50,60); Personality="Spicy mountain nights"}
        )

        foreach ($wine in $wineCharacters) {
            $x = 160 + ($wine.Fruit * 4.0)
            $y = 140 + (($wine.Body) * 2.0)
            [void]$this.Wines.Add(@{
                Name = $wine.Name
                Fruit = $wine.Fruit
                Body = $wine.Body
                X = [float]$x
                Y = [float]$y
                Color = $wine.Color
                Personality = $wine.Personality
                Size = 10 + ($wine.Body / 15)
            })
        }

        for ($i = 0; $i -lt $this.Wines.Count; $i++) {
            for ($j = $i+1; $j -lt $this.Wines.Count; $j++) {
                $w1 = $this.Wines[$i]
                $w2 = $this.Wines[$j]
                $dx = $w1.X - $w2.X
                $dy = $w1.Y - $w2.Y
                $dist = [math]::Sqrt($dx*$dx + $dy*$dy)
                if ($dist -lt 150) {
                    [void]$this.Connections.Add(@{
                        From = $i
                        To   = $j
                        Strength = (1.0 - ($dist / 150.0))
                    })
                }
            }
        }

        for ($i = 0; $i -lt 80; $i++) {
            [void]$this.Stars.Add(@{
                X = (Get-Random -Minimum 0 -Maximum 700)
                Y = (Get-Random -Minimum 0 -Maximum 450)
                Phase = (Get-Random -Minimum 0 -Maximum 628) / 100.0
            })
        }
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

            $width = $s.Width
            $height = $s.Height
            if ($width -le 0 -or $height -le 0) { return }

            # Space background
            $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                (New-Object Drawing.Point(0,0)), (New-Object Drawing.Point(0,$height)),
                [System.Drawing.Color]::FromArgb(5,5,15),
                [System.Drawing.Color]::FromArgb(15,10,30)
            )
            $g.FillRectangle($bg, 0, 0, $width, $height)
            $bg.Dispose()

            # Twinkling small stars
            foreach ($star in $self.Stars) {
                $alpha = 80 + [int](40 * [math]::Sin($self.PulsePhase + $star.Phase))
                $starBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 255, 240))
                $g.FillEllipse($starBrush, $star.X, $star.Y, 2, 2)
                $starBrush.Dispose()
            }

            # Connections
            foreach ($conn in $self.Connections) {
                $w1 = $self.Wines[$conn.From]
                $w2 = $self.Wines[$conn.To]
                $alpha = [int](50 * $conn.Strength)
                $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha, 140, 180, 230), 1)
                $g.DrawLine($pen, $w1.X, $w1.Y, $w2.X, $w2.Y)
                $pen.Dispose()
            }

            # Wine stars
            foreach ($wine in $self.Wines) {
                $pulse = ([math]::Sin($self.PulsePhase + $wine.Fruit*0.05) + 1) / 2
                $size = $wine.Size * (0.8 + 0.4*$pulse)

                $bodyBrush = New-Object System.Drawing.SolidBrush($wine.Color)
                $g.FillEllipse($bodyBrush, $wine.X - $size/2, $wine.Y - $size/2, $size, $size)
                $bodyBrush.Dispose()

                $nameFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
                $nameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 240, 250))
                $ts = $g.MeasureString($wine.Name, $nameFont)
                $g.DrawString($wine.Name, $nameFont, $nameBrush, $wine.X - $ts.Width/2, $wine.Y + $size/2 + 4)
                $nameFont.Dispose(); $nameBrush.Dispose()
            }

            # Selected wine panel
            if ($self.SelectedWine) {
                $w = $self.SelectedWine
                $px = 30; $py = 30; $pw = 300; $ph = 140

                $panelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(32,20,40))
                $g.FillRectangle($panelBrush, $px, $py, $pw, $ph)
                $panelBrush.Dispose()

                $borderPen = New-Object System.Drawing.Pen($w.Color, 2)
                $g.DrawRectangle($borderPen, $px, $py, $pw, $ph)
                $borderPen.Dispose()

                $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
                $titleBrush = New-Object System.Drawing.SolidBrush($w.Color)
                $g.DrawString($w.Name, $titleFont, $titleBrush, $px+16, $py+16)
                $titleFont.Dispose(); $titleBrush.Dispose()

                $textFont = New-Object System.Drawing.Font("Segoe UI", 9)
                $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 235, 245))
                $lines = @(
                    "Fruitiness: $($w.Fruit)%   Body: $($w.Body)%",
                    "",
                    $w.Personality,
                    "",
                    "✨ A star for moments like this"
                )
                $yy = $py + 48
                foreach ($line in $lines) {
                    $g.DrawString($line, $textFont, $textBrush, $px+16, $yy)
                    $yy += 20
                }
                $textFont.Dispose(); $textBrush.Dispose()
            }

            # Axes labels
            $axisPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 200, 220, 255), 1)
            $g.DrawLine($axisPen, 150, 120, 650, 120)  # Fruit axis
            $g.DrawLine($axisPen, 400, 80, 400, 420)   # Body axis
            $axisPen.Dispose()

            $axisFont = New-Object System.Drawing.Font("Segoe UI", 8)
            $axisBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210, 230, 245))
            $g.DrawString("Lighter Fruit", $axisFont, $axisBrush, 150, 100)
            $g.DrawString("Richer Fruit", $axisFont, $axisBrush, 570, 100)
            $g.DrawString("Lighter Body", $axisFont, $axisBrush, 410, 80)
            $g.DrawString("Fuller Body",  $axisFont, $axisBrush, 410, 400)
            $axisFont.Dispose(); $axisBrush.Dispose()

            # Title
            $titleFont2 = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $titleBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 240, 230))
            $g.DrawString("Flavor Constellation", $titleFont2, $titleBrush2, 40, $height-40)
            $titleFont2.Dispose(); $titleBrush2.Dispose()
        }.GetNewClosure())
    }

    hidden [void] SetupMouseHandler() {
        $self = $this
        $this.Panel.Add_MouseClick({
            param($s, $e)
            $clicked = $null
            foreach ($wine in $self.Wines) {
                $dx = $e.X - $wine.X
                $dy = $e.Y - $wine.Y
                if (($dx*$dx + $dy*$dy) -lt 100) {
                    $clicked = $wine
                    break
                }
            }
            $self.SelectedWine = $clicked
            $self.Panel.Invalidate()
        }.GetNewClosure())
    }
}

function Stop-Show13 {
    Write-Host "[Show13] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show13")) {
        $Global:ShowManager.Shows["show13"].Stop()
    }
}
