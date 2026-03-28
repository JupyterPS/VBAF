Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -------------------------------
# FORM
# -------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Width = 1000
$form.Height = 420
$form.Text = "Castle Parade — Integrated with Calm World"

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = 'Fill'
$panel.BackColor = [Drawing.Color]::Black
$form.Controls.Add($panel)

# Enable DoubleBuffering
$prop = $panel.GetType().GetProperty("DoubleBuffered",[System.Reflection.BindingFlags] "Instance,NonPublic")
$prop.SetValue($panel,$true,$null)

# -------------------------------
# STATE
# -------------------------------
$script:TargetCalm = 0.5
$script:VisualCalm = 0.5
$script:TickCount = 0

# Stars
$script:Stars = @()
for ($i = 0; $i -lt 80; $i++) {
    $script:Stars += @{
        X = Get-Random -Minimum 0 -Maximum 1200
        Y = Get-Random -Minimum 0 -Maximum 250
        Brightness = Get-Random -Minimum 100 -Maximum 255
        Size = Get-Random -Minimum 1 -Maximum 3
    }
}

# Castles with full Show20 structure
$script:Castles = @()
for ($i = 0; $i -lt 8; $i++) {
    $castle = @{
        X = ($i * 250)
        Y = 0
        Width = 0
        Height = 0
        Speed = (Get-Random -Minimum 3 -Maximum 9) / 10.0
        Type = ""
        Towers = @()
        Flags = @()
        Torches = @()
        Color = [Drawing.Color]::White
        WindowColor = [Drawing.Color]::White
        ThemeName = ""
    }
    $script:Castles += $castle
}

# -------------------------------
# CASTLE BUILDER FUNCTIONS
# -------------------------------
function Initialize-Castle($castle, $canvasWidth, $groundY) {
    # Weighted types - FairyTale appears more often
    $types = @(
        "Gothic", "FairyTale",
        "Fortress", "Palace",  
        "Wizard", "Cathedral", 
         "Oriental", "Ruins"
    )
    $castle.Type = $types[(Get-Random -Minimum 0 -Maximum $types.Count)]
    
    $castle.X = $canvasWidth + (Get-Random -Minimum 60 -Maximum 350)
    
    # Color themes
    $colorThemes = @(
        @{ Castle = [Drawing.Color]::FromArgb(140, 230, 230, 240); Window = [Drawing.Color]::FromArgb(220, 255, 240, 180); Name = "Moonstone" },
        @{ Castle = [Drawing.Color]::FromArgb(120, 180, 100, 130); Window = [Drawing.Color]::FromArgb(200, 255, 200, 120); Name = "Emerald" },
        @{ Castle = [Drawing.Color]::FromArgb(130, 150, 120, 160); Window = [Drawing.Color]::FromArgb(230, 255, 220, 180); Name = "Amethyst" },
        @{ Castle = [Drawing.Color]::FromArgb(110, 200, 160, 140); Window = [Drawing.Color]::FromArgb(200, 255, 210, 140); Name = "Sandstone" }
    )
    $theme = $colorThemes[(Get-Random -Minimum 0 -Maximum $colorThemes.Count)]
    $castle.Color = $theme.Castle
    $castle.WindowColor = $theme.Window
    $castle.ThemeName = $theme.Name
    
    # Build based on type
    switch ($castle.Type) {
        "FairyTale" { Build-FairyTaleCastle $castle $groundY }
        "Gothic"    { Build-GothicCastle $castle $groundY }
        "Fortress"  { Build-FortressCastle $castle $groundY }
        "Palace"    { Build-PalaceCastle $castle $groundY }
        "Wizard"    { Build-WizardCastle $castle $groundY }
        "Cathedral" { Build-CathedralCastle $castle $groundY }
        "Oriental"  { Build-OrientalCastle $castle $groundY }
        "Ruins"     { Build-RuinsCastle $castle $groundY }
    }
}

function Build-FairyTaleCastle($castle, $groundY) {
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
    Add-CastleFlags $castle
    Add-CastleTorches $castle 6
}

function Build-GothicCastle($castle, $groundY) {
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
    Add-CastleFlags $castle
    Add-CastleTorches $castle 4
}

function Build-FortressCastle($castle, $groundY) {
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
    Add-CastleFlags $castle
    Add-CastleTorches $castle 8
}

function Build-PalaceCastle($castle, $groundY) {
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
            RoofType = "Dome"
            HasFlag = (Get-Random -Minimum 0 -Maximum 2) -eq 1
        }
    }
    $castle.Towers = $towers
    Add-CastleFlags $castle
    Add-CastleTorches $castle 7
}

