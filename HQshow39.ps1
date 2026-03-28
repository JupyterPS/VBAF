# ==============================================
# Show39 - Drug Development Pipeline (BaseShow)
# COMPLETE AND READY TO TEST
# ==============================================

class Show39 : BaseShow {
    hidden [System.Collections.ArrayList] $Drugs = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $PipelineStages = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $Transitions = [System.Collections.ArrayList]::new()
    hidden [int] $TickCount = 0
    hidden [int] $TickerOffset = 0
    hidden [System.Windows.Forms.Timer] $AnimationTimer

    Show39([System.Windows.Forms.Panel]$panel) : base("show39", $panel) {
        $this.InitializePipelineStages()
        $this.InitializeDrugs()
        
        # Create animation timer
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 50  # 20 FPS
        
        $self = $this
        $this.AnimationTimer.Add_Tick({
            $self.OnUpdate()
        }.GetNewClosure())
    }

    [void] OnStart() {
        Write-Host "🔬 [Show39] Drug Development Pipeline initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(15, 20, 25)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Ticker messages
        $Show39Messages = @(
            "DRUG DEVELOPMENT PIPELINE - From Lab to Life",
            "Watch compounds progress through development stages",
            "Discovery → Preclinical → Clinical → FDA → Market",
            "Novo Nordisk - 10-15 years from molecule to medicine",
            "Innovation pipeline: Transforming science into treatments"
        )
        $global:messages = $Show39Messages
        if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
        
        $this.SetupPaintEvent()
        $this.SetupVisibleChanged()
        
        # Start animation
        $this.AnimationTimer.Start()
        
        Write-Host "✅ [Show39] Ready with $($this.Drugs.Count) drugs!" -ForegroundColor Green
        Write-Host "🎬 [Show39] Animation started!" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.TickCount++
        $tick = $this.TickCount
        
        # Update ticker scroll
        $this.TickerOffset += 2
        if ($this.TickerOffset -gt 1500) { $this.TickerOffset = 0 }
        
        # Update drugs
        foreach ($drug in $this.Drugs) {
            # Pulse animation
            $drug.Pulse += 0.05
            if ($drug.Pulse -gt 6.28) { $drug.Pulse -= 6.28 }
            
            # Move toward target
            if ($drug.Moving) {
                $dx = $drug.TargetX - $drug.X
                $dy = $drug.TargetY - $drug.Y
                $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
                
                if ($dist -gt 2) {
                    $drug.X += $dx * 0.05
                    $drug.Y += $dy * 0.05
                    
                    # Add trail
                    if ($tick % 3 -eq 0) {
                        [void]$drug.Trail.Add(@{ X = $drug.X; Y = $drug.Y; Life = 100 })
                    }
                } else {
                    $drug.Moving = $false
                }
            }
            
            # Update trail
            $this.UpdateDrugTrail($drug)
            
            # Progress through stage
            if (-not $drug.Moving) {
                $drug.StageProgress += 0.002
                
                # Advance to next stage
                if ($drug.StageProgress -ge 1.0 -and $drug.Stage -lt 6) {
                    $drug.Stage++
                    $drug.StageProgress = 0
                    
                    $newStage = $this.PipelineStages[$drug.Stage]
                    $drug.TargetX = $newStage.X
                    $drug.TargetY = $newStage.Y + 100 + ($newStage.Drugs.Count * 25)
                    $drug.Color = $newStage.Color
                    $drug.Moving = $true
                    
                    [void]$newStage.Drugs.Add($drug.Name)
                    $newStage.Glow = 1.0
                }
            }
        }
        
        # Update stages
        foreach ($stage in $this.PipelineStages) {
            if ($stage.Glow -gt 0) { $stage.Glow -= 0.02 }
        }
        
        # Update transitions
        $this.UpdateTransitions()
        
        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "🛑 [Show39] Cleanup..." -ForegroundColor Yellow
        
        # Stop timer
        if ($this.AnimationTimer) {
            $this.AnimationTimer.Stop()
        }
        
        $this.Drugs.Clear()
        $this.Transitions.Clear()
        
        Write-Host "✔️ [Show39] Cleanup complete!" -ForegroundColor Green
    }

