# ====================================================
# HQshow30.ps1 — Risk RADAR v3
# Commerce Bank: Real-time Risk Assessment
# Converted to Game Machine Architecture
# ====================================================

# ============================================
# Show30 - Inherits from BaseShow
# ============================================
class Show30 : BaseShow {
    hidden [System.Collections.ArrayList] $Transactions
    hidden [System.Collections.ArrayList] $Threats
    hidden [System.Collections.ArrayList] $CreditScores
    hidden [System.Collections.ArrayList] $SystemMeters
    hidden [hashtable] $State
    hidden [System.Windows.Forms.Panel] $Canvas

    Show30([System.Windows.Forms.Panel]$panel) : base("show30", $panel) {
        $this.State = @{
            RadarAngle = 0
            TickCount = 0
            ThreatLevel = 0
            AlertActive = $false
            AlertFlash = 0
            BlockedThreats = 0
        }
        $this.Transactions = [System.Collections.ArrayList]::new()
        $this.Threats = [System.Collections.ArrayList]::new()
        $this.CreditScores = [System.Collections.ArrayList]::new()
        $this.SystemMeters = [System.Collections.ArrayList]::new()
    }

    [void] OnStart() {
        Write-Host " 🎯 [Show30] Initializing Risk Radar..." -ForegroundColor Yellow
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 15)
        
        # Ticker messages
        $Show30Messages = @(
            "🎯 RISK RADAR - 360° Security Monitoring Active",
            "🛡️ Real-time threat detection and risk assessment",
            "⚠️ Protecting Commerce Bank assets 24/7",
            "🔒 Advanced fraud prevention systems online"
        )
        $global:messages = $Show30Messages
        Update-Ticker
        
