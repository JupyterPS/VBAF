# ====================================================
# HQshow6.ps1 — AI Research Lab v3
# Converted to Game Machine Architecture
# ====================================================
Write-Host "`n=> _____ HQshow6 (AI Research Lab v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show6 - Inherits from BaseShow
# ============================================
class Show6 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Experiments
    hidden [System.Collections.ArrayList] $Papers
    
    # ========================================
    # Constructor
    # ========================================
    Show6([System.Windows.Forms.Panel]$panel) : base("show6", $panel) {
        $this.State = @{
            BreakthroughFlash = $null
            TickCount = 0
            BreakthroughCount = 0
        }
        $this.Experiments = [System.Collections.ArrayList]::new()
        $this.Papers = [System.Collections.ArrayList]::new()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host "[Show6] Initializing AI Research Lab..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(30, 38, 50)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Update ticker messages
        $Show6Messages = @(
            "AI RESEARCH LAB - Innovation in Progress",
            "Multiple experiments running simultaneously",
            "Hypothesis testing with real-time results",
            "Breakthroughs lead to published research",
            "Advancing the frontier of artificial intelligence"
        )
        $Global:messages = $Show6Messages
        
        # Initialize experiments
        $this.InitializeExperiments()
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host " ✅ [Show6] AI Research Lab ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~100ms)
    # ========================================
    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        # Update experiments
        foreach ($exp in $this.Experiments) {
            if ($exp.Status -eq "Running") {
                $exp.Progress += (Get-Random -Minimum 1 -Maximum 4) / 2.0
                
                if ($exp.Progress -ge 100) {
                    $exp.Progress = 100
                    
                    $successRoll = (Get-Random -Minimum 0 -Maximum 100) / 100.0
                    if ($successRoll -lt $exp.BaseSuccess) {
                        $exp.Status = "Success"
                        $exp.ResultValue = 0.8 + (Get-Random -Minimum 0 -Maximum 20) / 100.0
                        
                        # Spawn celebration particles
                        for ($i = 0; $i -lt 15; $i++) {
                            [void]$exp.Particles.Add(@{
                                X = $exp.X + ($exp.Width / 2) + (Get-Random -Minimum -30 -Maximum 30)
                                Y = $exp.Y + ($exp.Height / 2)
                                VY = -2 - (Get-Random -Minimum 0 -Maximum 20) / 10.0
                                Life = 50
                            })
                        }
                        
                        # Check for breakthrough
                        if ($exp.ResultValue -gt 0.9) {
                            $this.State.BreakthroughCount++
                            $this.State.BreakthroughFlash = @{ Life = 50 }
                            
                            $paperTitles = @(
                                "Novel Approach to $($exp.Name) Optimization",
                                "Breakthrough in $($exp.Name) Architecture",
                                "Advancing $($exp.Name) Performance Metrics",
                                "Revolutionary $($exp.Name) Methodology"
                            )
                            [void]$this.Papers.Add(@{
                                Title = $paperTitles | Get-Random
                                Alpha = 0
                            })
                        }
                        
                    } else {
                        $exp.Status = "Failed"
                        $exp.ResultValue = 0.3 + (Get-Random -Minimum 0 -Maximum 30) / 100.0
                    }
                }
                
                $exp.Pulse = [math]::Abs([math]::Sin($tick * 0.1))
            }
            
            # Update particles
            $alive = [System.Collections.ArrayList]::new()
            foreach ($p in $exp.Particles) {
                $p.Y += $p.VY
                $p.Life -= 1
                if ($p.Life -gt 0) { [void]$alive.Add($p) }
            }
            $exp.Particles = $alive
        }
        
        # Reset completed experiments
        if ($tick % 80 -eq 0) {
            foreach ($exp in $this.Experiments) {
                if ($exp.Status -ne "Running") {
                    $exp.Status = "Running"
                    $exp.Progress = 0
                    $exp.ResultValue = 0
                    $exp.Particles.Clear()
                }
            }
        }
        
        # Update breakthrough flash
        if ($this.State.BreakthroughFlash) {
            $this.State.BreakthroughFlash.Life -= 1
            if ($this.State.BreakthroughFlash.Life -le 0) {
                $this.State.BreakthroughFlash = $null
            }
        }
        
        # Fade in papers
        foreach ($paper in $this.Papers) {
            if ($paper.Alpha -lt 255) { $paper.Alpha += 5 }
        }
        
        # Limit papers
        if ($this.Papers.Count -gt 5) {
            $this.Papers.RemoveAt(0)
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host " 🛑 [Show6] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        foreach ($exp in $this.Experiments) {
            $exp.Particles.Clear()
        }
        $this.Papers.Clear()
        
        # Reset state
        $this.State.TickCount = 0
        $this.State.BreakthroughCount = 0
        $this.State.BreakthroughFlash = $null
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        Write-Host " ✅ [Show6] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    hidden [void] InitializeExperiments() {
        $experimentTypes = @(
            @{Name="Deep Learning"; Icon="🧠"; BaseSuccess=0.7},
            @{Name="Computer Vision"; Icon="👁️"; BaseSuccess=0.6},
            @{Name="NLP Model"; Icon="💬"; BaseSuccess=0.65},
            @{Name="Reinforcement"; Icon="🎮"; BaseSuccess=0.5},
            @{Name="Neural Architecture"; Icon="🏗️"; BaseSuccess=0.55}
        )
        
        $xPositions = @(10, 136, 266, 390, 520)
        
        for ($i = 0; $i -lt $experimentTypes.Count; $i++) {
            $expType = $experimentTypes[$i]
            $exp = @{
                Name = $expType.Name
                Icon = $expType.Icon
                X = $xPositions[$i]
                Y = 100
                Width = 120
                Height = 140
                Progress = 0
                Status = "Running"
                ResultValue = 0
                BaseSuccess = $expType.BaseSuccess
                Pulse = 0
                Particles = [System.Collections.ArrayList]::new()
            }
            [void]$this.Experiments.Add($exp)
        }
    }
    
    # Setup paint event
    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderScene($s, $e.Graphics)
        }.GetNewClosure())
    }
    
    # Main render method (EXACT V1 LOGIC)
    hidden [void] RenderScene([object]$sender, [System.Drawing.Graphics]$g) {
        $width = $sender.Width
        $height = $sender.Height
        
        if ($width -le 0 -or $height -le 0) { return }
        
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        # Title
        $titleFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        #$titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 210, 230))
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 180, 0))
        $titleText = "✨ AI RESEARCH LAB"
        $titleSize = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 20)
        $titleFont.Dispose()
        $titleBrush.Dispose()
        
        # Draw experiments
        foreach ($exp in $this.Experiments) {
            $x = $exp.X
            $y = $exp.Y
            $w = $exp.Width
            $h = $exp.Height
            
            # Experiment box background
            $boxColor = switch ($exp.Status) {
                "Running" { [System.Drawing.Color]::FromArgb(40, 50, 70) }
                "Success" { [System.Drawing.Color]::FromArgb(50, 80, 50) }
                "Failed" { [System.Drawing.Color]::FromArgb(80, 40, 40) }
            }
            $boxBrush = New-Object System.Drawing.SolidBrush($boxColor)
            $g.FillRectangle($boxBrush, $x, $y, $w, $h)
            $boxBrush.Dispose()
            
            # Border with status color
            $borderColor = switch ($exp.Status) {                
                "Running" { [System.Drawing.Color]::FromArgb(255, 215, 0) }
                "Success" { [System.Drawing.Color]::FromArgb(80, 220, 80) }
                "Failed" { [System.Drawing.Color]::FromArgb(255, 80, 80) }
            }
            $borderPen = New-Object System.Drawing.Pen($borderColor, 3)
            $g.DrawRectangle($borderPen, $x, $y, $w, $h)
            $borderPen.Dispose()
            
            # Experiment icon
            $iconFont = New-Object System.Drawing.Font("Segoe UI Emoji", 24)            
            $iconBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 0))
            $iconSize = $g.MeasureString($exp.Icon, $iconFont)
            $g.DrawString($exp.Icon, $iconFont, $iconBrush, $x + ($w - $iconSize.Width) / 2, $y + 10)
            $iconFont.Dispose()
            $iconBrush.Dispose()
            
            # Experiment name
            $nameFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $nameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 210, 230))
            $nameSize = $g.MeasureString($exp.Name, $nameFont)
            $g.DrawString($exp.Name, $nameFont, $nameBrush, $x + ($w - $nameSize.Width) / 2, $y + 50)
            $nameFont.Dispose()
            $nameBrush.Dispose()
            
            # Progress bar
            $progressY = $y + 75
            $progressBarBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 70, 80))
            $g.FillRectangle($progressBarBg, $x + 10, $progressY, $w - 20, 15)
            $progressBarBg.Dispose()
            
            $progressWidth = ($exp.Progress / 100.0) * ($w - 20)
            $progressColor = switch ($exp.Status) {
                "Running" { [System.Drawing.Color]::FromArgb(100, 150, 255) }
                "Success" { [System.Drawing.Color]::FromArgb(50, 200, 50) }
                "Failed" { [System.Drawing.Color]::FromArgb(255, 100, 100) }
            }
            $progressBrush = New-Object System.Drawing.SolidBrush($progressColor)
            $g.FillRectangle($progressBrush, $x + 10, $progressY, $progressWidth, 15)
            $progressBrush.Dispose()
            
            # Progress percentage
            $progFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Bold)
            $progBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(230, 230, 230))
            $progText = "$([math]::Round($exp.Progress))%"
            $progSize = $g.MeasureString($progText, $progFont)
            $g.DrawString($progText, $progFont, $progBrush, $x + ($w - $progSize.Width) / 2, $progressY + 2)
            $progFont.Dispose()
            $progBrush.Dispose()
            
            # Status indicator
            $statusY = $y + 100
            $statusFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $statusColor = switch ($exp.Status) {               
                "Running" { [System.Drawing.Color]::FromArgb(244, 233, 140) }
                "Success" { [System.Drawing.Color]::FromArgb(80, 220, 80) }
                "Failed" { [System.Drawing.Color]::FromArgb(255, 80, 80) }
            }
            $statusBrush = New-Object System.Drawing.SolidBrush($statusColor)
            $statusText = switch ($exp.Status) {
                "Running" { "⚗️ Testing..." }
                "Success" { "✅ Success!" }
                "Failed"  { "❌ Failed" }
            }
            $statusSize = $g.MeasureString($statusText, $statusFont)
            $g.DrawString($statusText, $statusFont, $statusBrush, $x + ($w - $statusSize.Width) / 2, $statusY)
            $statusFont.Dispose()
            $statusBrush.Dispose()
            
            # Result value
            if ($exp.Status -ne "Running") {
                $resultFont = New-Object System.Drawing.Font("Consolas", 9)
                $resultBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 200, 200))
                $resultText = "Score: $([math]::Round($exp.ResultValue, 2))"
                $resultSize = $g.MeasureString($resultText, $resultFont)
                $g.DrawString($resultText, $resultFont, $resultBrush, $x + ($w - $resultSize.Width) / 2, $y + 120)
                $resultFont.Dispose()
                $resultBrush.Dispose()
            }
            
            # Particles
            foreach ($particle in $exp.Particles) {
                $alpha = [math]::Min(255, $particle.Life * 3)
                $pColor = [System.Drawing.Color]::FromArgb($alpha, 255, 215, 0)
                $pBrush = New-Object System.Drawing.SolidBrush($pColor)
                $g.FillEllipse($pBrush, $particle.X, $particle.Y, 6, 6)
                $pBrush.Dispose()
            }
        }
        
        # Published papers
        $paperY = 260
        $paperFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $paperTitleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 210, 230))
        $g.DrawString("PUBLISHED RESEARCH:", $paperFont, $paperTitleBrush, 20, $paperY)
        $paperFont.Dispose()
        $paperTitleBrush.Dispose()
        
        $paperListY = $paperY + 30
        foreach ($paper in $this.Papers) {
            if ($paper.Alpha -gt 0) {
                $alpha = [math]::Min(255, $paper.Alpha)
                $pFont = New-Object System.Drawing.Font("Georgia", 9, [System.Drawing.FontStyle]::Italic)
                $pBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 210, 220, 240))
                $g.DrawString("• $($paper.Title)", $pFont, $pBrush, 30, $paperListY)
                $pFont.Dispose()
                $pBrush.Dispose()
                $paperListY += 25
            }
        }
        
        # Breakthrough flash
        if ($this.State.BreakthroughFlash) {
            $flash = $this.State.BreakthroughFlash
            $alpha = [math]::Min(255, $flash.Life * 5)
            
            $flashBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha/3, 255, 215, 0))
            $g.FillRectangle($flashBg, 0, 0, $width, 80)
            $flashBg.Dispose()
            
            $flashFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $flashBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 180, 0))
            $flashText = "BREAKTHROUGH ACHIEVED!"
            $flashSize = $g.MeasureString($flashText, $flashFont)
            $g.DrawString($flashText, $flashFont, $flashBrush, ($width - $flashSize.Width) / 2, 45)
            $flashFont.Dispose()
            $flashBrush.Dispose()
        }
        
        # Stats
        $statsFont = New-Object System.Drawing.Font("Consolas", 9)
        $statsBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 180, 180))
        $runningCount = ($this.Experiments | Where-Object { $_.Status -eq "Running" }).Count
        $successCount = ($this.Experiments | Where-Object { $_.Status -eq "Success" }).Count
        $failedCount = ($this.Experiments | Where-Object { $_.Status -eq "Failed" }).Count
        $statsText = "Running: $runningCount | Succeeded: $successCount | Failed: $failedCount | Breakthroughs: $($this.State.BreakthroughCount)"
        $g.DrawString($statsText, $statsFont, $statsBrush, 20, $height - 30)
        $statsFont.Dispose()
        $statsBrush.Dispose()
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show6 {
    Write-Host "[Show6] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show6")) {
        $show = $Global:ShowManager.Shows["show6"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show6] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow6 class loaded (v3)" -ForegroundColor Green