function Build-WizardCastle($castle, $groundY) {
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
    Add-CastleFlags $castle
    Add-CastleTorches $castle 3
}

function Build-CathedralCastle($castle, [int]$groundY) {
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
                Holy = $true
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
        Add-CastleFlags $castle
        Add-CastleTorches $castle 5
    }

function Build-OrientalCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 140 -Maximum 200
        $castleHeight = Get-Random -Minimum 90 -Maximum 130

        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight
        $castle.Y = $groundY - $castleHeight

        $towers = @()
        for ($t = 0; $t -lt 4; $t++) {
            $tx = ($t * ($castleWidth / 4)) + (Get-Random -Minimum 5 -Maximum 15)
            $tw = Get-Random -Minimum 28 -Maximum 40
            $th = Get-Random -Minimum 40 -Maximum 70
            
            $towers += @{
                X = $tx; Width = $tw; Height = $th
                HasRoof = $true; RoofType = "Pagoda"
                HasFlag = (Get-Random -Minimum 0 -Maximum 2) -eq 1
                Oriental = $true
            }
        }
        $castle.Towers = $towers
        Add-CastleFlags $castle
        Add-CastleTorches $castle 6
    }

function Build-RuinsCastle($castle, [int]$groundY) {
        $castleWidth  = Get-Random -Minimum 120 -Maximum 180
        $castleHeight = Get-Random -Minimum 70 -Maximum 110

        $castle.Width  = $castleWidth
        $castle.Height = $castleHeight - 20
        $castle.Y = $groundY - $castle.Height

        $towers = @()
        $towerCount = Get-Random -Minimum 2 -Maximum 4
        for ($t = 0; $t -lt $towerCount; $t++) {
            $tx = Get-Random -Minimum 10 -Maximum ($castleWidth - 40)
            $tw = Get-Random -Minimum 25 -Maximum 38
            $th = Get-Random -Minimum 35 -Maximum 65
            
            $towers += @{
                X = $tx; Width = $tw; Height = $th
                HasRoof = (Get-Random -Minimum 0 -Maximum 2) -eq 1
                RoofType = "Battlement"
                IsRuin = $true
                Crumbled = $true
            }
        }
        $castle.Towers = $towers
        Add-CastleFlags $castle
        Add-CastleTorches $castle 2
    }

function Add-CastleFlags($castle) {
    $flags = @()
    foreach ($tower in $castle.Towers) {
        if ($tower.HasFlag) {
            $flags += @{
                X = $tower.X + ($tower.Width / 2)
                Y = -$tower.Height - 10
                Phase = Get-Random -Minimum 0.0 -Maximum 6.28
                WaveOffset = 0
                Color = Get-RandomFlagColor
            }
        }
    }
    $castle.Flags = $flags
}

