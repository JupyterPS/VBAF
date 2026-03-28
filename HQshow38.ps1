# ==============================================
# Show38 - Clinical Trial Progress (BaseShow)
# ==============================================

class Show38 : BaseShow {
    hidden [System.Collections.ArrayList] $Trials = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $SuccessParticles = [System.Collections.ArrayList]::new()
    hidden [int] $TickCount = 0

    Show38([System.Windows.Forms.Panel]$panel) : base("show38", $panel) {
        $this.InitializeTrials()
    }

    [void] OnStart() {
        Write-Host "💉 [Show38] Clinical Trial Progress initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(15, 20, 30)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Ticker messages
        $Show38Messages = @(
            "💉 CLINICAL TRIAL PROGRESS - Real-time Drug Development",
            "👥 Tracking patient outcomes across multiple trial phases",
            "📊 Phase I → Phase II → Phase III → FDA Approval",
            "🏥 Novo Nordisk - Advancing Life-Saving Treatments",
            "✅ Safety, efficacy, and patient wellbeing are our priorities"
        )
        $global:messages = $Show38Messages
        if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
        
        $this.SetupPaintEvent()
        $this.SetupVisibleChanged()
        
        Write-Host "✅ [Show38] Ready with $($this.Trials.Count) trials!" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.TickCount++
        $tick = $this.TickCount
        
        # Update trials
        foreach ($trial in $this.Trials) {
            if ($trial.Progress -lt $trial.TargetProgress) {
                $trial.Progress += 0.2
                
                if ($tick % 10 -eq 0 -and $trial.Progress -gt 20) {
                    [void]$this.SuccessParticles.Add(@{
                        X = 550; Y = $trial.Y + 35
                        VelocityX = (Get-Random -Minimum -20 -Maximum 20) / 10.0
                        VelocityY = (Get-Random -Minimum -30 -Maximum -10) / 10.0
                        Life = 80
                    })
                }
            }
            
            if ($trial.Progress -ge 100) {
                $trial.Progress = 0
                $trial.TargetProgress = Get-Random -Minimum 70 -Maximum 95
            }
            
            $trial.Pulse += 0.1
            if ($trial.Pulse -gt 6.28) { $trial.Pulse -= 6.28 }
            
            if ((Get-Random -Minimum 0 -Maximum 500) -lt 2) {
                $trial.Progress = [Math]::Min($trial.TargetProgress, $trial.Progress + 5)
            }
        }
        
        # Update particles
        $activeParticles = [System.Collections.ArrayList]::new()
        foreach ($particle in $this.SuccessParticles) {
            $particle.X += $particle.VelocityX
            $particle.Y += $particle.VelocityY
            $particle.VelocityY += 0.2
            $particle.Life -= 1
            
            if ($particle.Life -gt 0) { [void]$activeParticles.Add($particle) }
        }
        $this.SuccessParticles = $activeParticles
        
        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "🛑 [Show38] Cleanup..." -ForegroundColor Yellow
        
        $this.SuccessParticles.Clear()
        
        Write-Host "✔️ [Show38] Cleanup complete!" -ForegroundColor Green
    }

    hidden [void] InitializeTrials() {
        $trialData = @(
            @{Drug="NNC-2023"; Indication="Diabetes Type 2"; Phase="Phase III"; Patients=850; Success=82; Color=[System.Drawing.Color]::FromArgb(100, 200, 100); Y=80},
            @{Drug="GLP-1 Agonist"; Indication="Obesity"; Phase="Phase II"; Patients=320; Success=68; Color=[System.Drawing.Color]::FromArgb(100, 150, 255); Y=145},
            @{Drug="Insulin Analog"; Indication="Diabetes Type 1"; Phase="Phase III"; Patients=620; Success=89; Color=[System.Drawing.Color]::FromArgb(255, 200, 100); Y=210},
            @{Drug="Cardiovascular"; Indication="Heart Disease"; Phase="Phase II"; Patients=280; Success=71; Color=[System.Drawing.Color]::FromArgb(255, 100, 150); Y=275},
            @{Drug="Hemophilia A"; Indication="Blood Disorder"; Phase="Phase I"; Patients=45; Success=54; Color=[System.Drawing.Color]::FromArgb(200, 100, 255); Y=15}  # Moved to top
        )
        
        foreach ($data in $trialData) {
            [void]$this.Trials.Add(@{
                Drug = $data.Drug; Indication = $data.Indication; Phase = $data.Phase
                TotalPatients = $data.Patients; EnrolledPatients = $data.Patients
                CompletedPatients = [int]($data.Patients * ($data.Success / 100))
                SuccessRate = $data.Success; AdverseEvents = Get-Random -Minimum 2 -Maximum 15
                Color = $data.Color; Y = $data.Y; Progress = 0; TargetProgress = $data.Success
                Pulse = 0; Active = $true
                Timeline = @{ Start = "2023-01"; Current = "2024-11"; End = "2025-12"; DaysElapsed = Get-Random -Minimum 200 -Maximum 600; DaysTotal = 730 }
            })
        }
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
            
            $width = $s.Width; $height = $s.Height
            if ($width -le 0 -or $height -le 0) { return }
            
            # Background gradient
            $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                [System.Drawing.Point]::new(0, 0), [System.Drawing.Point]::new(0, $height),
                [System.Drawing.Color]::FromArgb(15, 20, 30), [System.Drawing.Color]::FromArgb(25, 30, 45)
            )
            $g.FillRectangle($bgBrush, 0, 0, $width, $height)
            $bgBrush.Dispose()
            
