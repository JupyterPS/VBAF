# ===============================
# Show20 — Wine Castles ULTIMATE (GM v3)
# Wine Company - Full Vineyard Animation
# ===============================

Write-Host "`n=> _____ HQshow20 (Wine Castles ULTIMATE) ___________ <=`n" -ForegroundColor Cyan

class Show20 : BaseShow {
    hidden [System.Collections.ArrayList] $Castles
    hidden [hashtable] $State

    Show20([System.Windows.Forms.Panel]$panel) : base("show20", $panel) {
        $this.Castles = [System.Collections.ArrayList]::new()
        $this.State = @{
            TickCount = 0
            Stars = @()
        }
        $this.InitializeCastles()
        $this.InitializeStars()
    }

    [void] OnStart() {
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(8, 6, 15)

        $prop = $this.Panel.GetType().GetProperty(
            "DoubleBuffered",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }

        $this.SetupEvents()
        Write-Host "  ✅ [Show20] Wine Castles ULTIMATE started" -ForegroundColor Magenta
    }

    [void] OnUpdate() {
        if (-not $this.Panel.Visible -or $this.Panel.Width -le 0 -or $this.Panel.Height -le 0) { return }

        $this.State.TickCount++

        foreach ($c in $this.Castles) {
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

        # Twinkle stars
        foreach ($star in $this.State.Stars) {
            if ((Get-Random -Minimum 0 -Maximum 100) -lt 3) {
                $star.Brightness = Get-Random -Minimum 50 -Maximum 255
            }
        }

        # Recycle castles
        $width = $this.Panel.Width
        for ($i = 0; $i -lt $this.Castles.Count; $i++) {
            $c = $this.Castles[$i]
            if ($c.X + $c.Width -lt -50) {
                $this.RandomizeCastle($c, $width)
            }
        }

        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        $this.Panel.Controls.Clear()
        $this.Castles.Clear()
        Write-Host "  🛑 [Show20] Stopped" -ForegroundColor Yellow
    }

        # ---------- INITIALIZATION ----------

    hidden [void] InitializeStars() {
        $this.State.Stars = @()
        for ($i = 0; $i -lt 80; $i++) {
            $this.State.Stars += @{
                X = Get-Random -Minimum 0 -Maximum 1200
                Y = Get-Random -Minimum 0 -Maximum 250
                Brightness = Get-Random -Minimum 100 -Maximum 255
                Size = Get-Random -Minimum 1 -Maximum 3
            }
        }
    }

    hidden [void] InitializeCastles() {
        $this.Castles.Clear()
        $startX = 0
        for ($i = 0; $i -lt 7; $i++) {
            $castle = @{
                X      = $startX
                Y      = 0
                Width  = 0
                Height = 0
                Speed  = 0
                Type   = ""
                Towers = @()
                Flags  = @()
                Torches = @()
                Color  = [System.Drawing.Color]::White
                WindowColor = [System.Drawing.Color]::White
                ShadowIntensity = 0
            }
            $this.Castles.Add($castle) | Out-Null
            $startX += 250
        }

        $width = $this.Panel.Width
        foreach ($c in $this.Castles) {
            $this.RandomizeCastle($c, $width)
        }
    }

    hidden [void] RandomizeCastle($castle, [int]$canvasWidth) {
        $groundY = [math]::Max(260, [int]($this.Panel.Height * 0.6))

        # Pick a random castle type
        $types = @("Gothic","FairyTale","Gothic","Fortress","Palace","Wizard","FairyTale","Cathedral","Gothic","Oriental","Ruins")      
        $castle.Type = $types[(Get-Random -Minimum 0 -Maximum $types.Count)]

        $castle.X = $canvasWidth + (Get-Random -Minimum 60 -Maximum 350)
        $castle.Speed = (Get-Random -Minimum 3 -Maximum 9) / 10.0
        $castle.ShadowIntensity = Get-Random -Minimum 40 -Maximum 80

        # Enhanced color themes with wine-inspired colors
        $colorThemes = @(
            @{ Castle = [System.Drawing.Color]::FromArgb(140, 230, 230, 240); Window = [System.Drawing.Color]::FromArgb(220, 255, 240, 180); Name = "Moonstone" },
            @{ Castle = [System.Drawing.Color]::FromArgb(120, 180, 100, 130); Window = [System.Drawing.Color]::FromArgb(200, 255, 200, 120); Name = "Emerald" },
            @{ Castle = [System.Drawing.Color]::FromArgb(130, 150, 120, 160); Window = [System.Drawing.Color]::FromArgb(230, 255, 220, 180); Name = "Amethyst" },
            @{ Castle = [System.Drawing.Color]::FromArgb(110, 200, 160, 140); Window = [System.Drawing.Color]::FromArgb(200, 255, 210, 140); Name = "Sandstone" },
            @{ Castle = [System.Drawing.Color]::FromArgb(100, 120, 80, 110); Window = [System.Drawing.Color]::FromArgb(240, 200, 150, 255); Name = "Obsidian" },
            @{ Castle = [System.Drawing.Color]::FromArgb(140, 200, 140, 170); Window = [System.Drawing.Color]::FromArgb(200, 180, 220, 255); Name = "Sapphire" },
            @{ Castle = [System.Drawing.Color]::FromArgb(120, 220, 180, 160); Window = [System.Drawing.Color]::FromArgb(255, 255, 200, 150); Name = "Coral" }
        )
        $theme = $colorThemes[(Get-Random -Minimum 0 -Maximum $colorThemes.Count)]
        $castle.Color = $theme.Castle
        $castle.WindowColor = $theme.Window
        $castle.ThemeName = $theme.Name

        

        # Build castle based on type
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

    #$roofPool = @("Pointed","Spire","Battlement","Conical","Spiral","Dome","Pagoda","Broken")
       
    <#
    "Gothic",     tårne (spids hat)         "Pointed"       
    "FairyTale",  (spir)                    "Spire"
    "Fortress",   fortmure (skydeskår)      "Battlement" 
    "Palace",     spir (fjer i hatten)      "Conical"                       
    "Wizard",     skruelåg (grimme)         "Spiral"
    "Cathedral",  prop med isse             "Dome"
    "Oriental",   tag på prop               "Pagoda"
    "Ruins"       Samme som fortmure        "Broken"    
#>

    hidden [void] BuildGothicCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 110 -Maximum 170
        $castleHeight = Get-Random -Minimum 95 -Maximum 140

        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight

        # Roof pool for Gothic
        $roofPool = @("Pointed","Spire","Battlement","Conical","Pagoda","Spire","Broken")              
            
        $towers = @()
        for ($t = 0; $t -lt 4; $t++) {
            $tx = ($t * ($castleWidth / 4)) + (Get-Random -Minimum 0 -Maximum 12)
            $tw = Get-Random -Minimum 20 -Maximum 30
            $th = Get-Random -Minimum 55 -Maximum 100

            $roofType = $roofPool | Get-Random

            $towers += @{
                X       = $tx; Width = $tw; Height = $th
                HasRoof = $true; RoofType = $roofType
                HasFlag = (Get-Random -Minimum 0 -Maximum 2) -eq 1
                HasArch = $true
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

        #$roofPool = @("Conical","Pointed","Spiral")
        $roofPool = @("Pointed","Spire","Battlement","Conical","Pagoda","Spire","Broken")         

        $towers = @()
        $towerCount = Get-Random -Minimum 4 -Maximum 6
        for ($t = 0; $t -lt $towerCount; $t++) {
            $tx = Get-Random -Minimum 5 -Maximum ($castleWidth - 35)
            $tw = Get-Random -Minimum 24 -Maximum 34
            $th = Get-Random -Minimum 45 -Maximum 75

            $roofType = $roofPool | Get-Random

            $towers += @{
                X       = $tx; Width = $tw; Height = $th
                HasRoof = $true; RoofType = $roofType
                IsRound = $true
                HasFlag = $true
                Sparkle = $true
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

        # Fortress: @("Pointed","Spire","Battlement","Conical","Pagoda","Spire","Broken") 
        $roofPool = @("Pointed","Spire","Battlement","Conical","Pagoda","Spire","Broken")         

        $towers = @()
        for ($t = 0; $t -lt 5; $t++) {
            $tx = ($t * ($castleWidth / 5)) + (Get-Random -Minimum 0 -Maximum 8)
            $tw = Get-Random -Minimum 30 -Maximum 42
            $th = Get-Random -Minimum 40 -Maximum 65

            $roofType = $roofPool | Get-Random

            $towers += @{
                X       = $tx; Width = $tw; Height = $th
                HasRoof = $true; RoofType = $roofType
                HasFlag = (Get-Random -Minimum 0 -Maximum 3) -eq 1
                Thick   = $true
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

        $roofPool = @("Pointed","Spire","Battlement","Conical","Pagoda","Spire","Broken")               

        $towers = @()
        for ($t = 0; $t -lt 5; $t++) {
            $tx = Get-Random -Minimum 10 -Maximum ($castleWidth - 45)
            $tw = Get-Random -Minimum 32 -Maximum 48
            $th = Get-Random -Minimum 35 -Maximum 60

            $roofType = $roofPool | Get-Random

            $towers += @{
                X       = $tx; Width = $tw; Height = $th
                HasRoof = $true; RoofType = $roofType
                HasFlag = (Get-Random -Minimum 0 -Maximum 2) -eq 1
                Ornate  = $true
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

        $roofPool = @("Pointed","Spire","Battlement","Conical","Pagoda","Spire","Broken")   
        
        $roofType = $roofPool | Get-Random      

        $towers = @(
            @{
                X       = [int]($castleWidth / 3); Width = 38; Height = 150
                HasRoof = $true; RoofType = $roofType                
                HasFlag = $true
                IsSpecial = $true
                MagicGlow = $true
            }
        )

        $roofType = $roofPool | Get-Random 

        $towers += @{
            X       = [int]($castleWidth * 0.7); Width = 24; Height = 55
            HasRoof = $true; RoofType = $roofType
            HasFlag = $true
        }
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

        $roofPool = @("Pointed","Spire","Battlement","Conical","Pagoda","Spire","Broken")                  

        $centerRoof = $roofPool | Get-Random
        $sideRoof   = $roofPool | Get-Random

        $towers = @(
            @{
                X = [int]($castleWidth / 2 - 22); Width = 44; Height = 120
                HasRoof = $true; RoofType = $centerRoof
                HasFlag = $true
                HasRoseWindow = $true
                Holy = $true
            },
            @{
                X = 12; Width = 30; Height = 75
                HasRoof = $true; RoofType = $sideRoof
                HasFlag = $false
            },
            @{
                X = [int]($castleWidth - 42); Width = 30; Height = 75
                HasRoof = $true; RoofType = $centerRoof
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

        $roofPool = @("Pointed","Spire","Battlement","Conical","Pagoda","Broken")               

        $towers = @()
        for ($t = 0; $t -lt 4; $t++) {
            $tx = ($t * ($castleWidth / 4)) + (Get-Random -Minimum 5 -Maximum 15)
            $tw = Get-Random -Minimum 28 -Maximum 40
            $th = Get-Random -Minimum 40 -Maximum 70

            $roofType = $roofPool | Get-Random

            $towers += @{
                X       = $tx; Width = $tw; Height = $th
                HasRoof = $true; RoofType = $roofType
                HasFlag = (Get-Random -Minimum 0 -Maximum 2) -eq 1
                Oriental = $true
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

        $roofPool = @("Pointed","Spire","Battlement","Conical","Pagoda","Broken")   

        $towers = @()
        $towerCount = Get-Random -Minimum 2 -Maximum 4
        for ($t = 0; $t -lt $towerCount; $t++) {
            $tx = Get-Random -Minimum 10 -Maximum ($castleWidth - 40)
            $tw = Get-Random -Minimum 25 -Maximum 38
            $th = Get-Random -Minimum 35 -Maximum 65

            $roofType = $roofPool | Get-Random

            $towers += @{
                X       = $tx; Width = $tw; Height = $th                
                HasRoof = $true; RoofType = $roofType
                IsRuin   = $true
                Crumbled = $true
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
            [System.Drawing.Color]::FromArgb(220, 150, 50, 200),
            [System.Drawing.Color]::FromArgb(220, 50, 200, 120)
        )
        return $colors[(Get-Random -Minimum 0 -Maximum $colors.Count)]
    }

    hidden [void] SetupEvents() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderCanvas($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }

    # ---------- RENDERING ----------

    hidden [void] RenderCanvas([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        if ($width -le 0 -or $height -le 0) { return }

        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        # Sky gradient with deeper colors
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0,0),
            [System.Drawing.Point]::new(0,$height),
            [System.Drawing.Color]::FromArgb(25, 15, 45),
            [System.Drawing.Color]::FromArgb(8, 5, 18)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()

        # Twinkling stars
        foreach ($star in $this.State.Stars) {
            $starBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($star.Brightness, 255, 255, 230))
            $g.FillEllipse($starBrush, $star.X, $star.Y, $star.Size, $star.Size)
            $starBrush.Dispose()
        }

        # Moon
        $moonBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new($width-150, 50),
            [System.Drawing.Point]::new($width-100, 100),
            [System.Drawing.Color]::FromArgb(220, 255, 250, 230),
            [System.Drawing.Color]::FromArgb(150, 230, 230, 240)
        )
        $g.FillEllipse($moonBrush, $width-150, 50, 60, 60)
        $moonBrush.Dispose()

        $groundY = [math]::Max(260, [int]($height * 0.6))

        # Multiple layer hills for depth
        $hill1Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 40, 30, 60))
        $g.FillEllipse($hill1Brush, -300, $groundY-120, $width+600, 200)
        $hill1Brush.Dispose()

        $hill2Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 50, 40, 70))
        $g.FillEllipse($hill2Brush, -100, $groundY-80, $width+200, 150)
        $hill2Brush.Dispose()

        # Layered mist
        $mist1Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 200, 200, 220))
        $g.FillRectangle($mist1Brush, 0, $groundY-30, $width, 50)
        $mist1Brush.Dispose()

        $mist2Brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 180, 180, 200))
        $g.FillRectangle($mist2Brush, 0, $groundY-10, $width, 30)
        $mist2Brush.Dispose()

        # Textured ground
        $groundGradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, $groundY),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(90, 30, 20),
            [System.Drawing.Color]::FromArgb(60, 20, 15)
        )
        $g.FillRectangle($groundGradient, 0, $groundY, $width, $height-$groundY)
        $groundGradient.Dispose()

        # Ground texture lines
        $grassPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(30, 40, 40, 30), 1)
        for ($gx = 0; $gx -lt $width; $gx += 25) {
            $gy = $groundY + (Get-Random -Minimum 0 -Maximum 8)
            $g.DrawLine($grassPen, $gx, $gy, $gx+15, $gy+2)
        }
        $grassPen.Dispose()

        # Render castles
        foreach ($c in $this.Castles) {
            if ($c.Width -le 0) { continue }
            $this.RenderCastle($g, $c, $groundY)
        }

        # Enhanced title with glow effect (bottom center)
        $titleText = "✨ WINE CASTLE PARADE ✨"
        $titleFont  = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)

        # Measure text to center it
        $titleSize  = $g.MeasureString($titleText, $titleFont)
        $titleX     = ($width  - $titleSize.Width) / 2
        $titleY     = $height - $titleSize.Height - 10   # 10px from bottom

        $glowBrush  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 255, 240, 200))
        $g.DrawString($titleText, $titleFont, $glowBrush, $titleX-2, $titleY-2)
        $glowBrush.Dispose()
        
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 240, 180))
        $g.DrawString($titleText, $titleFont, $titleBrush, $titleX, $titleY)
        $titleFont.Dispose()
        $titleBrush.Dispose()

        # FPS / build label at top-left
        $smallFont = New-Object System.Drawing.Font("Segoe UI", 9)
        $infoBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 200, 200, 200))
        $g.DrawString("Ultimate Edition v3.0", $smallFont, $infoBrush, 8, 8)
        $smallFont.Dispose()
        $infoBrush.Dispose()
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

        # Flags (unchanged)
        $flagBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 220, 50, 70))
        foreach ($flag in $castle.Flags) {
            $fx = [int]($castle.X + $flag.X + $flag.WaveOffset)
            $fy = [int]($castle.Y + $flag.Y)

            $polePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 100, 100, 100), 2)
            $g.DrawLine($polePen, $fx, $fy, $fx, $fy-20)
            $polePen.Dispose()

            $flagPoints = [System.Drawing.Point[]]@(
                [System.Drawing.Point]::new($fx, $fy-20),
                [System.Drawing.Point]::new($fx+12, $fy-15),
                [System.Drawing.Point]::new($fx, $fy-10)
            )
            $g.FillPolygon($flagBrush, $flagPoints)
        }
        $flagBrush.Dispose()
    }
}

function Stop-Show20 {
    Write-Host "🛑 [Show20] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show20")) {
        $Global:ShowManager.Shows["show20"].Stop()
    }
}

Write-Host "✅ Show20 - Wine Castles ENHANCED (v2.0) loaded!" -ForegroundColor Green




[void]$form.ShowDialog()