# ==============================================
# Show12 - Tasting Room Palette (BaseShow, clean)
# ==============================================

class Show12 : BaseShow {
    hidden [System.Collections.ArrayList] $Glasses = [System.Collections.ArrayList]::new()
    hidden [int]    $TickCount   = 0
    hidden [double] $TableRotate = 0.0
    hidden [double] $CandlePhase = 0.0
    hidden [hashtable] $SelectedGlass = $null

    Show12([System.Windows.Forms.Panel]$panel) : base("show12", $panel) { }

    [void] OnStart() {
        Write-Host "🥂 [Show12] Tasting Room initializing..." -ForegroundColor Magenta

        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(35, 25, 20)

        # Enable double buffering on the panel
        $prop = $this.Panel.GetType().GetProperty(
            "DoubleBuffered",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }

        $Global:messages = @(
            "🥂 Tasting Room - Where stories meet in the glass",
            "🍷 Each glass holds a moment and a memory",
            "✨ Watch the wines breathe and reveal their character",
            "🌹 Rosé blushes for summer evenings",
            "🍇 Cabernet whispers of winter fireplaces"
        )

        $this.InitializeGlasses()
        $this.SetupPaintEvent()
        $this.SetupMouseHandler()

        Write-Host "✅ [Show12] Tasting table set with $($this.Glasses.Count) wines" -ForegroundColor Green
    }

[void] OnUpdate() {
    if (-not $this.Panel.Visible -or $this.Panel.Width -le 0 -or $this.Panel.Height -le 0) { return }

    $this.TickCount++

    # Draw only every 5th tick instead of every 2nd
    if ($this.TickCount % 2 -ne 0) { return }               # 6,7,8

    $this.TableRotate += 0.001
    $this.CandlePhase += 0.02
    $this.Panel.Invalidate()
}


    [void] OnStop() {
        Write-Host "🛑 [Show12] Tasting Room cleanup..." -ForegroundColor Yellow

        $this.Glasses.Clear()
        $this.SelectedGlass = $null

        $this.Panel.Remove_Paint($null)
        $this.Panel.Remove_MouseClick($null)
        $this.Panel.Controls.Clear()

        $this.TickCount   = 0
        $this.TableRotate = 0.0
        $this.CandlePhase = 0.0

        Write-Host "✔️ [Show12] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] InitializeGlasses() {
        $this.Glasses.Clear()

        $wineStories = @(
            @{Name="Château Rouge";  Style="Bold Red";    Color=[System.Drawing.Color]::FromArgb(120,40,25);  Notes="Fireplace evenings, dark chocolate"},
            @{Name="Blanc d'Été";    Style="Crisp White"; Color=[System.Drawing.Color]::FromArgb(220,200,140); Notes="Seaside afternoons, oysters"},
            @{Name="Rosé Lumière";   Style="Summer Blush";Color=[System.Drawing.Color]::FromArgb(255,180,190); Notes="Picnics, laughter in the park"},
            @{Name="Pinot Noire";    Style="Elegant Red"; Color=[System.Drawing.Color]::FromArgb(140,60,50);   Notes="Autumn walks, forest mushrooms"},
            @{Name="Sauvignon Vive"; Style="Bright White";Color=[System.Drawing.Color]::FromArgb(230,210,160); Notes="Garden parties, goat cheese"},
            @{Name="Merlot Doux";    Style="Velvet Red";  Color=[System.Drawing.Color]::FromArgb(110,50,40);   Notes="Quiet dinners, soft conversation"},
            @{Name="Chardonnay Or";  Style="Golden White";Color=[System.Drawing.Color]::FromArgb(240,220,160); Notes="Sunset sails, lobster"},
            @{Name="Syrah Mystère";  Style="Spicy Red";   Color=[System.Drawing.Color]::FromArgb(90,35,30);    Notes="Winter nights, lamb tagine"}
        )

        $radius  = 130
        $centerX = 0
        $centerY = 0
        $angleStep = 360 / $wineStories.Count
        $angle = 0.0

        foreach ($wine in $wineStories) {
            $rad = $angle * [math]::PI / 180
            [void]$this.Glasses.Add(@{
                Name  = $wine.Name
                Style = $wine.Style
                Color = $wine.Color
                BaseX = [float]($centerX + [math]::Cos($rad) * $radius)
                BaseY = [float]($centerY + [math]::Sin($rad) * $radius)
                Notes = $wine.Notes
            })
            $angle += $angleStep
        }
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)

            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

            $width  = $s.Width
            $height = $s.Height
            if ($width -le 0 -or $height -le 0) { return }

            $centerX = [int]($width / 2)
            $centerY = [int]($height / 2 + 40)