            # Medical cross pattern
            $crossPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(15, 100, 150, 200), 1)
            for ($i = 0; $i -lt 10; $i++) {
                $x = 100 + ($i * 60); $y = 50 + ($i * 40)
                $g.DrawLine($crossPen, $x - 10, $y, $x + 10, $y)
                $g.DrawLine($crossPen, $x, $y - 10, $x, $y + 10)
            }
            $crossPen.Dispose()
            
            # Success particles
            foreach ($particle in $self.SuccessParticles) {
                $alpha = [math]::Min(255, $particle.Life * 3)
                $particleColor = [System.Drawing.Color]::FromArgb($alpha, 100, 255, 100)
                $particleBrush = New-Object System.Drawing.SolidBrush($particleColor)
                $g.FillEllipse($particleBrush, $particle.X - 3, $particle.Y - 3, 6, 6)
                $particleBrush.Dispose()
            }
            
            # Clinical trials
            foreach ($trial in $self.Trials) {
                $self.RenderTrial($g, $trial, $width)
            }
            
            # Timeline
            $self.RenderTimeline($g, $width, $height)

            # Title bottom-left
$titleFont  = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 100, 200, 255))
$titleText  = " CLINICAL TRIAL PROGRESS"

$marginX = 10
$marginY = 10   # distance from bottom edge

# Y is height - margin from bottom
$g.DrawString($titleText, $titleFont, $titleBrush, $marginX, $height - $marginY - $titleFont.Height)

$titleFont.Dispose()
$titleBrush.Dispose()

        }.GetNewClosure())
    }

