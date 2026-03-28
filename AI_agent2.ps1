Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -------------------------------
# FORM
# -------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Width  = 1000
$form.Height = 400
$form.Text   = "Calm World"
$form.StartPosition = "CenterScreen"

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = 'Fill'
$panel.BackColor = [Drawing.Color]::Black
$form.Controls.Add($panel)

# --- Double buffering (PowerShell-safe)
$prop = $panel.GetType().GetProperty(
    "DoubleBuffered",
    [System.Reflection.BindingFlags] "Instance,NonPublic"
)
$prop.SetValue($panel,$true,$null)

# -------------------------------
# STATE
# -------------------------------
$script:TargetCalm = 0.5
$script:VisualCalm = 0.5

# -------------------------------
# SLIDER
# -------------------------------
$slider = New-Object System.Windows.Forms.TrackBar
$slider.Minimum = 0
$slider.Maximum = 100
$slider.Value   = 50
$slider.Dock    = "Bottom"
$slider.TickStyle = 'None'
$panel.Controls.Add($slider)

$slider.Add_ValueChanged({
    $script:TargetCalm = $slider.Value / 100
})

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

    # Smooth interpolation
    $script:VisualCalm += ($script:TargetCalm - $script:VisualCalm) * 0.03
    $calm = $script:VisualCalm

    $w = $s.Width
    $h = $s.Height
    $groundY = [int]($h * 0.62)

    # ---------- SKY ----------
    $skyTop = LerpColor `
        ([Drawing.Color]::FromArgb(30,60,110)) `
        ([Drawing.Color]::FromArgb(140,80,30)) `
        $calm

    $skyBottom = LerpColor `
        ([Drawing.Color]::FromArgb(10,20,40)) `
        ([Drawing.Color]::FromArgb(90,50,25)) `
        $calm

    $skyBrush = New-Object Drawing.Drawing2D.LinearGradientBrush -ArgumentList `
        (New-Object Drawing.Point -ArgumentList 0,0),
        (New-Object Drawing.Point -ArgumentList 0,$groundY),
        $skyTop,$skyBottom

    $e.Graphics.FillRectangle($skyBrush,0,0,$w,$groundY)
    $skyBrush.Dispose()

    # ---------- DISTANT HILLS ----------
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

    # ---------- GROUND ----------
    $groundTop = LerpColor `
        ([Drawing.Color]::FromArgb(55,60,70)) `
        ([Drawing.Color]::FromArgb(120,95,70)) `
        $calm

    $groundBottom = LerpColor `
        ([Drawing.Color]::FromArgb(25,28,35)) `
        ([Drawing.Color]::FromArgb(70,55,40)) `
        $calm

    $groundBrush = New-Object Drawing.Drawing2D.LinearGradientBrush -ArgumentList `
        (New-Object Drawing.Point -ArgumentList 0,$groundY),
        (New-Object Drawing.Point -ArgumentList 0,$h),
        $groundTop,$groundBottom

    $e.Graphics.FillRectangle($groundBrush,0,$groundY,$w,$h-$groundY)
    $groundBrush.Dispose()

    # Subtle terrain strata
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

    # Depth shading
    $shadeBrush = New-Object Drawing.Drawing2D.LinearGradientBrush -ArgumentList `
        (New-Object Drawing.Point -ArgumentList 0,$groundY),
        (New-Object Drawing.Point -ArgumentList 0,$h),
        ([Drawing.Color]::FromArgb(25,0,0,0)),
        ([Drawing.Color]::FromArgb(90,0,0,0))

    $e.Graphics.FillRectangle($shadeBrush,0,$groundY,$w,$h-$groundY)
    $shadeBrush.Dispose()

    # ---------- MIST ----------
    $mistAlpha = [int](60 + 90 * $calm)
    $mistBrush = New-Object Drawing.SolidBrush `
        ([Drawing.Color]::FromArgb($mistAlpha,210,210,220))

    $e.Graphics.FillEllipse(
        $mistBrush,
        -150,$groundY-45,
        $w+300,120
    )
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
# SHOW
# -------------------------------
$form.Add_Shown({
    $form.TopMost = $true
    $form.Activate()
    $form.TopMost = $false
})

$form.ShowDialog()