    hidden [void] InitializePipelineStages() {
        $stageData = @(
            @{Name="Discovery"; X=50; Icon="🔍"; Color=[System.Drawing.Color]::FromArgb(100, 150, 255); Duration="2-3 years"},
            @{Name="Preclinical"; X=150; Icon="🧪"; Color=[System.Drawing.Color]::FromArgb(150, 100, 255); Duration="1-2 years"},
            @{Name="Phase I"; X=250; Icon="💉"; Color=[System.Drawing.Color]::FromArgb(255, 150, 100); Duration="1-2 years"},
            @{Name="Phase II"; X=350; Icon="🏥"; Color=[System.Drawing.Color]::FromArgb(255, 200, 100); Duration="2-3 years"},
            @{Name="Phase III"; X=450; Icon="👥"; Color=[System.Drawing.Color]::FromArgb(100, 255, 150); Duration="3-4 years"},
            @{Name="FDA Review"; X=550; Icon="📋"; Color=[System.Drawing.Color]::FromArgb(255, 100, 150); Duration="1-2 years"},
            @{Name="Market"; X=650; Icon="🎯"; Color=[System.Drawing.Color]::FromArgb(255, 215, 0); Duration="∞"}
        )
        
        foreach ($data in $stageData) {
            [void]$this.PipelineStages.Add(@{
                Name = $data.Name; X = $data.X; Y = 150
                Icon = $data.Icon; Color = $data.Color; Duration = $data.Duration
                Drugs = [System.Collections.ArrayList]::new(); Glow = 0
            })
        }
    }

    hidden [void] InitializeDrugs() {
        $drugData = @(
            @{Name="NNC-4287"; Stage=0; Target="Diabetes"; Progress=0.75},
            @{Name="GLP-2 Rev"; Stage=1; Target="Obesity"; Progress=0.45},
            @{Name="Insulin Neo"; Stage=2; Target="Type 1"; Progress=0.30},
            @{Name="CardioX"; Stage=2; Target="Heart"; Progress=0.60},
            @{Name="HemoFix"; Stage=3; Target="Blood"; Progress=0.80},
            @{Name="MetabPro"; Stage=3; Target="Metabolism"; Progress=0.55},
            @{Name="SemaNext"; Stage=4; Target="Weight"; Progress=0.90},
            @{Name="DiabCure"; Stage=5; Target="Diabetes"; Progress=0.40},
            @{Name="InsuVita"; Stage=6; Target="Type 2"; Progress=1.0}
        )
        
        foreach ($data in $drugData) {
            $stage = $this.PipelineStages[$data.Stage]
            $drugY = $stage.Y + 100 + ($stage.Drugs.Count * 25)
            
            [void]$this.Drugs.Add(@{
                Name = $data.Name; Target = $data.Target; Stage = $data.Stage
                StageProgress = $data.Progress; X = $stage.X; Y = $drugY
                TargetX = $stage.X; TargetY = $drugY; Color = $stage.Color
                Size = 12; Pulse = (Get-Random -Minimum 0 -Maximum 628) / 100.0
                Trail = [System.Collections.ArrayList]::new(); Moving = $false
            })
            [void]$stage.Drugs.Add($data.Name)
        }
    }

    hidden [void] UpdateDrugTrail($drug) {
        $aliveTrail = [System.Collections.ArrayList]::new()
        foreach ($trailPoint in $drug.Trail) {
            $trailPoint.Life -= 2
            if ($trailPoint.Life -gt 0) { [void]$aliveTrail.Add($trailPoint) }
        }
        $drug.Trail.Clear()
        foreach ($point in $aliveTrail) { [void]$drug.Trail.Add($point) }
    }

    hidden [void] UpdateTransitions() {
        $activeTransitions = [System.Collections.ArrayList]::new()
        foreach ($transition in $this.Transitions) {
            $transition.Life -= 1
            if ($transition.Life -gt 0) { [void]$activeTransitions.Add($transition) }
        }
        $this.Transitions.Clear()
        foreach ($trans in $activeTransitions) { [void]$this.Transitions.Add($trans) }
    }

    hidden [void] RenderPipeline($g, $width, $height, $tickerOffset) {
        # Background gradient
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(15, 20, 25),
            [System.Drawing.Color]::FromArgb(25, 30, 40)
        )
        try {
            $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        }
        finally {
            $bgBrush.Dispose()
        }
        