            # TABLE (gradient)
            $p1 = New-Object System.Drawing.Point ($centerX-250), ($centerY-160)
            $p2 = New-Object System.Drawing.Point ($centerX+250), ($centerY+160)
            $tableBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush `
                ($p1, $p2,
                 [System.Drawing.Color]::FromArgb(70, 50, 35),
                 [System.Drawing.Color]::FromArgb(40, 25, 20))
            $g.FillEllipse($tableBrush, $centerX-250, $centerY-160, 500, 320)
            $tableBrush.Dispose()

            # Candles
            for ($i = 0; $i -lt 6; $i++) {
                $ang = ($i * 60) * [math]::PI / 180
                $cx = $centerX + [math]::Cos($ang) * 210
                $cy = $centerY + [math]::Sin($ang) * 90
                $flicker = [math]::Sin($self.CandlePhase + $i) * 0.3 + 0.7
                $glowBrush = New-Object System.Drawing.SolidBrush(
                    [System.Drawing.Color]::FromArgb([int]($flicker*60), 255, 210, 120)
                )
                $g.FillEllipse($glowBrush, [int]($cx-15), [int]($cy-25), 30, 40)
                $glowBrush.Dispose()
            }

            # Glasses
            foreach ($glass in $self.Glasses) {
                $r = [math]::Sqrt($glass.BaseX*$glass.BaseX + $glass.BaseY*$glass.BaseY)
                $baseAngle = [math]::Atan2($glass.BaseY, $glass.BaseX) + $self.TableRotate
                $gx = $centerX + [math]::Cos($baseAngle) * $r
                $gy = $centerY + [math]::Sin($baseAngle) * $r

                # Stem
                $stemPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 240, 240, 220), 4)
                $g.DrawLine($stemPen, [int]$gx, [int]$gy+25, [int]$gx, [int]$gy+60)
                $stemPen.Dispose()

                # Bowl (gradient)
                $bp1 = New-Object System.Drawing.Point ([int]$gx-20), ([int]$gy-5)
                $bp2 = New-Object System.Drawing.Point ([int]$gx+20), ([int]$gy+15)
                $bowlBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush `
                    ($bp1, $bp2,
                     $glass.Color,
                     [System.Drawing.Color]::FromArgb(180, 255, 255, 255))
                $g.FillEllipse($bowlBrush, [int]$gx-20, [int]$gy-5, 40, 30)
                $bowlBrush.Dispose()

                # Rim
                $rimBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 255, 240))
                $g.FillEllipse($rimBrush, [int]$gx-18, [int]$gy-8, 36, 8)
                $rimBrush.Dispose()

                # Base
                $baseBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 200, 200, 180))
                $g.FillEllipse($baseBrush, [int]$gx-12, [int]$gy+20, 24, 8)
                $baseBrush.Dispose()

                # Name
                $nameFont  = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
                $nameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 235, 220))
                $ts = $g.MeasureString($glass.Name, $nameFont)
                $g.DrawString($glass.Name, $nameFont, $nameBrush, $gx - $ts.Width/2, $gy+70)
                $nameFont.Dispose(); $nameBrush.Dispose()
            }


                       # Selected glass story card (moved to top-right)
# Selected glass story card (smaller, tighter top-right)
if ($self.SelectedGlass) {
    $glass = $self.SelectedGlass

    $cardW = 180   # was 280
    $cardH = 90    # was 160
    $cardX = $width - $cardW - 20   # closer to right edge
    $cardY = 20                     # closer to top

    $cardBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235,245,230))
    $g.FillRectangle($cardBrush, $cardX, $cardY, $cardW, $cardH)
    $cardBrush.Dispose()

    $borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160,140,110), 2)
    $g.DrawRectangle($borderPen, $cardX, $cardY, $cardW, $cardH)
    $borderPen.Dispose()

    $titleFont  = New-Object System.Drawing.Font("Georgia", 10, [System.Drawing.FontStyle]::Bold)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(110,60,40))
    $g.DrawString($glass.Name, $titleFont, $titleBrush, $cardX+10, $cardY+8)
    $titleFont.Dispose(); $titleBrush.Dispose()

    $textFont  = New-Object System.Drawing.Font("Segoe UI", 8)
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90,50,30))

    # Only two lines now
    $lines = @(
        "Style: $($glass.Style)",
        $glass.Notes
    )

    $y = $cardY + 30
    foreach ($line in $lines) {
        $g.DrawString($line, $textFont, $textBrush, $cardX+10, $y)
        $y += 16
    }

    $textFont.Dispose(); $textBrush.Dispose()
}






            # Title
            $titleFont2  = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Italic)
            $titleBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 230, 210))
            $g.DrawString("✨ La Table des Histoires", $titleFont2, $titleBrush2, 40, 10)
            $titleFont2.Dispose(); $titleBrush2.Dispose()
        }.GetNewClosure())
    }

    hidden [void] SetupMouseHandler() {
        $self = $this
        $this.Panel.Add_MouseClick({
            param($s, $e)

            $width = $self.Panel.Width
            $height = $self.Panel.Height
            $centerX = [int]($width / 2)
            $centerY = [int]($height / 2 + 40)

            $clicked = $null
            foreach ($glass in $self.Glasses) {
                $r = [math]::Sqrt($glass.BaseX*$glass.BaseX + $glass.BaseY*$glass.BaseY)
                $baseAngle = [math]::Atan2($glass.BaseY, $glass.BaseX) + $self.TableRotate
                $gx = $centerX + [math]::Cos($baseAngle) * $r
                $gy = $centerY + [math]::Sin($baseAngle) * $r

                $dx = $e.X - $gx
                $dy = $e.Y - $gy
                if (($dx*$dx + $dy*$dy) -lt 30*30) {
                    $clicked = $glass
                    break
                }
            }

            $self.SelectedGlass = $clicked
            $self.Panel.Invalidate()
        }.GetNewClosure())
    }
}

function Stop-Show12 {
    Write-Host "🛑 [Show12] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show12")) {
        $Global:ShowManager.Shows["show12"].Stop()
    }
}
