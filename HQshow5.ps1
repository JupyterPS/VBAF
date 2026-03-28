# ====================================================
# HQshow5.ps1 — Algorithm Race Track v3
# Converted to Game Machine Architecture
# ZERO VISUAL CHANGES - Looks identical to V1
# ====================================================
Write-Host "`n=> _____ HQshow5 (Algorithm Race v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show5 - Inherits from BaseShow
# ============================================
class Show5 : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Racers
    hidden [System.Collections.ArrayList] $TrackParticles
    hidden [System.Collections.ArrayList] $BoostEffects
    
    # ========================================
    # Constructor
    # ========================================
    Show5([System.Windows.Forms.Panel]$panel) : base("show5", $panel) {
        $this.State = @{
            TickCount = 0
            RaceStarted = $false
            RaceComplete = $false
            Winner = $null
            TickerOffset = 0
        }
        $this.Racers = [System.Collections.ArrayList]::new()
        $this.TrackParticles = [System.Collections.ArrayList]::new()
        $this.BoostEffects = [System.Collections.ArrayList]::new()
    }
    
    # ========================================
    # OnStart - Called when show activates
    # ========================================
    [void] OnStart() {
        Write-Host " 🏎️ [Show5] Initializing Algorithm Race Track..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(15, 20, 30)
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Update ticker messages
        $Show5Messages = @(
            "🏎️ ALGORITHM RACE TRACK - ML Performance Competition",
            "🤖 Watch AI algorithms compete in real-time training",
            "📊 Faster convergence = Higher speed on the track",
            "🏁 Who will reach optimal accuracy first?"
        )
        $Global:messages = $Show5Messages
        
        # Initialize racers
        $this.InitializeRacers()
        
        # Setup paint event
        $this.SetupPaintEvent()
        
        Write-Host " ✅ [Show5] Algorithm Race Track ready" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Called every frame (~50ms)
    # ========================================
    [void] OnUpdate() {
        $this.State.TickCount++
        $tick = $this.State.TickCount
        
        # Update ticker scroll
        $this.State.TickerOffset += 2
        if ($this.State.TickerOffset -gt 800) { $this.State.TickerOffset = 0 }
        
        # Start race after delay
        if ($tick -gt 20) { $this.State.RaceStarted = $true }
        
        # Update racers
        foreach ($racer in $this.Racers) {
            if (-not $racer.Finished -and $this.State.RaceStarted) {
                $speedVariation = (Get-Random -Minimum -5 -Maximum 15) / 100.0
                $racer.CurrentSpeed = $racer.BaseSpeed + $speedVariation
                
                # Random boost
                if ((Get-Random -Minimum 0 -Maximum 100) -lt 3) {
                    $racer.Boost = 1.0
                    $racer.CurrentSpeed *= 2
                    
                    [void]$this.BoostEffects.Add(@{
                        X = $racer.X
                        Y = $racer.Y
                        Size = 20
                        Life = 50
                    })
                }
                
                # Move racer
                $racer.X += $racer.CurrentSpeed
                $racer.Progress = [math]::Min(100, ($racer.X / 550) * 100)
                
                # Spawn trail
                if ($tick % 3 -eq 0) {
                    [void]$racer.TrailParticles.Add(@{
                        X = $racer.X
                        Y = $racer.Y
                        Life = 50
                    })
                }
                
                # Update trail particles
                $aliveTrail = [System.Collections.ArrayList]::new()
                foreach ($trail in $racer.TrailParticles) {
                    $trail.Life -= 1
                    if ($trail.Life -gt 0) { [void]$aliveTrail.Add($trail) }
                }
                $racer.TrailParticles = $aliveTrail
                
                # Decay boost
                if ($racer.Boost -gt 0) { $racer.Boost -= 0.05 }
                
                # Check finish
                if ($racer.X -gt 520 -and -not $racer.Finished) {
                    $racer.Finished = $true
                    if (-not $this.State.Winner) {
                        $this.State.Winner = $racer.Name
                        Write-Host "🏆 WINNER: $($racer.Name)!" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        # Update boost effects
        $aliveBoosts = [System.Collections.ArrayList]::new()
        foreach ($boost in $this.BoostEffects) {
            $boost.Life -= 1
            $boost.Size += 2
            if ($boost.Life -gt 0) { [void]$aliveBoosts.Add($boost) }
        }
        $this.BoostEffects = $aliveBoosts
        
        # Reset race if all finished
        $unfinished = ($this.Racers | Where-Object { -not $_.Finished }).Count
        if ($unfinished -eq 0 -and $tick -gt 50) {
            Start-Sleep -Milliseconds 2000
            foreach ($racer in $this.Racers) {
                $racer.X = 50
                $racer.Progress = 0
                $racer.Finished = $false
                $racer.TrailParticles.Clear()
            }
            $this.State.Winner = $null
            $this.State.TickCount = 0
            $this.State.RaceStarted = $false
        }
        
        # Trigger repaint
        $this.Panel.Invalidate()
    }
    
    # ========================================
    # OnStop - Called when show deactivates
    # ========================================
    [void] OnStop() {
        Write-Host " 🛑 [Show5] Cleaning up..." -ForegroundColor Yellow
        
        # Clear collections
        $this.Racers.Clear()
        $this.TrackParticles.Clear()
        $this.BoostEffects.Clear()
        
        # Reset state
        $this.State.TickCount = 0
        $this.State.RaceStarted = $false
        $this.State.Winner = $null
        $this.State.TickerOffset = 0
        
        # Remove paint event
        $this.Panel.Remove_Paint($null)
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        Write-Host " ✅ [Show5] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    hidden [void] InitializeRacers() {
        $algorithms = @(
            @{Name="CNN"; Color=[System.Drawing.Color]::FromArgb(255, 50, 50); Speed=2.0},
            @{Name="RNN"; Color=[System.Drawing.Color]::FromArgb(50, 150, 255); Speed=1.8},
            @{Name="Transformer"; Color=[System.Drawing.Color]::FromArgb(255, 200, 50); Speed=2.2},
            @{Name="LSTM"; Color=[System.Drawing.Color]::FromArgb(150, 50, 255); Speed=1.9},
            @{Name="GAN"; Color=[System.Drawing.Color]::FromArgb(50, 255, 150); Speed=1.7},
            @{Name="XGBoost"; Color=[System.Drawing.Color]::FromArgb(255, 100, 200); Speed=2.1}
        )
        
        $laneHeight = 50
        $startX = 50
        
        for ($i = 0; $i -lt $algorithms.Count; $i++) {
            $algo = $algorithms[$i]
            $laneY = 80 + ($i * $laneHeight)
            
            $racer = @{
                Name = $algo.Name
                Color = $algo.Color
                X = $startX
                Y = $laneY
                Lane = $i
                BaseSpeed = $algo.Speed
                CurrentSpeed = 0
                Progress = 0
                Accuracy = 0
                Boost = 0
                TrailParticles = [System.Collections.ArrayList]::new()
                Finished = $false
            }
            [void]$this.Racers.Add($racer)
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
        
        # Background
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(15, 20, 30),
            [System.Drawing.Color]::FromArgb(30, 20, 40)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()
        
        # Draw track
        $trackStartX = 40
        $trackEndX = $width - 100
        $laneHeight = 50
        
        for ($i = 0; $i -lt 6; $i++) {
            $laneY = 80 + ($i * $laneHeight)
            
            # Lane background
            $laneBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 40, 50, 70))
            $g.FillRectangle($laneBrush, $trackStartX, $laneY - 20, $trackEndX - $trackStartX, 40)
            $laneBrush.Dispose()
            
            # Lane dividers
            $dividerPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(80, 255, 255, 255), 1)
            $dividerPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
            $g.DrawLine($dividerPen, $trackStartX, $laneY + 20, $trackEndX, $laneY + 20)
            $dividerPen.Dispose()
            
            # Animated checkered pattern
            for ($x = $trackStartX; $x -lt $trackEndX; $x += 40) {
                $offset = [int]($this.State.TickCount * 2) % 40
                $checkerX = $x - $offset
                if (($x / 40) % 2 -eq 0) {
                    $checkerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 255, 255, 255))
                    $g.FillRectangle($checkerBrush, $checkerX, $laneY - 20, 20, 40)
                    $checkerBrush.Dispose()
                }
            }
        }
        
        # Finish line
        $finishX = $trackEndX - 30
        for ($y = 60; $y -lt 380; $y += 20) {
            for ($x = 0; $x -lt 30; $x += 20) {
                if ((([int]($y/20)) + ([int]($x/20))) % 2 -eq 0) {
                    $checkerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                } else {
                    $checkerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
                }
                $g.FillRectangle($checkerBrush, $finishX + $x, $y, 20, 20)
                $checkerBrush.Dispose()
            }
        }
        
        # Draw boost effects
        foreach ($boost in $this.BoostEffects) {
            $alpha = [math]::Min(255, $boost.Life * 5)
            for ($r = 0; $r -lt 3; $r++) {
                $ringSize = $boost.Size + ($r * 10)
                $ringAlpha = [int]($alpha / (1 + $r))
                $ringColor = [System.Drawing.Color]::FromArgb($ringAlpha, 255, 200, 0)
                $ringPen = New-Object System.Drawing.Pen($ringColor, 2)
                $g.DrawEllipse($ringPen, $boost.X - $ringSize/2, $boost.Y - $ringSize/2, $ringSize, $ringSize)
                $ringPen.Dispose()
            }
        }
        
        # Draw racers
        foreach ($racer in $this.Racers) {
            $x = $racer.X
            $y = $racer.Y
            
            # Trail particles
            foreach ($trail in $racer.TrailParticles) {
                if ($trail.Life -gt 0) {
                    $trailAlpha = [math]::Min(200, $trail.Life * 4)
                    $trailColor = [System.Drawing.Color]::FromArgb($trailAlpha, $racer.Color.R, $racer.Color.G, $racer.Color.B)
                    $trailBrush = New-Object System.Drawing.SolidBrush($trailColor)
                    $g.FillEllipse($trailBrush, $trail.X - 3, $trail.Y - 3, 6, 6)
                    $trailBrush.Dispose()
                }
            }
            
            # Boost glow
            if ($racer.Boost -gt 0) {
                $glowSize = 40 + ($racer.Boost * 20)
                $glowAlpha = [int]([math]::Min(150, $racer.Boost * 100))
                $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($glowAlpha, 255, 200, 0))
                $g.FillEllipse($glowBrush, $x - $glowSize/2, $y - $glowSize/2, $glowSize, $glowSize)
                $glowBrush.Dispose()
            }
            
            # Car body
            $carWidth = 35
            $carHeight = 20
            $carBrush = New-Object System.Drawing.SolidBrush($racer.Color)
            $g.FillEllipse($carBrush, $x - $carWidth/2, $y - $carHeight/2, $carWidth, $carHeight)
            $carBrush.Dispose()
            
            # Car highlight
            $highlightBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 255, 255, 255))
            $g.FillEllipse($highlightBrush, $x - 8, $y - 8, 16, 16)
            $highlightBrush.Dispose()
            
            # Algorithm name
            $nameFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $nameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
            $nameSize = $g.MeasureString($racer.Name, $nameFont)
            $g.DrawString($racer.Name, $nameFont, $nameBrush, $x - $nameSize.Width/2, $y - 25)
            $nameFont.Dispose()
            $nameBrush.Dispose()
            
            # Stats below
            $statsFont = New-Object System.Drawing.Font("Consolas", 7)
            $statsBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 100, 255, 100))
            $statsText = "$([int]($racer.Progress))%"
            $g.DrawString($statsText, $statsFont, $statsBrush, $x - 10, $y + 15)
            $statsFont.Dispose()
            $statsBrush.Dispose()
        }
        
        # Bottom ticker
        $tickerHeight = 35
        $tickerY = $height - $tickerHeight - 5
        
        # Ticker background
        $tickerBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
        $g.FillRectangle($tickerBg, 0, $tickerY, $width, $tickerHeight)
        $tickerBg.Dispose()
        
        # Ticker border
        $tickerBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 255, 215, 0), 2)
        $g.DrawRectangle($tickerBorder, 0, $tickerY, $width - 1, $tickerHeight - 1)
        $tickerBorder.Dispose()
        
        # Build ticker text with leaderboard
        $sorted = $this.Racers | Sort-Object -Property Progress -Descending
        $tickerText = " LEADERBOARD: "
        $rank = 1
        foreach ($racer in $sorted) {
            $tickerText += "$rank. $($racer.Name) ($([int]$racer.Progress)%) • "
            $rank++
        }
        
        if ($this.State.Winner) {
            $tickerText += "    WINNER: $($this.State.Winner)! • "
        }
        $tickerText += "   |   "
        
        # Draw scrolling ticker text
        $tickerFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $tickerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 0))
        
        $textSize = $g.MeasureString($tickerText, $tickerFont)
        $tickerX = $width - $this.State.TickerOffset
        
        # Draw text twice for seamless loop
        $g.DrawString($tickerText, $tickerFont, $tickerBrush, $tickerX, $tickerY + 8)
        $g.DrawString($tickerText, $tickerFont, $tickerBrush, $tickerX + $textSize.Width, $tickerY + 8)
        
        $tickerFont.Dispose()
        $tickerBrush.Dispose()
        
        # Title
        $titleMainFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleMainBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 255, 215, 0))
        $titleText = "✨ ALGORITHM RACE TRACK"
        $titleSize = $g.MeasureString($titleText, $titleMainFont)
        $g.DrawString($titleText, $titleMainFont, $titleMainBrush, ($width - $titleSize.Width) / 2, 10)
        $titleMainFont.Dispose()
        $titleMainBrush.Dispose()
        
        # Race status
        if ($this.State.Winner) {
            $winFont = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
            $winBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 215, 0))
            $winText = "WINNER: $($this.State.Winner)!"
            $winSize = $g.MeasureString($winText, $winFont)
            $g.DrawString($winText, $winFont, $winBrush, ($width - $winSize.Width) / 2, 35)
            $winFont.Dispose()
            $winBrush.Dispose()
        }
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show5 {
    Write-Host "🛑 [Show5] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show5")) {
        $show = $Global:ShowManager.Shows["show5"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show5] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow5 class loaded (v3)" -ForegroundColor Green