        # Pipeline flow lines
        $flowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40, 100, 150, 200), 2)
        $flowPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        try {
            for ($i = 0; $i -lt ($this.PipelineStages.Count - 1); $i++) {
                $stage1 = $this.PipelineStages[$i]
                $stage2 = $this.PipelineStages[$i + 1]
                $g.DrawLine($flowPen, $stage1.X + 40, $stage1.Y + 40, $stage2.X - 10, $stage2.Y + 40)
            }
        }
        finally {
            $flowPen.Dispose()
        }
        
        # Draw stages
        foreach ($stage in $this.PipelineStages) {
            $this.DrawStage($g, $stage)
        }
        
        # Draw drug trails
        foreach ($drug in $this.Drugs) {
            foreach ($trailPoint in $drug.Trail) {
                $alpha = [int](($trailPoint.Life / 100.0) * 150)
                $trailColor = [System.Drawing.Color]::FromArgb($alpha, $drug.Color.R, $drug.Color.G, $drug.Color.B)
                $trailBrush = New-Object System.Drawing.SolidBrush($trailColor)
                try {
                    $g.FillEllipse($trailBrush, $trailPoint.X - 2, $trailPoint.Y - 2, 4, 4)
                }
                finally {
                    $trailBrush.Dispose()
                }
            }
        }
        
        # Draw drugs
        foreach ($drug in $this.Drugs) {
            $this.DrawDrug($g, $drug)
        }
        
        # Draw ticker at bottom
        $this.DrawTicker($g, $width, $height, $tickerOffset)
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 200, 255))
        try {
            $g.DrawString("DRUG DEVELOPMENT PIPELINE", $titleFont, $titleBrush, 10, 10)
        }
        finally {
            $titleFont.Dispose()
            $titleBrush.Dispose()
        }
    }

    hidden [void] DrawStage($g, $stage) {
        # Stage box
        $boxWidth = 80
        $boxHeight = 80
        
        # Glow effect
        if ($stage.Glow -gt 0) {
            $glowAlpha = [int]($stage.Glow * 100)
            $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, $stage.Color.R, $stage.Color.G, $stage.Color.B)
            $glowBrush = New-Object System.Drawing.SolidBrush($glowColor)
            try {
                $g.FillEllipse($glowBrush, $stage.X - 10, $stage.Y - 10, $boxWidth + 20, $boxHeight + 20)
            }
            finally {
                $glowBrush.Dispose()
            }
        }
        
        # Stage background
        $stageBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, $stage.Color.R, $stage.Color.G, $stage.Color.B))
        try {
            $g.FillRoundedRectangle($stageBrush, $stage.X, $stage.Y, $boxWidth, $boxHeight, 10)
        }
        catch {
            # Fallback to regular rectangle if rounded not available
            $g.FillRectangle($stageBrush, $stage.X, $stage.Y, $boxWidth, $boxHeight)
        }
        finally {
            $stageBrush.Dispose()
        }
        
        # Stage border
        $borderPen = New-Object System.Drawing.Pen($stage.Color, 2)
        try {
            $g.DrawRectangle($borderPen, $stage.X, $stage.Y, $boxWidth, $boxHeight)
        }
        finally {
            $borderPen.Dispose()
        }
        
        # Icon
        $iconFont = New-Object System.Drawing.Font("Segoe UI Emoji", 24)
        $iconBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        try {
            $iconSize = $g.MeasureString($stage.Icon, $iconFont)
            $g.DrawString($stage.Icon, $iconFont, $iconBrush, 
                $stage.X + ($boxWidth - $iconSize.Width) / 2, 
                $stage.Y + 10)
        }
        finally {
            $iconFont.Dispose()
            $iconBrush.Dispose()
        }
        
        # Stage name
        $nameFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $nameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        try {
            $nameSize = $g.MeasureString($stage.Name, $nameFont)
            $g.DrawString($stage.Name, $nameFont, $nameBrush,
                $stage.X + ($boxWidth - $nameSize.Width) / 2,
                $stage.Y + 50)
        }
        finally {
            $nameFont.Dispose()
            $nameBrush.Dispose()
        }
        
        # Duration
        $durFont = New-Object System.Drawing.Font("Segoe UI", 7)
        $durBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 200, 200, 200))
        try {
            $durSize = $g.MeasureString($stage.Duration, $durFont)
            $g.DrawString($stage.Duration, $durFont, $durBrush,
                $stage.X + ($boxWidth - $durSize.Width) / 2,
                $stage.Y + 65)
        }
        finally {
            $durFont.Dispose()
            $durBrush.Dispose()
        }
    }

    hidden [void] DrawDrug($g, $drug) {
        $pulseSize = 2 + ([Math]::Sin($drug.Pulse) * 3)
        $radius = $drug.Size + $pulseSize
        
        # Drug glow
        $glowAlpha = 80
        $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, $drug.Color.R, $drug.Color.G, $drug.Color.B)
        $glowBrush = New-Object System.Drawing.SolidBrush($glowColor)
        try {
            $g.FillEllipse($glowBrush, $drug.X - $radius - 5, $drug.Y - $radius - 5, ($radius + 5) * 2, ($radius + 5) * 2)
        }
        finally {
            $glowBrush.Dispose()
        }
        
        # Drug body
        $drugBrush = New-Object System.Drawing.SolidBrush($drug.Color)
        try {
            $g.FillEllipse($drugBrush, $drug.X - $radius, $drug.Y - $radius, $radius * 2, $radius * 2)
        }
        finally {
            $drugBrush.Dispose()
        }
        
        # Drug outline
        $outlinePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 2)
        try {
            $g.DrawEllipse($outlinePen, $drug.X - $radius, $drug.Y - $radius, $radius * 2, $radius * 2)
        }
        finally {
            $outlinePen.Dispose()
        }
        
        # Drug name
        $nameFont = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
        $nameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        try {
            $g.DrawString($drug.Name, $nameFont, $nameBrush, $drug.X + 15, $drug.Y - 5)
        }
        finally {
            $nameFont.Dispose()
            $nameBrush.Dispose()
        }
        
        # Progress bar
        if ($drug.StageProgress -gt 0 -and -not $drug.Moving) {
            $barWidth = 60
            $barHeight = 4
            $barX = $drug.X + 15
            $barY = $drug.Y + 8
            
            # Background
            $barBgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 50, 50, 50))
            try {
                $g.FillRectangle($barBgBrush, $barX, $barY, $barWidth, $barHeight)
            }
            finally {
                $barBgBrush.Dispose()
            }
            
            # Progress
            $progressWidth = $barWidth * $drug.StageProgress
            $progressBrush = New-Object System.Drawing.SolidBrush($drug.Color)
            try {
                $g.FillRectangle($progressBrush, $barX, $barY, $progressWidth, $barHeight)
            }
            finally {
                $progressBrush.Dispose()
            }
        }
    }

    hidden [void] DrawTicker($g, $width, $height, $offset) {
        $tickerY = $height - 30
        $tickerFont = New-Object System.Drawing.Font("Segoe UI", 10)
        $tickerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 200, 255))
        
        try {
            $tickerText = "💊 Pipeline Progress: 9 compounds | 🔬 Discovery: 1 | 🧪 Preclinical: 1 | Phase I-III: 5 | 📋 FDA: 1 | 🎯 Market: 1 | Timeline: 10-15 years average"
            $textWidth = $g.MeasureString($tickerText, $tickerFont).Width
            
            $x = $width - $offset
            while ($x -lt $width + $textWidth) {
                $g.DrawString($tickerText, $tickerFont, $tickerBrush, $x, $tickerY)
                $x += $textWidth + 100
            }
        }
        finally {
            $tickerFont.Dispose()
            $tickerBrush.Dispose()
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
            
            # Render complete pipeline
            $self.RenderPipeline($g, $width, $height, $self.TickerOffset)
        }.GetNewClosure())
    }

    hidden [void] SetupVisibleChanged() {
        $self = $this
        $this.Panel.Add_VisibleChanged({
            param($s, $e)
            if ($self.Panel.Visible) {
                $Show39Messages = @(
                    "✨ DRUG DEVELOPMENT PIPELINE - From Lab to Life",
                    "Watch compounds progress through development stages",
                    "Discovery → Preclinical → Clinical → FDA → Market",
                    "Novo Nordisk - 10-15 years from molecule to medicine",
                    "Innovation pipeline: Transforming science into treatments"
                )
                $global:messages = $Show39Messages
                if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
            }
        }.GetNewClosure())
    }
}

# Legacy compatibility
function Stop-Show39 {
    Write-Host "[Show39] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show39")) {
        $Global:ShowManager.Shows["show39"].Stop()
    }
}

Write-Host "✅ COMPLETE Show39 - Drug Development Pipeline (BaseShow)" -ForegroundColor Green
Write-Host "🔬 TreeView → Show39 → Watch drugs flow through pipeline! ✨" -ForegroundColor Cyan
