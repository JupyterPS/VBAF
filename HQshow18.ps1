# ===============================================
# HQshow18.ps1 — Wine Drop Journey v3 (COMPLETE)
# FULL 6-STAGES + 60 FPS + DASHBOARD INTEGRATION
# ===============================================
Write-Host "`n=> _____ HQshow18 (Wine Journey v3 - FULL) _____ <=`n" -ForegroundColor Cyan

class Show18 : BaseShow {
    hidden [hashtable] $State = @{}
    hidden [System.Collections.ArrayList] $Particles
    hidden [System.Windows.Forms.Label] $MessageLabel
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    hidden [int] $TickCount = 0

    Show18([System.Windows.Forms.Panel]$panel) : base("show18", $panel) {
        $this.State = @{
            CurrentStage = 0
            StageProgress = 0
            TickCount = 0
            Stages = @(
                @{Name="VINE"; Duration=60; Message="The journey begins in the vineyard..."},
                @{Name="HARVEST"; Duration=60; Message="Hand-picked at perfect ripeness..."},
                @{Name="PRESS"; Duration=60; Message="Gentle pressing extracts the essence..."},
                @{Name="BARREL"; Duration=80; Message="Aging in French oak barrels..."},
                @{Name="BOTTLE"; Duration=60; Message="Carefully bottled and sealed..."},
                @{Name="GLASS"; Duration=80; Message="Ready to be savored..."}
            )
        }
        $this.Particles = [System.Collections.ArrayList]::new()
    }

    [void] OnStart() {
        Write-Host " ▶️ [show18] Starting..." -ForegroundColor Green
        $self = $this
        
        # Dashboard panel integration
        if (-not $Global:floorShows.ContainsKey("Show18")) {
            $Global:floorShows["Show18"] = New-Object System.Windows.Forms.Panel
            $Global:floorShows["Show18"].Dock = 'Fill'
        }
        $panel = $Global:floorShows["Show18"]
        $this.Panel = $panel
        
        if (-not $Global:Show18Initialized) {
            Write-Host "[Show18] First time initialization..." -ForegroundColor Magenta
            
            $panel.Controls.Clear()
            $panel.BackColor = [System.Drawing.Color]::FromArgb(245, 235, 220)
            
            $prop = $panel.GetType().GetProperty("DoubleBuffered", [Reflection.BindingFlags]::Instance -bor [Reflection.BindingFlags]::NonPublic)
            if ($prop) { $prop.SetValue($panel, $true, $null) }
            
            $this.MessageLabel = New-Object System.Windows.Forms.Label
            $this.MessageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
            $this.MessageLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 40, 40)
            $this.MessageLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $this.MessageLabel.Dock = "Top"
            $this.MessageLabel.Height = 50
            $this.MessageLabel.Text = $this.State.Stages[0].Message
            $panel.Controls.Add($this.MessageLabel)
            
            $panel.Add_Paint({
                param($s,$e)
                $self.RenderWineJourney($e.Graphics, $s.Width, $s.Height)
            }.GetNewClosure())
            
            $Global:Show18Initialized = $true
        }
        
        # Animation timer (50ms = 20 FPS original timing)
        if ($this.AnimationTimer) {
            $this.AnimationTimer.Stop()
            $this.AnimationTimer.Dispose()
        }
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 50
        $this.AnimationTimer.Add_Tick({
            $self.TickCount++
            $self.State.TickCount = $self.TickCount
            $self.UpdateWineJourney()
            if ($self.Panel -and $self.Panel.Visible) {
                $self.Panel.Invalidate()
            }
        }.GetNewClosure())
        $this.AnimationTimer.Start()
        
        # Dashboard panel management
        foreach ($key in $Global:floorShows.Keys) {
            if ($key -ne "Show18") {
                $Global:floorShows[$key].Visible = $false
                $Global:floorShows[$key].SendToBack()
            }
        }
        $panel.Visible = $true
        $panel.BringToFront()
        if ($Global:form) { $Global:form.Refresh() }
        
