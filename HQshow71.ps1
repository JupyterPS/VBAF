# ===============================
# Show71 — Castle Parade with Agent2 Visuals (GM v3)
# Wine Company - Full Castle Animation with Calm World Background
# ===============================

Write-Host "`n=> _____ HQshow71 (Castle Parade - Agent2 Style) ___________ <=`n" -ForegroundColor Cyan

class Show71 : BaseShow {
    hidden [System.Collections.ArrayList] $Castles
    hidden [hashtable] $State

    Show71([System.Windows.Forms.Panel]$panel) : base("show71", $panel) {
        $this.Castles = [System.Collections.ArrayList]::new()
        $this.State = @{
            TickCount = 0
            TargetCalm = 0.5
            VisualCalm = 0.5
        }
        $this.InitializeCastles()
    }

    [void] OnStart() {
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::Black

        $prop = $this.Panel.GetType().GetProperty(
            "DoubleBuffered",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }

        $this.CreateCalmSlider()
        $this.SetupEvents()
        Write-Host "  ✅ [Show71] Castle Parade with Agent2 Visuals started" -ForegroundColor Magenta
    }

[void] OnUpdate() {
    if (-not $this.Panel.Visible -or $this.Panel.Width -le 0 -or $this.Panel.Height -le 0) { return }

    $this.State.TickCount++

    # Smooth calm interpolation
    $this.State.VisualCalm += ($this.State.TargetCalm - $this.State.VisualCalm) * 0.03

    # Initialize castles on first update when dimensions are valid
    $width = $this.Panel.Width
    $groundY = [int]($this.Panel.Height * 0.62)
    
    foreach ($c in $this.Castles) {
        # Initialize uninitialized castles (Width = 0)
        if ($c.Width -eq 0) {
            $this.RandomizeCastle($c, $width, $groundY)
        }
        
        $c.X -= $c.Speed
        # Animate flags
        if ($c.Flags) {
            foreach ($flag in $c.Flags) {
                $flag.WaveOffset = [Math]::Sin($this.State.TickCount * 0.15 + $flag.Phase) * 3
            }
        }
        
        # Animate torch flames
        if ($c.Torches) {
            foreach ($torch in $c.Torches) {
                $torch.FlickerOffset = [Math]::Sin($this.State.TickCount * 0.3 + $torch.Phase) * 2
                $torch.FlickerSize = 1 + [Math]::Abs([Math]::Sin($this.State.TickCount * 0.25 + $torch.Phase)) * 0.5
            }
        }
    }
    
    # Recycle castles
    for ($i = 0; $i -lt $this.Castles.Count; $i++) {
        $c = $this.Castles[$i]
        if ($c.X + $c.Width -lt -50) {
            $this.RandomizeCastle($c, $width, $groundY)
        }
    }

    $this.Panel.Invalidate()
}

    [void] OnStop() {
        $this.Panel.Controls.Clear()
        $this.Castles.Clear()
        Write-Host "  🛑 [Show71] Stopped" -ForegroundColor Yellow
    }

    # ---------- INITIALIZATION ----------

    hidden [void] InitializeCastles() {
        $this.Castles.Clear()
        $startX = 0
        for ($i = 0; $i -lt 8; $i++) {
            $castle = @{
                X      = $startX
                Y      = 0
                Width  = 0
                Height = 0
                Speed  = (Get-Random -Minimum 3 -Maximum 9) / 10.0
                Type   = ""
                Towers = @()
                Flags  = @()
                Torches = @()
                Color  = [System.Drawing.Color]::White
                WindowColor = [System.Drawing.Color]::White
                ThemeName = ""
            }
            $this.Castles.Add($castle) | Out-Null
            $startX += 250
        }
<#
        # Initialize with panel dimensions if available
        if ($this.Panel.Width -gt 0 -and $this.Panel.Height -gt 0) {            
            $groundY = [int]($this.Panel.Height * 0.62)
            foreach ($c in $this.Castles) {
                $this.RandomizeCastle($c, $this.Panel.Width, $groundY)
            }
        }
#>
    }