function Add-CastleTorches($castle, $count) {
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

function Get-RandomFlagColor {
    $colors = @(
        [Drawing.Color]::FromArgb(220, 220, 50, 70),
        [Drawing.Color]::FromArgb(220, 50, 150, 220),
        [Drawing.Color]::FromArgb(220, 200, 180, 50),
        [Drawing.Color]::FromArgb(220, 150, 50, 200)
    )
    return $colors[(Get-Random -Minimum 0 -Maximum $colors.Count)]
}

# Initialize all castles
$w = 1000
$h = 420
$groundY = [int]($h * 0.65)
foreach ($c in $script:Castles) {
    Initialize-Castle $c $w $groundY
}

# -------------------------------
# SLIDER
# -------------------------------
$slider = New-Object System.Windows.Forms.TrackBar
$slider.Minimum = 0
$slider.Maximum = 100
$slider.Value = 50
$slider.Dock = "Bottom"
$slider.TickStyle = 'None'
$panel.Controls.Add($slider)

$slider.Add_ValueChanged({ $script:TargetCalm = $slider.Value / 100 })

# -------------------------------
# HELPERS
# -------------------------------
function LerpColor($a,$b,$t) {
    $t = [Math]::Max(0,[Math]::Min(1,$t))
    [Drawing.Color]::FromArgb(
        255,
        [int]($a.R + ($b.R - $a.R) * $t),
        [int]($a.G + ($b.G - $a.G) * $t),
        [int]($a.B + ($b.B - $a.B) * $t)
    )
}

# -------------------------------
# PAINT
# -------------------------------
$panel.Add_Paint({
    param($s,$e)

    $script:TickCount++
    $script:VisualCalm += ($script:TargetCalm - $script:VisualCalm) * 0.03
    $calm = $script:VisualCalm

    $w = $s.Width
    $h = $s.Height
    $groundY = [int]($h * 0.65)

    $e.Graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # ---------- SKY ----------
    $skyTop = LerpColor ([Drawing.Color]::FromArgb(25, 15, 45)) ([Drawing.Color]::FromArgb(140,80,30)) $calm
    $skyBottom = LerpColor ([Drawing.Color]::FromArgb(8, 5, 18)) ([Drawing.Color]::FromArgb(90,50,25)) $calm
    $skyBrush = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0,0),(New-Object Drawing.Point 0,$h),$skyTop,$skyBottom
    $e.Graphics.FillRectangle($skyBrush,0,0,$w,$h)
    $skyBrush.Dispose()

    # ---------- STARS ----------
    foreach ($star in $script:Stars) {
        if ((Get-Random -Minimum 0 -Maximum 100) -lt 3) {
            $star.Brightness = Get-Random -Minimum 50 -Maximum 255
        }
        $starBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb($star.Brightness, 255, 255, 230))
        $e.Graphics.FillEllipse($starBrush, $star.X, $star.Y, $star.Size, $star.Size)
        $starBrush.Dispose()
    }

    # ---------- MOON ----------
    $moonBrush = New-Object Drawing.Drawing2D.LinearGradientBrush(
        [Drawing.Point]::new($w-150, 50),
        [Drawing.Point]::new($w-100, 100),
        [Drawing.Color]::FromArgb(220, 255, 250, 230),
        [Drawing.Color]::FromArgb(150, 230, 230, 240)
    )
    $e.Graphics.FillEllipse($moonBrush, $w-150, 50, 60, 60)
    $moonBrush.Dispose()

    # ---------- HILLS ----------
    $hillColor = LerpColor ([Drawing.Color]::FromArgb(30, 40, 30, 60)) ([Drawing.Color]::FromArgb(90,80,60)) $calm
    $hillBrush = New-Object Drawing.SolidBrush $hillColor
    $e.Graphics.FillEllipse($hillBrush, -300, $groundY-120, $w+600, 200)
    $hillBrush.Dispose()

    # ---------- GROUND ----------
    $groundTop = LerpColor ([Drawing.Color]::FromArgb(90, 30, 20)) ([Drawing.Color]::FromArgb(120,95,70)) $calm
    $groundBottom = LerpColor ([Drawing.Color]::FromArgb(60, 20, 15)) ([Drawing.Color]::FromArgb(70,55,40)) $calm
    $groundBrush = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0,$groundY),(New-Object Drawing.Point 0,$h),$groundTop,$groundBottom
    $e.Graphics.FillRectangle($groundBrush,0,$groundY,$w,$h-$groundY)
    $groundBrush.Dispose()

    # ---------- CASTLES ----------
    foreach ($c in $script:Castles) {
        # Animate movement
        $c.X -= $c.Speed
        
        # Animate flags
        foreach ($flag in $c.Flags) {
            $flag.WaveOffset = [Math]::Sin($script:TickCount * 0.15 + $flag.Phase) * 3
        }
        
        # Animate torches
        foreach ($torch in $c.Torches) {
            $torch.FlickerOffset = [Math]::Sin($script:TickCount * 0.3 + $torch.Phase) * 2
            $torch.FlickerSize = 1 + [Math]::Abs([Math]::Sin($script:TickCount * 0.25 + $torch.Phase)) * 0.5
        }
        
        # Recycle castle
        if ($c.X + $c.Width -lt -50) {
            Initialize-Castle $c $w $groundY
        }
        
        # Render castle
        Render-Castle $e.Graphics $c $groundY
    }

    # ---------- MIST ----------
    $mistAlpha = [int](20 + 35 * $calm)
    $mistBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb($mistAlpha,200,200,220))
    $e.Graphics.FillRectangle($mistBrush, 0, $groundY-30, $w, 50)
    $mistBrush.Dispose()

    # ---------- TITLE ----------
    $titleText = "✨ WINE CASTLE PARADE ✨"
    $titleFont = New-Object Drawing.Font("Segoe UI", 14, [Drawing.FontStyle]::Bold)
    $titleSize = $e.Graphics.MeasureString($titleText, $titleFont)
    $titleX = ($w - $titleSize.Width) / 2
    $titleY = $h - $titleSize.Height - 30

    $glowBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(100, 255, 240, 200))
    $e.Graphics.DrawString($titleText, $titleFont, $glowBrush, $titleX-2, $titleY-2)
    $glowBrush.Dispose()
    
    $titleBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(255, 255, 240, 180))
    $e.Graphics.DrawString($titleText, $titleFont, $titleBrush, $titleX, $titleY)
    $titleFont.Dispose()
    $titleBrush.Dispose()

    # ---------- DEBUG ----------
    $debugFont = New-Object Drawing.Font("Consolas", 9)
    $debugBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(180, 200, 200, 200))
    $e.Graphics.DrawString(("Calm = {0:N2}" -f $calm), $debugFont, $debugBrush, 10, 10)
    $debugFont.Dispose()
    $debugBrush.Dispose()
})