hidden [void] RenderTrial($g, $trial, $width) {
    $x = 50
    $y = $trial.Y
    $barWidth = 500
    $barHeight = 50

    # Container
    $containerBrush = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(40, 255, 255, 255)
    )
    $g.FillRectangle($containerBrush, $x, $y, $barWidth, $barHeight)
    $containerBrush.Dispose()

    $containerBorder = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(100, 200, 200, 200), 2
    )
    $g.DrawRectangle($containerBorder, $x, $y, $barWidth, $barHeight)
    $containerBorder.Dispose()

    # Progress bar background
    $progressX = $x + 140
    $progressY = $y + 18
    $progressW = $barWidth - 200
    $progressH = 14

    $progressBg = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(40, 80, 80, 100)
    )
    $g.FillRectangle($progressBg, $progressX, $progressY, $progressW, $progressH)
    $progressBg.Dispose()

    # Progress fill
    $pct = [math]::Min(100, [math]::Max(0, [double]$trial.Progress))
    $fillW = [int]($progressW * ($pct / 100.0))
    if ($fillW -gt 0) {
        $fillBrush = New-Object System.Drawing.SolidBrush($trial.Color)
        $g.FillRectangle($fillBrush, $progressX, $progressY, $fillW, $progressH)
        $fillBrush.Dispose()
    }

    # Drug + indication text
    $drugFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $indFont  = New-Object System.Drawing.Font("Segoe UI", 8)
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 240, 240, 255))

    $drugText = $trial.Drug
    $indText  = $trial.Indication

    $g.DrawString($drugText, $drugFont, $textBrush, $x + 8, $y + 6)
    $g.DrawString($indText,  $indFont,  $textBrush, $x + 8, $y + 24)

    $drugFont.Dispose()
    $indFont.Dispose()
    $textBrush.Dispose()

    # Phase badge
    $phaseText = $trial.Phase
    $phaseFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $phaseSize = $g.MeasureString($phaseText, $phaseFont)
    $phaseW = [int]($phaseSize.Width + 10)
    $phaseH = 18
    $phaseX = $x + $barWidth - $phaseW - 10
    $phaseY = $y + 6

    $phaseBrush = New-Object System.Drawing.SolidBrush(
        [System.Drawing.Color]::FromArgb(80, 0, 180, 255)
    )
    $g.FillRectangle($phaseBrush, $phaseX, $phaseY, $phaseW, $phaseH)
    $phaseBrush.Dispose()

    $phaseTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.DrawString($phaseText, $phaseFont, $phaseTextBrush, $phaseX + 5, $phaseY + 1)
    $phaseFont.Dispose()
    $phaseTextBrush.Dispose()

    # Success circle
    $circleX = $x + $barWidth + 20
    $circleY = $y + ($barHeight / 2) - 14
    $radius  = 14

    $successPct = [math]::Min(100, [math]::Max(0, [double]$trial.SuccessRate))
    $baseColor  = [System.Drawing.Color]::FromArgb(80, 100, 255, 100)
    $circleBrush = New-Object System.Drawing.SolidBrush($baseColor)
    $g.FillEllipse($circleBrush, $circleX, $circleY, $radius * 2, $radius * 2)
    $circleBrush.Dispose()

    $circlePen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(180, 150, 255, 150), 2
    )
    $g.DrawEllipse($circlePen, $circleX, $circleY, $radius * 2, $radius * 2)
    $circlePen.Dispose()

    $pctText = "$successPct`%"
    $pctFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $pctSize = $g.MeasureString($pctText, $pctFont)
    $pctBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.DrawString(
        $pctText, $pctFont, $pctBrush,
        $circleX + $radius - ($pctSize.Width / 2),
        $circleY + $radius - ($pctSize.Height / 2)
    )
    $pctFont.Dispose()
    $pctBrush.Dispose()
}
hidden [void] RenderTimeline($g, $width, $height) {
    if ($this.Trials.Count -eq 0) { return }

    $lineY = $height - 60
    $marginX = 60
    $lineW = $width - ($marginX * 2)

    $linePen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(120, 200, 200, 220), 2
    )
    $g.DrawLine($linePen, $marginX, $lineY, $marginX + $lineW, $lineY)
    $linePen.Dispose()

    $labelFont = New-Object System.Drawing.Font("Segoe UI", 8)
    $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 220, 220, 240))

    $phases = @("Phase I","Phase II","Phase III","Approval")
    for ($i = 0; $i -lt $phases.Count; $i++) {
        $t = $i / ([double]($phases.Count - 1))
        $x = $marginX + [int]($lineW * $t)
        $g.DrawLine(
            (New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 200, 200, 220), 1)),
            $x, $lineY - 5, $x, $lineY + 5
        )
        $g.DrawString($phases[$i], $labelFont, $labelBrush, $x - 20, $lineY + 8)
    }

    $labelFont.Dispose()
    $labelBrush.Dispose()
    }
    
    hidden [void] SetupVisibleChanged() {
        $self = $this
        $this.Panel.Add_VisibleChanged({
            param($s, $e)
            if ($self.Panel.Visible) {
                $Show38Messages = @(
                    "✨ CLINICAL TRIAL PROGRESS - Real-time Drug Development",
                    "👥 Tracking patient outcomes across multiple trial phases",
                    "📊 Phase I → Phase II → Phase III → FDA Approval",
                    "🏥 Novo Nordisk - Advancing Life-Saving Treatments",
                    "✅ Safety, efficacy, and patient wellbeing are our priorities"
                )
                $global:messages = $Show38Messages
                if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
            }
        }.GetNewClosure())
    }
}

# Legacy compatibility
function Stop-Show38 {
    Write-Host "🛑 [Show38] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show38")) {
        $Global:ShowManager.Shows["show38"].Stop()
    }
}

Write-Host "✅ COMPLETE Show38 - Clinical Trial Progress (BaseShow)" -ForegroundColor Green
Write-Host "💉 TreeView → Show38 → Watch clinical trials advance! ✨" -ForegroundColor Cyan