    hidden [void] RandomizeCastle($castle, [int]$canvasWidth, [int]$groundY) {
        # Weighted types
        $types = @(
        "Gothic", "FairyTale", "Cathedral", "FairyTale","Oriental"
        "Fortress", "Palace", "Cathedral", "FairyTale", "Oriental" 
        "Wizard", "Cathedral", "FairyTale", "Oriental"
        "Oriental", "Ruins", "Cathedral", "FairyTale" 
        )
        $castle.Type = $types[(Get-Random -Minimum 0 -Maximum $types.Count)]

        $castle.X = $canvasWidth + (Get-Random -Minimum 60 -Maximum 350)

        # Color themes
        $colorThemes = @(
            @{ Castle = [System.Drawing.Color]::FromArgb(140, 230, 230, 240); Window = [System.Drawing.Color]::FromArgb(220, 255, 240, 180); Name = "Moonstone" },
            @{ Castle = [System.Drawing.Color]::FromArgb(120, 180, 100, 130); Window = [System.Drawing.Color]::FromArgb(200, 255, 200, 120); Name = "Emerald" },
            @{ Castle = [System.Drawing.Color]::FromArgb(130, 150, 120, 160); Window = [System.Drawing.Color]::FromArgb(230, 255, 220, 180); Name = "Amethyst" },
            @{ Castle = [System.Drawing.Color]::FromArgb(110, 200, 160, 140); Window = [System.Drawing.Color]::FromArgb(200, 255, 210, 140); Name = "Sandstone" }
        )
        $theme = $colorThemes[(Get-Random -Minimum 0 -Maximum $colorThemes.Count)]
        $castle.Color = $theme.Castle
        $castle.WindowColor = $theme.Window
        $castle.ThemeName = $theme.Name

        # Build based on type
        switch ($castle.Type) {
            "Gothic"    { $this.BuildGothicCastle($castle, $groundY) }
            "FairyTale" { $this.BuildFairyTaleCastle($castle, $groundY) }
            "Fortress"  { $this.BuildFortressCastle($castle, $groundY) }
            "Palace"    { $this.BuildPalaceCastle($castle, $groundY) }
            "Wizard"    { $this.BuildWizardCastle($castle, $groundY) }
            "Cathedral" { $this.BuildCathedralCastle($castle, $groundY) }
            "Oriental"  { $this.BuildOrientalCastle($castle, $groundY) }
            "Ruins"     { $this.BuildRuinsCastle($castle, $groundY) }
        }
    }

    # ---------- CASTLE BUILDERS ----------

    hidden [void] BuildGothicCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 110 -Maximum 170
        $castleHeight = Get-Random -Minimum 95 -Maximum 140
        
        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight
        