        Write-Host "💧 [Show18] Wine Drop Journey FLOWING!" -ForegroundColor Green
    }

    [void] OnUpdate() {
        if ($this.Panel -and $this.Panel.Visible) {
            $this.UpdateWineJourney()
            $this.Panel.Invalidate()
        }
    }

    [void] OnStop() {
        if ($this.AnimationTimer) {
            $this.AnimationTimer.Stop()
            $this.AnimationTimer.Dispose()
            $this.AnimationTimer = $null
        }
        if ($this.Panel) {
            $this.Panel.Remove_Paint($null)
            $this.Panel.Visible = $false
        }
        $this.Particles.Clear()
        $this.State.CurrentStage = 0
        $this.State.StageProgress = 0
    }

    hidden [void] RenderWineJourney([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $stage = $this.State.Stages[$this.State.CurrentStage]
        $stageName = $stage.Name
        $centerX = $width / 2
        $centerY = ($height / 2) + 20
        
        # Background gradient
        $bgColor1 = switch ($stageName) {
            "VINE" { [System.Drawing.Color]::FromArgb(200, 230, 200) }
            "HARVEST" { [System.Drawing.Color]::FromArgb(255, 245, 220) }
            "PRESS" { [System.Drawing.Color]::FromArgb(255, 240, 240) }
            "BARREL" { [System.Drawing.Color]::FromArgb(80, 50, 30) }
            "BOTTLE" { [System.Drawing.Color]::FromArgb(30, 50, 40) }
            "GLASS" { [System.Drawing.Color]::FromArgb(240, 240, 250) }
        }
        $bgColor2 = switch ($stageName) {
            "VINE" { [System.Drawing.Color]::FromArgb(150, 200, 150) }
            "HARVEST" { [System.Drawing.Color]::FromArgb(230, 220, 200) }
            "PRESS" { [System.Drawing.Color]::FromArgb(255, 220, 220) }
            "BARREL" { [System.Drawing.Color]::FromArgb(50, 30, 20) }
            "BOTTLE" { [System.Drawing.Color]::FromArgb(20, 30, 25) }
            "GLASS" { [System.Drawing.Color]::FromArgb(220, 220, 240) }
        }
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 50),
            [System.Drawing.Point]::new(0, $height),
            $bgColor1,
            $bgColor2
        )
        $g.FillRectangle($bgBrush, 0, 50, $width, $height-50)
        $bgBrush.Dispose()
        
        # Stage-specific drawings
        switch ($stageName) {
            "VINE" { $this.RenderVineStage($g, $centerX, $centerY) }
            "HARVEST" { $this.RenderHarvestStage($g, $centerX, $centerY) }
            "PRESS" { $this.RenderPressStage($g, $centerX, $centerY) }
            "BARREL" { $this.RenderBarrelStage($g, $centerX, $centerY) }
            "BOTTLE" { $this.RenderBottleStage($g, $centerX, $centerY) }
            "GLASS" { $this.RenderGlassStage($g, $centerX, $centerY) }
        }
        
        # Stage indicator
        $stageFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $stageBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 80, 40, 40))
        $stageText = "✨ STAGE $($this.State.CurrentStage + 1)/6: $stageName"
        $stageSize = $g.MeasureString($stageText, $stageFont)
        $g.DrawString($stageText, $stageFont, $stageBrush, ($width - $stageSize.Width) / 2, $height - 40)
        $stageFont.Dispose()
        $stageBrush.Dispose()
    }

    hidden [void] RenderVineStage([System.Drawing.Graphics]$g, [int]$cx, [int]$cy) {
        $progress = $this.State.StageProgress / $this.State.Stages[0].Duration
        
        $trunkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(101, 67, 33))
        $g.FillRectangle($trunkBrush, $cx - 5, $cy, 10, 100)
        $trunkBrush.Dispose()
        
        $leafBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(34, 139, 34))
        for ($i = 0; $i -lt 5; $i++) {
            $leafX = $cx + ($i * 30) - 60
            $leafY = $cy + 20 + ($i * 15)
            $g.FillEllipse($leafBrush, $leafX, $leafY, 25, 15)
        }
        $leafBrush.Dispose()
        
        $grapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(139, 69, 139))
        for ($row = 0; $row -lt 3; $row++) {
            for ($col = 0; $col -lt 3; $col++) {
                $grapeX = $cx - 15 + ($col * 10)
                $grapeY = $cy + 40 + ($row * 10)
                $g.FillEllipse($grapeBrush, $grapeX, $grapeY, 12, 12)
            }
        }
        $grapeBrush.Dispose()
        
        $dropSize = 5 + ($progress * 10)
        $dropBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(139, 0, 139))
        $g.FillEllipse($dropBrush, $cx - $dropSize/2, $cy + 60, $dropSize, $dropSize)
        $dropBrush.Dispose()
    }

    hidden [void] RenderHarvestStage([System.Drawing.Graphics]$g, [int]$cx, [int]$cy) {
        $progress = $this.State.StageProgress / $this.State.Stages[1].Duration
        
        $basketBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(139, 90, 43))
        $g.FillRectangle($basketBrush, $cx - 60, $cy + 40, 120, 60)
        $basketBrush.Dispose()
        
        $basketPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(101, 67, 33), 3)
        $g.DrawRectangle($basketPen, $cx - 60, $cy + 40, 120, 60)
        $basketPen.Dispose()
        
        $grapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(139, 0, 139))
        for ($i = 0; $i -lt 15; $i++) {
            $grapeX = $cx - 50 + (($i % 5) * 20)
            $grapeY = $cy + 50 + ([math]::Floor($i / 5) * 15)
            $g.FillEllipse($grapeBrush, $grapeX, $grapeY, 15, 15)
        }
        $grapeBrush.Dispose()
        
        $dropY = $cy - 50 + ($progress * 100)
        $dropBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(139, 0, 139))
        $g.FillEllipse($dropBrush, $cx - 8, $dropY, 16, 16)
        $dropBrush.Dispose()
    }

    hidden [void] RenderPressStage([System.Drawing.Graphics]$g, [int]$cx, [int]$cy) {
        $progress = $this.State.StageProgress / $this.State.Stages[2].Duration
        
        $pressBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 100, 100))
        $g.FillRectangle($pressBrush, $cx - 80, $cy - 20, 160, 100)
        $pressBrush.Dispose()
        
        $detailPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 60, 60), 2)
        for ($i = 0; $i -lt 5; $i++) {
            $g.DrawLine($detailPen, $cx - 70 + ($i * 30), $cy, $cx - 70 + ($i * 30), $cy + 60)
        }
        $detailPen.Dispose()
        
        $juiceHeight = $progress * 50
        $juiceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(139, 0, 0))
        $g.FillRectangle($juiceBrush, $cx - 10, $cy + 80, 20, $juiceHeight)
        $juiceBrush.Dispose()
        
        foreach ($p in $this.Particles) {
            $alpha = [math]::Min(255, $p.Life * 3)
            $pBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 139, 0, 0))
            $g.FillEllipse($pBrush, $p.X, $p.Y, 6, 6)
            $pBrush.Dispose()
        }
    }

    hidden [void] RenderBarrelStage([System.Drawing.Graphics]$g, [int]$cx, [int]$cy) {
        $progress = $this.State.StageProgress / $this.State.Stages[3].Duration
        
        $barrelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(139, 90, 43))
        $g.FillEllipse($barrelBrush, $cx - 70, $cy - 40, 140, 100)
        $g.FillRectangle($barrelBrush, $cx - 70, $cy, 140, 60)
        $g.FillEllipse($barrelBrush, $cx - 70, $cy + 50, 140, 20)
        $barrelBrush.Dispose()
        
        $bandPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 40, 20), 4)
        $g.DrawEllipse($bandPen, $cx - 70, $cy - 5, 140, 20)
        $g.DrawEllipse($bandPen, $cx - 70, $cy + 25, 140, 20)
        $bandPen.Dispose()
        
        $wineLevel = $cy + 60 - ($progress * 60)
        $wineBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 100, 30, 30))
        $g.FillRectangle($wineBrush, $cx - 65, $wineLevel, 130, $cy + 60 - $wineLevel)
        $wineBrush.Dispose()
        
        $colorFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $colorBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 150))
        $colorText = "✨ Aging: $([math]::Round($progress * 100))%"
        $g.DrawString($colorText, $colorFont, $colorBrush, $cx - 40, $cy - 60)
        $colorFont.Dispose()
        $colorBrush.Dispose()
    }

    hidden [void] RenderBottleStage([System.Drawing.Graphics]$g, [int]$cx, [int]$cy) {
        $progress = $this.State.StageProgress / $this.State.Stages[4].Duration
        
        $bottleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 60, 30))
        $g.FillRectangle($bottleBrush, $cx - 25, $cy, 50, 100)
        $g.FillRectangle($bottleBrush, $cx - 12, $cy - 40, 24, 40)
        
        $shoulderPoints = @(
            [System.Drawing.Point]::new($cx - 25, $cy),
            [System.Drawing.Point]::new($cx - 12, $cy - 10),
            [System.Drawing.Point]::new($cx + 12, $cy - 10),
            [System.Drawing.Point]::new($cx + 25, $cy)
        )
        $g.FillPolygon($bottleBrush, $shoulderPoints)
        $bottleBrush.Dispose()
        
        $corkBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210, 180, 140))
        $g.FillRectangle($corkBrush, $cx - 10, $cy - 50, 20, 15)
        $corkBrush.Dispose()
        
        $wineLevel = $cy + 90 - ($progress * 80)
        $wineInBottle = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 100, 0, 0))
        $g.FillRectangle($wineInBottle, $cx - 20, $wineLevel, 40, $cy + 90 - $wineLevel)
        $wineInBottle.Dispose()
        
        if ($progress -gt 0.5) {
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 222, 179))
            $g.FillRectangle($labelBrush, $cx - 20, $cy + 30, 40, 30)
            $labelBrush.Dispose()
            
            $labelFont = New-Object System.Drawing.Font("Script MT Bold", 8)
            $labelTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(80, 40, 40))
            $g.DrawString("WINE", $labelFont, $labelTextBrush, $cx - 15, $cy + 35)
            $g.DrawString("✨ COMPANY", $labelFont, $labelTextBrush, $cx - 18, $cy + 45)
            $labelFont.Dispose()
            $labelTextBrush.Dispose()
        }
    }

    hidden [void] RenderGlassStage([System.Drawing.Graphics]$g, [int]$cx, [int]$cy) {
        $progress = $this.State.StageProgress / $this.State.Stages[5].Duration
        
        $glassBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 200, 220, 240))
        $bowlPoints = @(
            [System.Drawing.Point]::new($cx - 40, $cy - 20),
            [System.Drawing.Point]::new($cx - 35, $cy + 40),
            [System.Drawing.Point]::new($cx + 35, $cy + 40),
            [System.Drawing.Point]::new($cx + 40, $cy - 20)
        )
        $g.FillPolygon($glassBrush, $bowlPoints)
        $g.FillRectangle($glassBrush, $cx - 3, $cy + 40, 6, 30)
        $g.FillEllipse($glassBrush, $cx - 20, $cy + 65, 40, 10)
        $glassBrush.Dispose()
        
        $wineLevel = $cy + 35 - ($progress * 45)
        $wineGlassBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 120, 0, 30))
        $winePoints = @(
            [System.Drawing.Point]::new($cx - 35 + (5 * (1 - $progress)), $wineLevel),
            [System.Drawing.Point]::new($cx - 35, $cy + 40),
            [System.Drawing.Point]::new($cx + 35, $cy + 40),
            [System.Drawing.Point]::new($cx + 35 - (5 * (1 - $progress)), $wineLevel)
        )
        $g.FillPolygon($wineGlassBrush, $winePoints)
        $wineGlassBrush.Dispose()
        
        if ($progress -lt 0.8) {
            $streamBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 100, 0, 30))
            $g.FillRectangle($streamBrush, $cx - 5, $cy - 80, 10, 60)
            $streamBrush.Dispose()
        }
    }

    hidden [void] UpdateWineJourney() {
        $stage = $this.State.Stages[$this.State.CurrentStage]
        $this.State.StageProgress++
        
        # PRESS stage particles
        if ($stage.Name -eq "PRESS" -and $this.Particles.Count -lt 20 -and ($this.TickCount % 3 -eq 0)) {
            $null = $this.Particles.Add(@{
                X = 325 + (Get-Random -Minimum -5 -Maximum 5)
                Y = 260
                VY = 2 + (Get-Random -Minimum 0 -Maximum 20) / 10.0
                Life = 50
            })
        }
        
        # Update particles
        $alive = [System.Collections.ArrayList]::new()
        foreach ($p in $this.Particles) {
            $p.Y += $p.VY
            $p.Life -= 1
            if ($p.Life -gt 0) {
                [void]$alive.Add($p)
            }
        }
        $this.Particles.Clear()
        foreach ($p in $alive) {
            [void]$this.Particles.Add($p)
        }
        
        # Next stage
        if ($this.State.StageProgress -ge $stage.Duration) {
            $this.State.CurrentStage++
            if ($this.State.CurrentStage -ge $this.State.Stages.Count) {
                $this.State.CurrentStage = 0
            }
            $this.State.StageProgress = 0
            $this.Particles.Clear()
            if ($this.MessageLabel) {
                $this.MessageLabel.Text = $this.State.Stages[$this.State.CurrentStage].Message
            }
        }
    }
}

# Legacy compatibility
function Stop-Show18 {
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show18")) {
        $Global:ShowManager.Shows["show18"].Stop()
    }
}

Write-Host "HQshow18 FULLY LOADED - 6 Stages + Dashboard + 20 FPS!" -ForegroundColor Green
