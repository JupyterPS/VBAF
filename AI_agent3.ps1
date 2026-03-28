Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -------------------------------
# FORM
# -------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Width = 1000
$form.Height = 420
$form.Text = "Calm World — Sky, Mist, Hills & Castles"

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = 'Fill'
$panel.BackColor = [Drawing.Color]::Black
$form.Controls.Add($panel)

# Enable DoubleBuffering (safe reflection)
$prop = $panel.GetType().GetProperty("DoubleBuffered",[System.Reflection.BindingFlags] "Instance,NonPublic")
$prop.SetValue($panel,$true,$null)

# -------------------------------
# STATE
# -------------------------------
$script:TargetCalm = 0.5
$script:VisualCalm = 0.5

# Castles
$script:Castles = @()
for ($i=0; $i -lt 6; $i++) {
    $script:Castles += @{
        X = (Get-Random -Minimum 100 -Maximum 1000)
        Y = 0
        Width = 80
        Height = 80
        Speed = 0.5 + (Get-Random -Minimum 0 -Maximum 0.3)
    }
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

    # Smooth calm
    $script:VisualCalm += ($script:TargetCalm - $script:VisualCalm) * 0.03
    $calm = $script:VisualCalm

    $w = $s.Width
    $h = $s.Height
    $groundY = [int]($h * 0.65)

    # ---------- SKY ----------
    $skyTop = LerpColor ([Drawing.Color]::FromArgb(30,60,110)) ([Drawing.Color]::FromArgb(140,80,30)) $calm
    $skyBottom = LerpColor ([Drawing.Color]::FromArgb(10,20,40)) ([Drawing.Color]::FromArgb(90,50,25)) $calm
    $skyBrush = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0,0),(New-Object Drawing.Point 0,$groundY),$skyTop,$skyBottom
    $e.Graphics.FillRectangle($skyBrush,0,0,$w,$groundY)
    $skyBrush.Dispose()

    # ---------- HILLS ----------
    $hillBaseY = [int]($h * 0.58)
    $hillColor = LerpColor ([Drawing.Color]::FromArgb(40,70,90)) ([Drawing.Color]::FromArgb(90,80,60)) $calm
    $hillBrush = New-Object Drawing.SolidBrush $hillColor
    $hills = @(
        @{ X=-200; Width=600; Height=120 }
        @{ X=200; Width=700; Height=140 }
        @{ X=650; Width=600; Height=110 }
    )
    foreach ($hill in $hills) {
        $e.Graphics.FillEllipse($hillBrush,$hill.X,$hillBaseY-$hill.Height,$hill.Width,$hill.Height*2)
    }
    $hillBrush.Dispose()

    # ---------- GROUND ----------
    $groundTop = LerpColor ([Drawing.Color]::FromArgb(55,60,70)) ([Drawing.Color]::FromArgb(120,95,70)) $calm
    $groundBottom = LerpColor ([Drawing.Color]::FromArgb(25,28,35)) ([Drawing.Color]::FromArgb(70,55,40)) $calm
    $groundBrush = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0,$groundY),(New-Object Drawing.Point 0,$h),$groundTop,$groundBottom
    $e.Graphics.FillRectangle($groundBrush,0,$groundY,$w,$h-$groundY)
    $groundBrush.Dispose()

    # ---------- CASTLES ----------
    foreach ($c in $script:Castles) {
        $c.X -= $c.Speed
        if ($c.X + $c.Width -lt -50) { $c.X = $w + (Get-Random -Minimum 50 -Maximum 200) }
        $c.Y = $groundY - $c.Height
        $e.Graphics.FillRectangle([Drawing.Brushes]::Silver,[int]$c.X,[int]$c.Y,$c.Width,$c.Height)
        # Optional: draw simple towers
        $towerCount = 1 + (Get-Random -Minimum 0 -Maximum 2)
        for ($t=0; $t -lt $towerCount; $t++) {
            $tx = [int]$c.X + ($t*15)
            $ty = [int]$c.Y - 20
            $e.Graphics.FillRectangle([Drawing.Brushes]::Gray,$tx,$ty,10,20)
        }
    }

    # ---------- MIST ----------
    $mistAlpha = [int](60 + 90 * $calm)
    $mistBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb($mistAlpha,210,210,220))
    $e.Graphics.FillEllipse($mistBrush,-150,$groundY-40,$w+300,120)
    $mistBrush.Dispose()

    # ---------- DEBUG ----------
    $e.Graphics.DrawString(("Calm = {0:N2}" -f $calm),(New-Object Drawing.Font "Consolas",10),[Drawing.Brushes]::White,10,10)
})

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
