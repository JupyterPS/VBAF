# ==============================================
# Show11 - Vineyard Seasons (BaseShow)
# ==============================================

class Show11 : BaseShow {
    hidden [System.Collections.ArrayList] $Vines = [System.Collections.ArrayList]::new()
    hidden [int] $TickCount = 0
    hidden [int] $Season = 0
    hidden [double] $DayPhase = 0.0
    hidden [double] $Wind = 0.0

    Show11([System.Windows.Forms.Panel]$panel) : base("show11", $panel) { }

    [void] OnStart() {
        Write-Host "🌿 [Show11] Vineyard Seasons initializing..." -ForegroundColor Green

        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(20, 40, 60)

        # Enable double buffering for smooth rendering
$prop = $this.Panel.GetType().GetProperty(
    "DoubleBuffered",
    [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
)
if ($prop) { $prop.SetValue($this.Panel, $true, $null) }


        $Global:messages = @(
            "🌿 Vineyard Seasons - Where every slope tells a story",
            "☀️ Spring awakens buds and gentle greens",
            "☀️ Summer ripens fruit under golden light",
            "🍇 Autumn harvest paints the hills in amber",
            "❄️ Winter rests, dreaming of the next vintage"
        )

        $this.InitializeVines()
        $this.SetupPaintEvent()

        Write-Host "✅ [Show11] Vineyard ready with $($this.Vines.Count) vines" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.TickCount++
        $this.DayPhase += 0.02

        $this.Season = ([math]::Floor($this.DayPhase / (2 * [math]::PI))) % 4
        $this.Wind = [math]::Sin($this.DayPhase * 0.3) * 0.5

        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "🛑 [Show11] Vineyard Seasons cleanup..." -ForegroundColor Yellow

        $this.Vines.Clear()
        $this.Panel.Remove_Paint($null)
        $this.Panel.Controls.Clear()

        $this.TickCount = 0
        $this.Season = 0
        $this.DayPhase = 0.0
        $this.Wind = 0.0

        Write-Host "✔️ [Show11] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] InitializeVines() {
        $this.Vines.Clear()
        $vineRows = 8
        for ($row = 0; $row -lt $vineRows; $row++) {
            for ($col = 0; $col -lt 12; $col++) {
                $x = 60 + ($col * 55) + ($row * 8)
                $y = 200 + ($row * 35)
                [void]$this.Vines.Add(@{
                    X = [float]$x
                    Y = [float]$y
                    Row = $row
                    Col = $col
                    Varietal = @("Cabernet","Merlot","Pinot","Chardonnay","Syrah") | Get-Random
                })
            }
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

            # Sky gradient by season
            $skyTop = switch ($self.Season) {
                0 { [System.Drawing.Color]::FromArgb(135, 206, 235) }   # Spring
                1 { [System.Drawing.Color]::FromArgb(255, 223, 150) }   # Summer
                2 { [System.Drawing.Color]::FromArgb(255, 165, 0) }     # Autumn
                3 { [System.Drawing.Color]::FromArgb(173, 216, 230) }   # Winter
            }
            $skyBottom = [System.Drawing.Color]::FromArgb(100, 149, 237)

            $skyBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                (New-Object Drawing.Point(0,0)),
                (New-Object Drawing.Point(0,[int]($height/2))),
                $skyTop, $skyBottom
            )
            $g.FillRectangle($skyBrush, 0, 0, $width, [int]($height/2))
            $skyBrush.Dispose()

            # Sun path
            $sunX = 120 + [math]::Sin($self.DayPhase) * 220
            $sunY = 80 + [math]::Abs([math]::Cos($self.DayPhase)) * 80
            $sunGlow = New-Object System.Drawing.SolidBrush(
                [System.Drawing.Color]::FromArgb(90, 255, 220, 150)
            )
            $g.FillEllipse($sunGlow, [int]($sunX-40), [int]($sunY-40), 80, 80)
            $sunGlow.Dispose()

            # Hills
            $hillBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                (New-Object Drawing.Point(0,[int]($height/2))),
                (New-Object Drawing.Point(0,$height)),
                [System.Drawing.Color]::FromArgb(34,139,34),
                [System.Drawing.Color]::FromArgb(0,100,0)
            )
            $g.FillRectangle($hillBrush, 0, [int]($height/2), $width, [int]($height/2))
            $hillBrush.Dispose()

            # Vines back to front
            $sorted = $self.Vines | Sort-Object Row -Descending
            foreach ($vine in $sorted) {
                $self.RenderVine($g, $vine)
            }

            # Title
            $seasonNames = @("✨ Spring Awakening","✨ Summer Ripening","✨ Golden Harvest","✨ Winter Rest")
            $title = $seasonNames[$self.Season % 4]
            $titleFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Italic)
            $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(240, 240, 220))
            $ts = $g.MeasureString($title, $titleFont)
            $g.DrawString($title, $titleFont, $titleBrush, ($width - $ts.Width)/2, 20)
            $titleFont.Dispose(); $titleBrush.Dispose()
        }.GetNewClosure())
    }

    hidden [void] RenderVine([System.Drawing.Graphics]$g, $vine) {
        $bend = $this.Wind * 15
        $stemPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90, 139, 69), 4)
        $g.DrawLine($stemPen, [int]$vine.X, [int]$vine.Y, [int]($vine.X+$bend), [int]($vine.Y-60))
        $stemPen.Dispose()

        $leafColor = switch ($this.Season) {
            0 { [System.Drawing.Color]::FromArgb(170, 144, 238, 144) }
            1 { [System.Drawing.Color]::FromArgb(190, 200, 180, 120) }
            2 { [System.Drawing.Color]::FromArgb(210, 200, 140, 80) }
            3 { [System.Drawing.Color]::FromArgb(140, 150, 150, 170) }
        }

        for ($i = 0; $i -lt 6; $i++) {
            $leafX = $vine.X + [math]::Sin($i*1.2) * 12 + $bend
            #$leafY = $vine.Y - 20 - ($i*8)
            $leafY = $vine.Y - 20 - ($i*8) + [math]::Sin($this.DayPhase + $vine.Row*0.3) * 2

            $leafBrush = New-Object System.Drawing.SolidBrush($leafColor)
            $g.FillEllipse($leafBrush, [int]($leafX-6), [int]($leafY-4), 12, 8)
            $leafBrush.Dispose()
        }

        if ($this.Season -ge 1) {
            $grapeColor = switch ($vine.Varietal) {
                "Cabernet" { [System.Drawing.Color]::FromArgb(120, 50, 30) }
                "Merlot"   { [System.Drawing.Color]::FromArgb(130, 60, 40) }
                default    { [System.Drawing.Color]::FromArgb(115, 45, 30) }
            }
            $grapeBrush = New-Object System.Drawing.SolidBrush($grapeColor)
            for ($i = 0; $i -lt 4; $i++) {
                $g.FillEllipse($grapeBrush, [int]($vine.X-8), [int]($vine.Y-35-$i*3), 6, 6)
            }
            $grapeBrush.Dispose()
        }
    }
}

function Stop-Show11 {
    Write-Host "🛑 [Show11] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show11")) {
        $Global:ShowManager.Shows["show11"].Stop()
    }
}