function Render-Castle($g, $castle, $groundY) {
    # Shadow
    $shadowBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(40, 0, 0, 0))
    $g.FillEllipse($shadowBrush, [int]$castle.X, $groundY+2, [int]$castle.Width, 15)
    $shadowBrush.Dispose()

    # Castle body
    $castleBrush = New-Object Drawing.SolidBrush($castle.Color)
    $g.FillRectangle($castleBrush, [int]$castle.X, [int]$castle.Y, [int]$castle.Width, [int]$castle.Height)
    $castleBrush.Dispose()

    # Brown roof colors
    $roofMain = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(200, 120, 70, 40))
    $roofDark = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(220, 90, 45, 25))

    # Towers
    foreach ($t in $castle.Towers) {
        $tx = [int]($castle.X + $t.X)
        $tw = [int]$t.Width
        $th = [int]$t.Height
        $ty = [int]($castle.Y - $th + 25)

        # Tower body
        $towerBrush = New-Object Drawing.SolidBrush($castle.Color)
        if ($t.IsRound) {
            $g.FillEllipse($towerBrush, $tx, $ty, $tw, $th)
        } else {
            $g.FillRectangle($towerBrush, $tx, $ty, $tw, $th)
        }
        $towerBrush.Dispose()

        # Roof
        if ($t.HasRoof) {
            switch ($t.RoofType) {
                "Pointed" {
                    $roofPoints = [Drawing.Point[]]@(
                        [Drawing.Point]::new($tx, $ty),
                        [Drawing.Point]::new($tx + [int]($tw/2), $ty - 20),
                        [Drawing.Point]::new($tx + $tw, $ty)
                    )
                    $g.FillPolygon($roofMain, $roofPoints)
                }
                "Spire" {
                    $roofPoints = [Drawing.Point[]]@(
                        [Drawing.Point]::new($tx + 5, $ty),
                        [Drawing.Point]::new($tx + [int]($tw/2), $ty - 35),
                        [Drawing.Point]::new($tx + $tw - 5, $ty)
                    )
                    $g.FillPolygon($roofMain, $roofPoints)
                }
                "Battlement" {
                    $battlementPen = New-Object Drawing.Pen($roofMain.Color, 3)
                    for ($b = 0; $b -lt $tw; $b += 8) {
                        $g.DrawLine($battlementPen, $tx+$b, $ty, $tx+$b, $ty-6)
                    }
                    $battlementPen.Dispose()
                }
                "Dome" {
                    $g.FillEllipse($roofDark, $tx, $ty-10, $tw, 24)
                }
            }
        }
    }

    $roofMain.Dispose()
    $roofDark.Dispose()

    # Windows
    $windowBrush = New-Object Drawing.SolidBrush($castle.WindowColor)
    $windowCount = Get-Random -Minimum 3 -Maximum 7
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

    # Torches
    foreach ($torch in $castle.Torches) {
        $torchX = [int]($castle.X + $torch.X)
        $torchY = [int]($castle.Y + $torch.Y + $torch.FlickerOffset)
        $torchSize = [int](6 * $torch.FlickerSize)
        
        $flameBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(200, 255, 140, 0))
        $g.FillEllipse($flameBrush, $torchX, $torchY, $torchSize, $torchSize)
        $flameBrush.Dispose()
    }
}

# -------------------------------
# TIMER
# -------------------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 33
$timer.Add_Tick({ $panel.Invalidate() })
$timer.Start()

# -------------------------------
# BRING FORM TO FRONT
# -------------------------------
$form.Add_Shown({
    $form.TopMost = $true
    $form.Activate()
    $form.TopMost = $false
})

$form.ShowDialog()