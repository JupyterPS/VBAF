Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -------------------------------
# FORM
# -------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Width = 1000
$form.Height = 420
$form.Text = "Castle Parade — Agent2 Visual Style"

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
    # Weighted types
    $types = @(
        "Gothic",   "FairyTale", "Cathedral", "Oriental",  "Palace", "Ruins"
        "Fortress", "Palace",    "Cathedral", "Oriental",  "Palace" 
        "Wizard",   "Cathedral", "FairyTale", "Oriental",  "Palace", "Ruins"
        "Oriental", "Ruins",     "Cathedral", "FairyTale", "Palace" 
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
         "Gothic"    { Build-GothicCastle $castle $groundY }
         "FairyTale" { Build-FairyTaleCastle $castle $groundY }
         "Fortress"  { Build-FortressCastle $castle $groundY }
         "Palace"    { Build-PalaceCastle $castle $groundY }
         "Wizard"    { Build-WizardCastle $castle $groundY }
         "Cathedral" { Build-CathedralCastle $castle $groundY }    
         "Oriental"  { Build-OrientalCastle $castle $groundY }
         "Ruins"     { Build-RuinsCastle $castle $groundY }                  
    }
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
            RoofType = "Spire"
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
            HasRoseWindow = $true
            HasFlag = $true
        },
        @{
            X = [int]($castleWidth - 42); Width = 30; Height = 75
            HasRoof = $true; RoofType = "Pointed"
            HasRoseWindow = $true
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

# -------------------------------
# SLIDER
# -------------------------------
# Slim container for slider
$sliderContainer = New-Object System.Windows.Forms.Panel
$sliderContainer.Height = 25
$sliderContainer.Dock = "Bottom"
$sliderContainer.BackColor = [Drawing.Color]::FromArgb(30, 30, 30)

$slider = New-Object System.Windows.Forms.TrackBar
$slider.Minimum = 0
$slider.Maximum = 100
$slider.Value = 50
$slider.Dock = "Fill"
$slider.TickStyle = 'None'
$sliderContainer.Controls.Add($slider)

$panel.Controls.Add($sliderContainer)

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
# PAINT (AGENT2 VISUAL STYLE)
# -------------------------------
$panel.Add_Paint({
    param($s,$e)

    $script:TickCount++
    
    # Smooth interpolation (Agent2 style)
    $script:VisualCalm += ($script:TargetCalm - $script:VisualCalm) * 0.03
    $calm = $script:VisualCalm

    $w = $s.Width
    $h = $s.Height
    $groundY = [int]($h * 0.62)  # Agent2's ground position

    # ---------- SKY (AGENT2 COLORS) ----------
    $skyTop = LerpColor `
        ([Drawing.Color]::FromArgb(30,60,110)) `
        ([Drawing.Color]::FromArgb(140,80,30)) `
        $calm

    $skyBottom = LerpColor `
        ([Drawing.Color]::FromArgb(10,20,40)) `
        ([Drawing.Color]::FromArgb(90,50,25)) `
        $calm

    $skyBrush = New-Object Drawing.Drawing2D.LinearGradientBrush `
        (New-Object Drawing.Point 0,0),`
        (New-Object Drawing.Point 0,$groundY),`
        $skyTop,$skyBottom

    $e.Graphics.FillRectangle($skyBrush,0,0,$w,$groundY)
    $skyBrush.Dispose()

    # ---------- DISTANT HILLS (AGENT2 STYLE) ----------
    $hillColor = LerpColor `
        ([Drawing.Color]::FromArgb(45,70,90)) `
        ([Drawing.Color]::FromArgb(95,80,60)) `
        $calm

    $hillBrush = New-Object Drawing.SolidBrush $hillColor
    $hillBaseY = [int]($h * 0.58)

    $hills = @(
        @{ X = -200; W = 600; H = 120 }
        @{ X =  250; W = 700; H = 150 }
        @{ X =  750; W = 600; H = 110 }
    )

    foreach ($hill in $hills) {
        $e.Graphics.FillEllipse(
            $hillBrush,
            $hill.X,
            $hillBaseY - $hill.H,
            $hill.W,
            $hill.H * 2
        )
    }
    $hillBrush.Dispose()
<#
    # ---------- MOON ----------
    $moonBrush = New-Object Drawing.Drawing2D.LinearGradientBrush(
        [Drawing.Point]::new($w-150, 50),
        [Drawing.Point]::new($w-100, 100),
        [Drawing.Color]::FromArgb(220, 255, 250, 230),
        [Drawing.Color]::FromArgb(150, 230, 230, 240)
    )
    $e.Graphics.FillEllipse($moonBrush, $w-150, 50, 60, 60)
    $moonBrush.Dispose()
#>
    # ---------- GROUND (AGENT2 GRADIENT + TEXTURE) ----------
    $groundTop = LerpColor `
        ([Drawing.Color]::FromArgb(55,60,70)) `
        ([Drawing.Color]::FromArgb(120,95,70)) `
        $calm

    $groundBottom = LerpColor `
        ([Drawing.Color]::FromArgb(25,28,35)) `
        ([Drawing.Color]::FromArgb(70,55,40)) `
        $calm

    $groundBrush = New-Object Drawing.Drawing2D.LinearGradientBrush `
        (New-Object Drawing.Point 0,$groundY),`
        (New-Object Drawing.Point 0,$h),`
        $groundTop,$groundBottom

    $e.Graphics.FillRectangle($groundBrush,0,$groundY,$w,$h-$groundY)
    $groundBrush.Dispose()

    # Subtle terrain strata (Agent2's texture)
    for ($i=0; $i -lt 6; $i++) {
        $layerBrush = New-Object Drawing.SolidBrush `
            ([Drawing.Color]::FromArgb(10 + $i*4,0,0,0))
        $e.Graphics.FillRectangle(
            $layerBrush,
            0,$groundY + ($i*18),
            $w,3
        )
        $layerBrush.Dispose()
    }

    # Depth shading (Agent2's shadow effect)
    $shadeBrush = New-Object Drawing.Drawing2D.LinearGradientBrush `
        (New-Object Drawing.Point 0,$groundY),`
        (New-Object Drawing.Point 0,$h),`
        ([Drawing.Color]::FromArgb(25,0,0,0)),`
        ([Drawing.Color]::FromArgb(90,0,0,0))

    $e.Graphics.FillRectangle($shadeBrush,0,$groundY,$w,$h-$groundY)
    $shadeBrush.Dispose()

    # ---------- CASTLES ----------
    foreach ($c in $script:Castles) { 

    if ($c.Width -eq 0) {
        Initialize-Castle $c $w $groundY
    }
    
#       ← THIS IS THE FIX
#    $c.Y = $groundY - $c.Height

    # Animate flags
    foreach ($flag in $c.Flags) {
        $flag.WaveOffset = [Math]::Sin($script:TickCount * 0.15 + $flag.Phase) * 3
    }
    
    # Animate torches
    foreach ($torch in $c.Torches) {
        $torch.FlickerOffset = [Math]::Sin($script:TickCount * 0.3 + $torch.Phase) * 2
        $torch.FlickerSize = 1 + [Math]::Abs([Math]::Sin($script:TickCount * 0.25 + $torch.Phase)) * 0.5
    }

    $c.X -= $c.Speed

    if ($c.X + $c.Width -lt -50) {
        Initialize-Castle $c $w $groundY
    }

    Render-Castle $e.Graphics $c $groundY
    }

    # ---------- MIST (AGENT2 STYLE) ----------
    $mistAlpha = [int](60 + 90 * $calm)  # Agent2's mist opacity
    $mistBrush = New-Object Drawing.SolidBrush `
        ([Drawing.Color]::FromArgb($mistAlpha,210,210,220))

    $e.Graphics.FillEllipse(
        $mistBrush,
        -150,$groundY-45,
        $w+300,120
    )
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
    $e.Graphics.DrawString(("Calm = {0:N2}" -f $calm),(New-Object Drawing.Font "Consolas",10),[Drawing.Brushes]::White,10,10)
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
                "Pagoda" {
                    $tierHeight = 9
                    $tier1 = [Drawing.Rectangle]::new($tx-4, $ty-2, $tw+8, $tierHeight)
                    $tier2 = [Drawing.Rectangle]::new($tx-2, $ty-2-$tierHeight, $tw+4, $tierHeight)
                    $g.FillRectangle($roofMain, $tier1)
                    $g.FillRectangle($roofDark, $tier2)
                }
            }
        }

        # Rose window for cathedral
        if ($t.HasRoseWindow) {
            $rwSize = [int]($tw * 0.6)
            $rwX = $tx + [int](($tw - $rwSize) / 2)
            $rwY = $ty + [int]($th * 0.3)
            $rwBrush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(180, 255, 100, 150))
            $g.FillEllipse($rwBrush, $rwX, $rwY, $rwSize, $rwSize)
            $rwBrush.Dispose()
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

# Maximize the form
$form.WindowState = 'Maximized'

# Bring form to front
$form.Add_Shown({
    $form.TopMost = $true
    $form.Activate()
    $form.TopMost = $false
})

$form.ShowDialog()