        # Create canvas
        $this.Canvas = New-Object System.Windows.Forms.Panel
        $this.Canvas.Dock = "Fill"
        $this.Canvas.BackColor = [System.Drawing.Color]::FromArgb(5, 5, 15)
        $prop = $this.Canvas.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Canvas, $true, $null) }
        $this.Panel.Controls.Add($this.Canvas)
        
        # Initialize data
        $this.InitializeSecuritySystems()
        $this.SetupPaintEvent()
        
        Write-Host " ✅ [Show30] Risk Radar ready" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        # Rotate radar
        $this.State.RadarAngle = ($this.State.RadarAngle + 3) % 360
        
        # Spawn transactions
        if ($tick % 15 -eq 0) {
            $riskLevels = @("Low", "Low", "Low", "Medium", "High")
            $riskLevel = $riskLevels | Get-Random
            
            [void]$this.Transactions.Add(@{
                Angle = Get-Random -Minimum 0 -Maximum 360
                Distance = Get-Random -Minimum 50 -Maximum 170
                Life = 100
                RiskLevel = $riskLevel
            })
        }
        
        # Update transactions
        $toRemove = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $this.Transactions.Count; $i++) {
            $trans = $this.Transactions[$i]
            $trans.Life -= 1
            
            if ($trans.Life -le 0) {
                [void]$toRemove.Add($i)
            }
        }
        for ($i = $toRemove.Count - 1; $i -ge 0; $i--) {
            $this.Transactions.RemoveAt($toRemove[$i])
        }
        
        while ($this.Transactions.Count -gt 60) {
            $this.Transactions.RemoveAt(0)
        }
        
        # Spawn threats
        if ($tick % 80 -eq 0 -and (Get-Random -Minimum 0 -Maximum 10) -gt 6) {
            [void]$this.Threats.Add(@{
                Angle = Get-Random -Minimum 0 -Maximum 360
                Distance = 200
                Speed = 2 + (Get-Random -Minimum 0 -Maximum 10) / 10.0
                Pulse = 0
                Active = $true
            })
            
            $this.State.AlertActive = $true
            $this.State.ThreatLevel = [math]::Min(100, $this.State.ThreatLevel + 20)
        }
        
        # Update threats
        $toRemoveThreats = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $this.Threats.Count; $i++) {
            $threat = $this.Threats[$i]
            
            if ($threat.Active) {
                $threat.Distance -= $threat.Speed
                $threat.Pulse = [math]::Abs([math]::Sin($tick * 0.2))
                
                if ($threat.Distance -lt 50) {
                    $threat.Active = $false
                    $this.State.BlockedThreats++
                    [void]$toRemoveThreats.Add($i)
                }
            }
        }
        for ($i = $toRemoveThreats.Count - 1; $i -ge 0; $i--) {
            $this.Threats.RemoveAt($toRemoveThreats[$i])
        }
        
        # Decay threat level
        $this.State.ThreatLevel = [math]::Max(0, $this.State.ThreatLevel - 0.5)
        
        if ($this.Threats.Count -eq 0) {
            $this.State.AlertActive = $false
        }
        
        $this.State.AlertFlash++
        
        # Spawn credit scores
        if ($tick % 60 -eq 0) {
            [void]$this.CreditScores.Add(@{
                X = Get-Random -Minimum 50 -Maximum 550
                Y = Get-Random -Minimum 350 -Maximum 380
                Value = Get-Random -Minimum 550 -Maximum 850
                Life = 80
                Pulse = 0
                VY = -0.5
            })
        }
        
        # Update credit scores
        $toRemoveScores = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $this.CreditScores.Count; $i++) {
            $score = $this.CreditScores[$i]
            
            $score.Y += $score.VY
            $score.Life -= 1
            $score.Pulse = [math]::Abs([math]::Sin($tick * 0.1 + $i))
            
            if ($score.Life -le 0) {
                [void]$toRemoveScores.Add($i)
            }
        }
        for ($i = $toRemoveScores.Count - 1; $i -ge 0; $i--) {
            $this.CreditScores.RemoveAt($toRemoveScores[$i])
        }
        
        # Update system meters
        foreach ($meter in $this.SystemMeters) {
            if ($tick % 50 -eq 0) {
                $change = (Get-Random -Minimum -5 -Maximum 3)
                $meter.Health = [math]::Max(70, [math]::Min(100, $meter.Health + $change))
            }
            $meter.Pulse = [math]::Abs([math]::Sin($tick * 0.05))
        }
        
        # Repaint
        $this.Canvas.Invalidate()
    }

    [void] OnStop() {
        Write-Host " 🛑 [Show30] Cleaning up Risk Radar..." -ForegroundColor Yellow
        
        $this.Transactions.Clear()
        $this.Threats.Clear()
        $this.CreditScores.Clear()
        $this.SystemMeters.Clear()
        
        if ($this.Canvas) {
            $this.Canvas.Remove_Paint($null)
        }
        $this.Panel.Controls.Clear()
        
        $this.State.RadarAngle = 0
        $this.State.TickCount = 0
        $this.State.ThreatLevel = 0
        $this.State.AlertActive = $false
        $this.State.AlertFlash = 0
        $this.State.BlockedThreats = 0
        
        Write-Host " ✅ [Show30] Cleanup complete" -ForegroundColor Green
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Canvas.Add_Paint({
            param($sender, $e)
            $self.RenderFrame($e.Graphics, $sender.Width, $sender.Height)
        }.GetNewClosure())
    }

    hidden [void] InitializeSecuritySystems() {
        $meterNames = @("Firewall", "Encryption", "Auth", "Monitor", "Backup")
        $angle = 0
        $angleStep = 360 / $meterNames.Count
        
        foreach ($name in $meterNames) {
            [void]$this.SystemMeters.Add(@{
                Name = $name
                Health = Get-Random -Minimum 85 -Maximum 100
                Angle = $angle
                Color = [System.Drawing.Color]::LimeGreen
                Pulse = 0
            })
            $angle += $angleStep
        }
    }

    hidden [void] RenderFrame([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $centerX = $width / 2
        $centerY = ($height / 2) - 20
        $maxRadius = 180
        
        # Radar rings
        $zones = @(
            @{Radius=45; Label="SAFE"; Color=[System.Drawing.Color]::FromArgb(30, 0, 255, 0)},
            @{Radius=90; Label="LOW"; Color=[System.Drawing.Color]::FromArgb(30, 100, 200, 0)},
            @{Radius=135; Label="MEDIUM"; Color=[System.Drawing.Color]::FromArgb(30, 255, 200, 0)},
            @{Radius=180; Label="HIGH"; Color=[System.Drawing.Color]::FromArgb(30, 255, 100, 0)}
        )
        
        foreach ($zone in $zones) {
            $zoneBrush = New-Object System.Drawing.SolidBrush($zone.Color)
            $g.FillEllipse($zoneBrush, $centerX - $zone.Radius, $centerY - $zone.Radius, $zone.Radius*2, $zone.Radius*2)
            $zoneBrush.Dispose()
            
            $ringPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 0, 255, 100), 2)
            $g.DrawEllipse($ringPen, $centerX - $zone.Radius, $centerY - $zone.Radius, $zone.Radius*2, $zone.Radius*2)
            $ringPen.Dispose()
            
            $labelFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 0, 255, 100))
            $labelSize = $g.MeasureString($zone.Label, $labelFont)
            $g.DrawString($zone.Label, $labelFont, $labelBrush, $centerX - $labelSize.Width/2, $centerY - $zone.Radius - 15)
            $labelFont.Dispose()
            $labelBrush.Dispose()
        }
        
        # Center vault
        $vaultSize = 30
        $vaultGlowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 255, 215, 0))
        $g.FillEllipse($vaultGlowBrush, $centerX - $vaultSize*1.5, $centerY - $vaultSize*1.5, $vaultSize*3, $vaultSize*3)
        $vaultGlowBrush.Dispose()
        
        $vaultBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Gold)
        $g.FillEllipse($vaultBrush, $centerX - $vaultSize, $centerY - $vaultSize, $vaultSize*2, $vaultSize*2)
        $vaultBrush.Dispose()
        
        $vaultFont = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
        $vaultTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
        $vaultText = "🏦"
        $vaultTextSize = $g.MeasureString($vaultText, $vaultFont)
        $g.DrawString($vaultText, $vaultFont, $vaultTextBrush, $centerX - $vaultTextSize.Width/2, $centerY - $vaultTextSize.Height/2)
        $vaultFont.Dispose()
        $vaultTextBrush.Dispose()
        
        # Radar sweep
        $radarAngleRad = $this.State.RadarAngle * [math]::PI / 180
        $radarEndX = $centerX + ($maxRadius * [math]::Cos($radarAngleRad))
        $radarEndY = $centerY + ($maxRadius * [math]::Sin($radarAngleRad))
        
        $sweepBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.PointF]::new($centerX, $centerY),
            [System.Drawing.PointF]::new($radarEndX, $radarEndY),
            [System.Drawing.Color]::FromArgb(200, 0, 255, 0),
            [System.Drawing.Color]::FromArgb(0, 0, 255, 0)
        )
        $sweepPen = New-Object System.Drawing.Pen($sweepBrush, 3)
        $g.DrawLine($sweepPen, $centerX, $centerY, $radarEndX, $radarEndY)
        $sweepPen.Dispose()
        $sweepBrush.Dispose()
        
        # Transactions
        foreach ($trans in $this.Transactions) {
            $alpha = [math]::Min(255, $trans.Life * 3)
            $transAngle = $trans.Angle * [math]::PI / 180
            $transX = $centerX + ($trans.Distance * [math]::Cos($transAngle))
            $transY = $centerY + ($trans.Distance * [math]::Sin($transAngle))
            
            $dotColor = if ($trans.RiskLevel -eq "Low") {
                [System.Drawing.Color]::FromArgb($alpha, 0, 255, 0)
            } elseif ($trans.RiskLevel -eq "Medium") {
                [System.Drawing.Color]::FromArgb($alpha, 255, 200, 0)
            } else {
                [System.Drawing.Color]::FromArgb($alpha, 255, 0, 0)
            }
            
            $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha/4, $dotColor.R, $dotColor.G, $dotColor.B))
            $g.FillEllipse($glowBrush, $transX - 6, $transY - 6, 12, 12)
            $glowBrush.Dispose()
            
            $dotBrush = New-Object System.Drawing.SolidBrush($dotColor)
            $g.FillEllipse($dotBrush, $transX - 3, $transY - 3, 6, 6)
            $dotBrush.Dispose()
        }
        
        # Threats
        foreach ($threat in $this.Threats) {
            if ($threat.Active) {
                $threatAngle = $threat.Angle * [math]::PI / 180
                $threatX = $centerX + ($threat.Distance * [math]::Cos($threatAngle))
                $threatY = $centerY + ($threat.Distance * [math]::Sin($threatAngle))
                
                $glowSize = 15 + ($threat.Pulse * 10)
                $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 255, 0, 0))
                $g.FillEllipse($glowBrush, $threatX - $glowSize, $threatY - $glowSize, $glowSize*2, $glowSize*2)
                $glowBrush.Dispose()
                
                $threatBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
                $g.FillEllipse($threatBrush, $threatX - 8, $threatY - 8, 16, 16)
                $threatBrush.Dispose()
            }
        }
        
        # Credit scores (simplified)
        foreach ($score in $this.CreditScores) {
            $alpha = [math]::Min(255, $score.Life * 3)
            $size = 15 + ($score.Pulse * 5)
            
            $scoreColor = if ($score.Value -gt 750) {
                [System.Drawing.Color]::FromArgb($alpha, 0, 255, 0)
            } elseif ($score.Value -gt 650) {
                [System.Drawing.Color]::FromArgb($alpha, 255, 200, 0)
            } else {
                [System.Drawing.Color]::FromArgb($alpha, 255, 100, 0)
            }
            
            $orbBrush = New-Object System.Drawing.SolidBrush($scoreColor)
            $g.FillEllipse($orbBrush, $score.X - $size, $score.Y - $size, $size*2, $size*2)
            $orbBrush.Dispose()
        }
        
        # System meters (simplified)
        $meterRadius = 220
        foreach ($meter in $this.SystemMeters) {
            $meterAngle = $meter.Angle * [math]::PI / 180
            $meterX = $centerX + ($meterRadius * [math]::Cos($meterAngle))
            $meterY = $centerY + ($meterRadius * [math]::Sin($meterAngle))
            
            $meterBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 20, 20, 20))
            $g.FillRectangle($meterBg, $meterX - 30, $meterY - 15, 60, 30)
            $meterBg.Dispose()
            
            $barWidth = ($meter.Health / 100.0) * 55
            $barColor = if ($meter.Health -gt 80) { [System.Drawing.Color]::LimeGreen } 
                       elseif ($meter.Health -gt 50) { [System.Drawing.Color]::Yellow } 
                       else { [System.Drawing.Color]::Red }
            
            $barBrush = New-Object System.Drawing.SolidBrush($barColor)
            $g.FillRectangle($barBrush, $meterX - 27, $meterY - 5, $barWidth, 10)
            $barBrush.Dispose()
        }
        
        # Alert banner
        if ($this.State.AlertActive) {
            $alertAlpha = [math]::Abs([math]::Sin($this.State.AlertFlash * 0.3)) * 200
            $alertBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alertAlpha, 255, 0, 0))
            $g.FillRectangle($alertBrush, 0, 0, $width, 40)
            $alertBrush.Dispose()
        }
        
        # Status panel
        $statusY = $height - 60
        $statusBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 10, 10, 10))
        $g.FillRectangle($statusBg, 0, $statusY, $width, 60)
        $statusBg.Dispose()
        
        $statusFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $threatColor = if ($this.State.ThreatLevel -gt 70) { [System.Drawing.Color]::Red }
                      elseif ($this.State.ThreatLevel -gt 40) { [System.Drawing.Color]::Orange }
                      else { [System.Drawing.Color]::LimeGreen }
        
        $threatBrush = New-Object System.Drawing.SolidBrush($threatColor)
        $g.DrawString("✨ THREAT LEVEL: $([math]::Round($this.State.ThreatLevel))%", $statusFont, $threatBrush, 20, $statusY + 10)
        $threatBrush.Dispose()
        
        $blockBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
        $g.DrawString("✨ BLOCKED: $($this.State.BlockedThreats)", $statusFont, $blockBrush, 20, $statusY + 32)
        $blockBrush.Dispose()
        
        $statusFont.Dispose()
    }
}

# Legacy compatibility
function Stop-Show30 {
    Write-Host "[Show30] Stop called (v3)" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show30")) {
        $Global:ShowManager.Shows["show30"].Stop()
    }
}

Write-Host "✅ COMPLETE Show30 v3 - Copy/Paste READY for ISE!" -ForegroundColor Green