        $towers = @()
        for ($t = 0; $t -lt 4; $t++) {
            $towers += @{
                X = ($t * ($castleWidth / 4)) + (Get-Random -Minimum 0 -Maximum 12)
                Width = Get-Random -Minimum 20 -Maximum 30
                Height = Get-Random -Minimum 55 -Maximum 100
                HasRoof = $true
                RoofType = "Pointed"
                HasFlag = (Get-Random -Minimum 0 -Maximum 2) -eq 1
            }
        }
        $castle.Towers = $towers
        $this.AddFlags($castle)
        $this.AddTorches($castle, 4)
    }

    hidden [void] BuildFairyTaleCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 130 -Maximum 190
        $castleHeight = Get-Random -Minimum 85 -Maximum 125
        
        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight
        
        $towers = @()
        $towerCount = Get-Random -Minimum 4 -Maximum 6
        for ($t = 0; $t -lt $towerCount; $t++) {
            $towers += @{
                X = Get-Random -Minimum 5 -Maximum ($castleWidth - 35)
                Width = Get-Random -Minimum 24 -Maximum 34
                Height = Get-Random -Minimum 45 -Maximum 75
                HasRoof = $true
                RoofType = "Spire"
                IsRound = $true
                HasFlag = $true
            }
        }
        $castle.Towers = $towers
        $this.AddFlags($castle)
        $this.AddTorches($castle, 6)
    }

    hidden [void] BuildFortressCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 150 -Maximum 210
        $castleHeight = Get-Random -Minimum 75 -Maximum 120
        
        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight
        
        $towers = @()
        for ($t = 0; $t -lt 5; $t++) {
            $towers += @{
                X = ($t * ($castleWidth / 5)) + (Get-Random -Minimum 0 -Maximum 8)
                Width = Get-Random -Minimum 30 -Maximum 42
                Height = Get-Random -Minimum 40 -Maximum 65
                HasRoof = $true
                RoofType = "Battlement"
                HasFlag = (Get-Random -Minimum 0 -Maximum 3) -eq 1
            }
        }
        $castle.Towers = $towers
        $this.AddFlags($castle)
        $this.AddTorches($castle, 8)
    }

    hidden [void] BuildPalaceCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 170 -Maximum 230
        $castleHeight = Get-Random -Minimum 95 -Maximum 145
        
        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight
        
        $towers = @()
        for ($t = 0; $t -lt 5; $t++) {
            $towers += @{
                X = Get-Random -Minimum 10 -Maximum ($castleWidth - 45)
                Width = Get-Random -Minimum 32 -Maximum 48
                Height = Get-Random -Minimum 35 -Maximum 60
                HasRoof = $true
                RoofType = "Spire"
                HasFlag = (Get-Random -Minimum 0 -Maximum 2) -eq 1
            }
        }
        $castle.Towers = $towers
        $this.AddFlags($castle)
        $this.AddTorches($castle, 7)
    }

    hidden [void] BuildWizardCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 90 -Maximum 130
        $castleHeight = Get-Random -Minimum 65 -Maximum 95
        
        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight
        
        $towers = @(
            @{
                X = [int]($castleWidth / 3)
                Width = 38
                Height = 150
                HasRoof = $true
                RoofType = "Pointed"
                HasFlag = $true
                IsSpecial = $true
            }
        )
        $castle.Towers = $towers
        $this.AddFlags($castle)
        $this.AddTorches($castle, 3)
    }

    hidden [void] BuildCathedralCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 140 -Maximum 200
        $castleHeight = Get-Random -Minimum 105 -Maximum 155

        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight

        $towers = @(
            @{
                X = [int]($castleWidth / 2 - 22); Width = 44; Height = 120
                HasRoof = $true; RoofType = "Spire"
                HasFlag = $true
                HasRoseWindow = $true
            },
            @{
                X = 12; Width = 30; Height = 75
                HasRoof = $true; RoofType = "Pointed"
                HasFlag = $true
            },
            @{
                X = [int]($castleWidth - 42); Width = 30; Height = 75
                HasRoof = $true; RoofType = "Pointed"
                HasFlag = $false
            }
        )
        $castle.Towers = $towers
        $this.AddFlags($castle)
        $this.AddTorches($castle, 5)
    }

    hidden [void] BuildOrientalCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 140 -Maximum 200
        $castleHeight = Get-Random -Minimum 90 -Maximum 130

        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight

        $towers = @()
        for ($t = 0; $t -lt 4; $t++) {
            $towers += @{
                X = ($t * ($castleWidth / 4)) + (Get-Random -Minimum 5 -Maximum 15)
                Width = Get-Random -Minimum 28 -Maximum 40
                Height = Get-Random -Minimum 40 -Maximum 70
                HasRoof = $true
                RoofType = "Pagoda"
                HasFlag = (Get-Random -Minimum 0 -Maximum 2) -eq 1
            }
        }
        $castle.Towers = $towers
        $this.AddFlags($castle)
        $this.AddTorches($castle, 6)
    }

    hidden [void] BuildRuinsCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 120 -Maximum 180
        $castleHeight = Get-Random -Minimum 70 -Maximum 110

        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight - 20
        $castle.Y = $groundY - $castle.Height

        $towers = @()
        $towerCount = Get-Random -Minimum 2 -Maximum 4
        for ($t = 0; $t -lt $towerCount; $t++) {
            $towers += @{
                X = Get-Random -Minimum 10 -Maximum ($castleWidth - 40)
                Width = Get-Random -Minimum 25 -Maximum 38
                Height = Get-Random -Minimum 35 -Maximum 65
                HasRoof = (Get-Random -Minimum 0 -Maximum 2) -eq 1
                RoofType = "Battlement"
                IsRuin = $true
            }
        }
        $castle.Towers = $towers
        $this.AddFlags($castle)
        $this.AddTorches($castle, 2)
    }

    hidden [void] AddFlags($castle) {
        $flags = @()
        foreach ($tower in $castle.Towers) {
            if ($tower.HasFlag) {
                $flags += @{
                    X = $tower.X + ($tower.Width / 2)
                    Y = -$tower.Height - 10
                    Phase = Get-Random -Minimum 0.0 -Maximum 6.28
                    WaveOffset = 0
                    Color = $this.GetRandomFlagColor()
                }
            }
        }
        $castle.Flags = $flags
    }

    hidden [void] AddTorches($castle, [int]$count) {
        $torches = @()
        for ($i = 0; $i -lt $count; $i++) {
            $torches += @{
                X = Get-Random -Minimum 10 -Maximum ($castle.Width - 10)
                Y = Get-Random -Minimum 15 -Maximum ($castle.Height - 15)
                Phase = Get-Random -Minimum 0.0 -Maximum 6.28
                FlickerOffset = 0
                FlickerSize = 1.0
            }
        }
        $castle.Torches = $torches
    }

    hidden [System.Drawing.Color] GetRandomFlagColor() {
        $colors = @(
            [System.Drawing.Color]::FromArgb(220, 220, 50, 70),
            [System.Drawing.Color]::FromArgb(220, 50, 150, 220),
            [System.Drawing.Color]::FromArgb(220, 200, 180, 50),
            [System.Drawing.Color]::FromArgb(220, 150, 50, 200)
        )
        return $colors[(Get-Random -Minimum 0 -Maximum $colors.Count)]
    }

    # ---------- SLIDER ----------

    hidden [void] CreateCalmSlider() {
        $sliderContainer = New-Object System.Windows.Forms.Panel
        $sliderContainer.Height = 25
        $sliderContainer.Dock = "Bottom"
        $sliderContainer.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)

        $slider = New-Object System.Windows.Forms.TrackBar
        $slider.Minimum = 0
        $slider.Maximum = 100
        $slider.Value = 50
        $slider.Dock = "Fill"
        $slider.TickStyle = 'None'
        
        $self = $this
        $slider.Add_ValueChanged({
            $self.State.TargetCalm = $slider.Value / 100
        }.GetNewClosure())

        $sliderContainer.Controls.Add($slider)
        $this.Panel.Controls.Add($sliderContainer)
    }

    # ---------- EVENTS ----------

    hidden [void] SetupEvents() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderCanvas($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }

    # ---------- RENDERING ----------

    hidden [System.Drawing.Color] LerpColor([System.Drawing.Color]$a, [System.Drawing.Color]$b, [double]$t) {
        $t = [Math]::Max(0, [Math]::Min(1, $t))
        return [System.Drawing.Color]::FromArgb(
            255,
            [int]($a.R + ($b.R - $a.R) * $t),
            [int]($a.G + ($b.G - $a.G) * $t),
            [int]($a.B + ($b.B - $a.B) * $t)
        )
    }

    hidden [void] RenderCanvas([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        if ($width -le 0 -or $height -le 0) { return }

        $calm = $this.State.VisualCalm
        $groundY = [int]($height * 0.62)       

        # ---------- SKY (AGENT2 COLORS) ----------
        $skyTop = $this.LerpColor(
            [System.Drawing.Color]::FromArgb(30,60,110),
            [System.Drawing.Color]::FromArgb(140,80,30),
            $calm
        )
        $skyBottom = $this.LerpColor(
            [System.Drawing.Color]::FromArgb(10,20,40),
            [System.Drawing.Color]::FromArgb(90,50,25),
            $calm
        )

        $skyBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0,0),
            [System.Drawing.Point]::new(0,$groundY),
            $skyTop, $skyBottom
        )
        $g.FillRectangle($skyBrush, 0, 0, $width, $groundY)
        $skyBrush.Dispose()

        # ---------- DISTANT HILLS (AGENT2 STYLE) ----------
        $hillColor = $this.LerpColor(
            [System.Drawing.Color]::FromArgb(45,70,90),
            [System.Drawing.Color]::FromArgb(95,80,60),
            $calm
        )

        $hillBrush = New-Object System.Drawing.SolidBrush($hillColor)
        $hillBaseY = [int]($height * 0.58)

        $hills = @(
            @{ X = -200; W = 600; H = 120 },
            @{ X =  250; W = 700; H = 150 },
            @{ X =  750; W = 600; H = 110 }
        )

        foreach ($hill in $hills) {
            $g.FillEllipse($hillBrush, $hill.X, $hillBaseY - $hill.H, $hill.W, $hill.H * 2)
        }
        $hillBrush.Dispose()

        # ---------- GROUND (AGENT2 GRADIENT + TEXTURE) ----------
        $groundTop = $this.LerpColor(
            [System.Drawing.Color]::FromArgb(55,60,70),
            [System.Drawing.Color]::FromArgb(120,95,70),
            $calm
        )
        $groundBottom = $this.LerpColor(
            [System.Drawing.Color]::FromArgb(25,28,35),
            [System.Drawing.Color]::FromArgb(70,55,40),
            $calm
        )

        $groundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0,$groundY),
            [System.Drawing.Point]::new(0,$height),
            $groundTop, $groundBottom
        )
        $g.FillRectangle($groundBrush, 0, $groundY, $width, $height-$groundY)
        $groundBrush.Dispose()

        # Subtle terrain strata (Agent2's texture)
        for ($i = 0; $i -lt 6; $i++) {
            $layerBrush = New-Object System.Drawing.SolidBrush(
                [System.Drawing.Color]::FromArgb(10 + $i*4, 0, 0, 0)
            )
            $g.FillRectangle($layerBrush, 0, $groundY + ($i*18), $width, 3)
            $layerBrush.Dispose()
        }

        # Depth shading (Agent2's shadow effect)
        $shadeBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0,$groundY),
            [System.Drawing.Point]::new(0,$height),
            [System.Drawing.Color]::FromArgb(25,0,0,0),
            [System.Drawing.Color]::FromArgb(90,0,0,0)
        )
        $g.FillRectangle($shadeBrush, 0, $groundY, $width, $height-$groundY)
        $shadeBrush.Dispose()

        # ---------- CASTLES ----------
        foreach ($c in $this.Castles) {
            if ($c.Width -le 0) { continue }
            $this.RenderCastle($g, $c, $groundY)
        }

        # ---------- MIST (AGENT2 STYLE) ----------
        $mistAlpha = [int](60 + 90 * $calm)
        $mistBrush = New-Object System.Drawing.SolidBrush(
            [System.Drawing.Color]::FromArgb($mistAlpha, 210, 210, 220)
        )
        $g.FillEllipse($mistBrush, -150, $groundY-45, $width+300, 120)
        $mistBrush.Dispose()

        # ---------- TITLE ----------
        $titleText = "✨ WINE CASTLE PARADE ✨"
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $titleX = ($width - $titleSize.Width) / 2
        $titleY = $height - $titleSize.Height - 35

        $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 255, 240, 200))
        $g.DrawString($titleText, $titleFont, $glowBrush, $titleX-2, $titleY-2)
        $glowBrush.Dispose()
        
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 240, 180))
        $g.DrawString($titleText, $titleFont, $titleBrush, $titleX, $titleY)
        $titleFont.Dispose()
        $titleBrush.Dispose()

        # ---------- DEBUG ----------
        $debugFont = New-Object System.Drawing.Font("Consolas", 9)
        $debugBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 200, 200, 200))
        $g.DrawString(("Calm = {0:N2}" -f $calm), $debugFont, $debugBrush, 10, 10)
        $debugFont.Dispose()
        $debugBrush.Dispose()
    }

    hidden [void] RenderCastle([System.Drawing.Graphics]$g, $castle, [int]$groundY) {
        # Wall/body color (keep theme)
        $castleBrush = New-Object System.Drawing.SolidBrush($castle.Color)
        $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 0, 0, 0))

        # Universal roof color (warm brown)
        $roofBrushMain   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 120, 70, 40))   # main brown
        $roofBrushDark   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 90, 45, 25))    # darker for shading
        $roofBrushLight  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 170, 110, 70))  # lighter highlight

        # Shadow ellipse
        $g.FillEllipse($shadowBrush, [int]$castle.X, $groundY+2, [int]$castle.Width, 15)

        # Main body
        $g.FillRectangle($castleBrush, [int]$castle.X, [int]$castle.Y, [int]$castle.Width, [int]$castle.Height)

        # Render towers (with brown hats/roofs)
        foreach ($t in $castle.Towers) {
            $tx = [int]($castle.X + $t.X)
            $tw = [int]$t.Width
            $th = [int]$t.Height
            $ty = [int]($castle.Y - $th + 25)

            # Tower body
            if ($t.IsRound) {
                $g.FillEllipse($castleBrush, $tx, $ty, $tw, $th)
            } else {
                $g.FillRectangle($castleBrush, $tx, $ty, $tw, $th)
            }

            # Roof / top – always some shade of brown
            if ($t.HasRoof) {
                switch ($t.RoofType) {
                    "Pointed" {
                        $roofPoints = [System.Drawing.Point[]]@(
                            [System.Drawing.Point]::new($tx, $ty),
                            [System.Drawing.Point]::new($tx + [int]($tw/2), $ty - 20),
                            [System.Drawing.Point]::new($tx + $tw, $ty)
                        )
                        # main brown roof
                        $g.FillPolygon($roofBrushMain, $roofPoints)
                        # dark ridge for depth
                        $ridgePen = New-Object System.Drawing.Pen($roofBrushDark.Color, 2)
                        $g.DrawLine($ridgePen, $tx + [int]($tw/2), $ty - 20, $tx + [int]($tw/2), $ty)
                        $ridgePen.Dispose()
                    }
                    "Conical" {
                        $roofPoints = [System.Drawing.Point[]]@(
                            [System.Drawing.Point]::new($tx, $ty),
                            [System.Drawing.Point]::new($tx + [int]($tw/2), $ty - 25),
                            [System.Drawing.Point]::new($tx + $tw, $ty)
                        )
                        $g.FillPolygon($roofBrushMain, $roofPoints)
                        # highlight on sun side
                        $highlightPen = New-Object System.Drawing.Pen($roofBrushLight.Color, 2)
                        $g.DrawLine($highlightPen, $tx + [int]($tw*0.2), $ty - 10, $tx + [int]($tw*0.7), $ty - 20)
                        $highlightPen.Dispose()
                    }
                     "Dome" {
                        # lower dome (darker brown)
                        $g.FillEllipse($roofBrushDark, $tx, $ty-10, $tw, 24)
                        # little highlight cap
                        $g.FillEllipse($roofBrushLight, $tx+4, $ty-14, $tw-8, 14)
                    }   
                    "Spire" {
                        $roofPoints = [System.Drawing.Point[]]@(
                            [System.Drawing.Point]::new($tx + 5, $ty),
                            [System.Drawing.Point]::new($tx + [int]($tw/2), $ty - 35),
                            [System.Drawing.Point]::new($tx + $tw - 5, $ty)
                        )
                        $g.FillPolygon($roofBrushMain, $roofPoints)
                        $ridgePen = New-Object System.Drawing.Pen($roofBrushDark.Color, 2)
                        $g.DrawLine($ridgePen, $tx + [int]($tw/2), $ty - 35, $tx + [int]($tw/2), $ty)
                        $ridgePen.Dispose()
                    }
                    "Battlement" {
                        # battlements as brown bricks
                        $battlementPen = New-Object System.Drawing.Pen($roofBrushMain.Color, 3)
                        for ($b = 0; $b -lt $tw; $b += 8) {
                            $g.DrawLine($battlementPen, $tx+$b, $ty, $tx+$b, $ty-6)
                        }
                        $battlementPen.Dispose()
                        # thin darker cap
                        $capPen = New-Object System.Drawing.Pen($roofBrushDark.Color, 2)
                        $g.DrawLine($capPen, $tx, $ty-1, $tx+$tw, $ty-1)
                        $capPen.Dispose()
                    }
                    "Spiral" {
                    # stack of brown donuts, getting slightly darker upwards
                        for ($s = 0; $s -lt 5; $s++) {
                            $sy = $ty - ($s * 8)
                    
                            if ($s -lt 2) {
                                # lower rings: main brown
                                $g.FillEllipse($roofBrushMain, $tx-2, $sy, $tw+4, 10)
                            } else {
                                # upper rings: darker brown
                                $g.FillEllipse($roofBrushDark, $tx-2, $sy, $tw+4, 10)
                            }
                        }
                    }

                    "Pagoda" {
                        # two‑tier brown pagoda roof
                        $tierHeight = 9
                        $tier1 = [System.Drawing.Rectangle]::new($tx-4, $ty-2, $tw+8, $tierHeight)
                        $tier2 = [System.Drawing.Rectangle]::new($tx-2, $ty-2-$tierHeight, $tw+4, $tierHeight)

                        $g.FillRectangle($roofBrushMain, $tier1)
                        $g.FillRectangle($roofBrushDark,  $tier2)

                        # slight upward tips
                        $tipPen = New-Object System.Drawing.Pen($roofBrushLight.Color, 2)
                        $g.DrawLine($tipPen, $tier1.X,                $tier1.Y+1, $tier1.X+5,             $tier1.Y-3)
                        $g.DrawLine($tipPen, $tier1.X+$tier1.Width-5, $tier1.Y-3, $tier1.X+$tier1.Width,  $tier1.Y+1)
                        $tipPen.Dispose()
                    }
                    "Broken" {
                        # ruins: jagged brown roof fragments
                        $segW = [math]::Max(6, [int]($tw / 4))
                        for ($s = 0; $s -lt $tw; $s += $segW) {
                            if ((Get-Random -Minimum 0 -Maximum 3) -eq 0) { continue }  # missing segment
                            $rx = $tx + $s
                            $rTop = $ty - (Get-Random -Minimum 3 -Maximum 9)
                            $roofPoints = [System.Drawing.Point[]]@(
                                [System.Drawing.Point]::new($rx, $ty),
                                [System.Drawing.Point]::new($rx + $segW, $ty),
                                [System.Drawing.Point]::new($rx + [int]($segW/2), $rTop)
                            )
                            $g.FillPolygon($roofBrushDark, $roofPoints)
                        }
                    }
                    default {
                        # fallback: simple brown cap
                        $g.FillRectangle($roofBrushMain, $tx, $ty-4, $tw, 8)
                    }
                }
            }

            # Rose window for cathedral
            if ($t.HasRoseWindow) {
                $rwSize = [int]($tw * 0.6)
                $rwX = $tx + [int](($tw - $rwSize) / 2)
                $rwY = $ty + [int]($th * 0.3)
                $rwBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 255, 100, 150))
                $g.FillEllipse($rwBrush, $rwX, $rwY, $rwSize, $rwSize)
                $rwBrush.Dispose()
            }

            # Balconies for special towers
            if ($t.IsSpecial) {
                $balconyY = $ty + [int]($th * 0.4)
                $balconyBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, 200, 200, 200))
                $g.FillRectangle($balconyBrush, $tx-3, $balconyY, $tw+6, 4)
                $balconyBrush.Dispose()
            }
        }

        $castleBrush.Dispose()
        $shadowBrush.Dispose()
        $roofBrushMain.Dispose()
        $roofBrushDark.Dispose()
        $roofBrushLight.Dispose()

        # Windows (unchanged)
        $windowCount = Get-Random -Minimum 3 -Maximum 7
        $windowBrush = New-Object System.Drawing.SolidBrush($castle.WindowColor)
        for ($w = 0; $w -lt $windowCount; $w++) {
            $wx = [int]($castle.X + (Get-Random -Minimum 15 -Maximum ($castle.Width - 20)))
            $wy = [int]($castle.Y + (Get-Random -Minimum 20 -Maximum ($castle.Height - 25)))
            $g.FillRectangle($windowBrush, $wx, $wy, 5, 8)
        }
        $windowBrush.Dispose()

        # Flags
        foreach ($flag in $castle.Flags) {
            $fx = [int]($castle.X + $flag.X + $flag.WaveOffset)
            $fy = [int]($castle.Y + $flag.Y)
        
            $polePen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(150, 100, 100, 100), 2)
            $g.DrawLine($polePen, $fx, $fy, $fx, $fy-20)
            $polePen.Dispose()
        
            $flagBrush = New-Object Drawing.SolidBrush($flag.Color)
            $flagPoints = [Drawing.Point[]]@(
                [Drawing.Point]::new($fx, $fy-20),
                [Drawing.Point]::new($fx+12, $fy-15),
                [Drawing.Point]::new($fx, $fy-10)
            )
            $g.FillPolygon($flagBrush, $flagPoints)
            $flagBrush.Dispose()
        }
    }
}

function Stop-Show71 {
    Write-Host "🛑 [Show71] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show71")) {
        $Global:ShowManager.Shows["show71"].Stop()
    }
}

Write-Host "✅ Show71 - Castle Parade (GM Architecture) loaded!" -ForegroundColor Green