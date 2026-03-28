# ==============================================
# Show9 - AI Neural Prediction Engine (COMPLETE FIXED VERSION)
# FROZEN PICTURE SOLVED - READY TO TEST!
# ==============================================

class Show9 : BaseShow {
    hidden [System.Collections.ArrayList] $Nodes = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $Connections = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $Particles = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $PredictionOrbs = [System.Collections.ArrayList]::new()
    hidden [float] $ProcessingWave = 0
    hidden [int] $TickCount = 0
    hidden [int] $LastSpawn = 0
    hidden [float[]] $layerX = @(50, 200, 350, 500)
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    hidden [System.Windows.Forms.Panel] $Canvas  # FIXED: Canvas reference

    Show9([System.Windows.Forms.Panel]$panel) : base("show9", $panel) {
        $this.InitializeNeuralNetwork()
    }

    [void] OnStart() {
        Write-Host "🧠 [Show9] AI Neural Prediction Engine initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::Black
        
        # FIXED: Create drawing canvas + STORE REFERENCE
        $this.Canvas = New-Object System.Windows.Forms.Panel
        $this.Canvas.Dock = "Fill"
        $this.Canvas.BackColor = [System.Drawing.Color]::Black
        $prop = $this.Canvas.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Canvas, $true, $null) }
        $this.Panel.Controls.Add($this.Canvas)
        
        # Ticker messages
        $Show9Messages = @(
            "🧠 AI NEURAL PREDICTION ENGINE - Visualizing Intelligence",
            "⚡ Neural networks processing real-time predictions",
            "🔮 Watch the digital brain think and learn",
            "💡 Synaptic connections firing across the network"
        )
        $global:messages = $Show9Messages
        if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
        
        $this.SetupPaintEvent()
        $this.SetupVisibleChanged()
        $this.StartAnimationTimer()
        
        Write-Host "✅ [Show9] Neural net ready: $($this.Nodes.Count) nodes, $($this.Connections.Count) connections!" -ForegroundColor Green
    }

    [void] OnUpdate() { }  # FIXED: Empty - use internal timer

    [void] OnStop() {
        Write-Host "🛑 [Show9] Neural cleanup..." -ForegroundColor Yellow
        
        if ($this.AnimationTimer) {
            $this.AnimationTimer.Stop()
            $this.AnimationTimer.Dispose()
            $this.AnimationTimer = $null
            Write-Host "⏹️ [Show9] Animation timer stopped" -ForegroundColor Yellow
        }
        
        $this.Particles.Clear()
        $this.PredictionOrbs.Clear()
        
        Write-Host "✔️ [Show9] Cleanup complete!" -ForegroundColor Green
    }

    hidden [void] StartAnimationTimer() {
        if ($this.AnimationTimer) {
            $this.AnimationTimer.Stop()
            $this.AnimationTimer.Dispose()
        }
        
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = 50
        
        $self = $this
        $this.AnimationTimer.Add_Tick({
            $self.UpdateAnimation()
        }.GetNewClosure())
        
        $this.AnimationTimer.Start()
        Write-Host "🎬 [Show9] Animation timer STARTED!" -ForegroundColor Green
    }

    hidden [void] UpdateAnimation() {
        $this.TickCount++
        $tick = $this.TickCount
        
        if ($tick % 20 -eq 0) {
            Write-Host "🔄 Tick: $tick | Particles: $($this.Particles.Count) | Orbs: $($this.PredictionOrbs.Count)" -ForegroundColor DarkGray
        }
        
        # Processing wave
        $this.ProcessingWave = ($this.ProcessingWave + 0.1) % 360
        $wave = [Math]::Sin([Math]::PI * $this.ProcessingWave / 180)
        
        # Activate nodes in waves
        $activeLayer = [Math]::Floor(($tick / 10) % 4)
        
        foreach ($node in $this.Nodes) {
            if ($node.Layer -eq $activeLayer) {
                $node.TargetActivation = 0.5 + (Get-Random -Minimum 0 -Maximum 50) / 100.0
            } else {
                $node.TargetActivation = 0.1
            }
            
            $node.Activation += ($node.TargetActivation - $node.Activation) * 0.15
            $node.Pulse = [Math]::Abs([Math]::Sin($tick * 0.1 + $node.Id * 0.3)) * 2
        }
        
        # Activate connections
        foreach ($conn in $this.Connections) {
            $fromNode = $this.Nodes[$conn.From]
            $toNode = $this.Nodes[$conn.To]
            
            if ($fromNode.Activation -gt 0.3 -and $toNode.Activation -gt 0.2) {
                $conn.Active = $true
                $conn.Brightness = [Math]::Min(255, $conn.Brightness + 30)
            } else {
                $conn.Brightness = [Math]::Max(0, $conn.Brightness - 20)
                if ($conn.Brightness -eq 0) { $conn.Active = $false }
            }
        }
        
        # Spawn particles
        if ($tick - $this.LastSpawn -gt 5) {
            $this.LastSpawn = $tick
            $inputNodes = $this.Nodes | Where-Object { $_.Layer -eq 0 }
            if ($inputNodes.Count -gt 0) {
                $randomNode = $inputNodes | Get-Random
                [void]$this.Particles.Add(@{
                    X = $randomNode.X; Y = $randomNode.Y
                    VX = (Get-Random -Minimum 2 -Maximum 5)
                    VY = (Get-Random -Minimum -2 -Maximum 2)
                    Size = Get-Random -Minimum 3 -Maximum 6
                    Life = 100; MaxLife = 100
                })
            }
        }
        
        $this.UpdateParticles()
        $this.UpdatePredictionOrbs($tick)
        
        # FIXED: CRITICAL - Invalidate CANVAS not parent
        if ($this.Canvas) {
            $this.Canvas.Invalidate()
            $this.Canvas.Update()
        }
    }

    hidden [void] InitializeNeuralNetwork() {
        $layers = @(5, 8, 6, 3)
        $nodeId = 0
        for ($layerIdx = 0; $layerIdx -lt $layers.Count; $layerIdx++) {
            $nodeCount = $layers[$layerIdx]
            $x = $this.layerX[$layerIdx]
            $spacing = 300 / ($nodeCount + 1)
            
            for ($i = 0; $i -lt $nodeCount; $i++) {
                $y = 50 + $spacing * ($i + 1)
                [void]$this.Nodes.Add(@{
                    Id = $nodeId++; X = $x; Y = $y; Layer = $layerIdx
                    Activation = 0.0; TargetActivation = 0.0; Radius = 8; Pulse = 0
                })
            }
        }
        
        for ($layerIdx = 0; $layerIdx -lt ($layers.Count - 1); $layerIdx++) {
            $currentNodes = $this.Nodes | Where-Object { $_.Layer -eq $layerIdx }
            $nextNodes = $this.Nodes | Where-Object { $_.Layer -eq ($layerIdx + 1) }
            
            foreach ($node1 in $currentNodes) {
                foreach ($node2 in $nextNodes) {
                    [void]$this.Connections.Add(@{
                        From = $node1.Id; To = $node2.Id
                        Weight = (Get-Random -Minimum 3 -Maximum 10) / 10.0
                        Active = $false; Brightness = 0
                    })
                }
            }
        }
    }

    hidden [void] UpdateParticles() {
        $toRemove = [System.Collections.ArrayList]::new()
        
        for ($i = 0; $i -lt $this.Particles.Count; $i++) {
            $p = $this.Particles[$i]
            $p.X += $p.VX; $p.Y += $p.VY; $p.Life -= 1
            
            $nearest = $null; $minDist = 999999
            foreach ($node in $this.Nodes) {
                $dx = $node.X - $p.X; $dy = $node.Y - $p.Y
                $dist = [Math]::Sqrt($dx*$dx + $dy*$dy)
                if ($dist -lt $minDist -and $dist -lt 100) {
                    $minDist = $dist; $nearest = $node
                }
            }
            
            if ($nearest) {
                $dx = $nearest.X - $p.X; $dy = $nearest.Y - $p.Y
                $p.VX += $dx * 0.01; $p.VY += $dy * 0.01
            }
            
            if ($p.Life -le 0 -or $p.X -gt 600) {
                [void]$toRemove.Add($i)
            }
        }
        
        for ($i = $toRemove.Count - 1; $i -ge 0; $i--) {
            $this.Particles.RemoveAt($toRemove[$i])
        }
        
        while ($this.Particles.Count -gt 80) { $this.Particles.RemoveAt(0) }
    }

    hidden [void] UpdatePredictionOrbs($tick) {
        if ($this.PredictionOrbs.Count -eq 0) {
            $outputNodes = $this.Nodes | Where-Object { $_.Layer -eq 3 }
            foreach ($node in $outputNodes) {
                [void]$this.PredictionOrbs.Add(@{
                    X = $node.X + 80; Y = $node.Y
                    Value = Get-Random -Minimum 30 -Maximum 95
                    Confidence = 0.5; Pulse = 0
                })
            }
        }
        
        foreach ($orb in $this.PredictionOrbs) {
            $orb.Pulse = [Math]::Abs([Math]::Sin($tick * 0.08)) * 0.5
            
            if ($tick % 30 -eq 0) {
                $orb.Value += (Get-Random -Minimum -5 -Maximum 5)
                $orb.Value = [Math]::Max(0, [Math]::Min(100, $orb.Value))
            }
            
            $avgActivation = ($this.Nodes | ForEach-Object { $_.Activation } | Measure-Object -Average).Average
            $orb.Confidence = [Math]::Max(0.3, $avgActivation)
        }
    }

hidden [void] RenderNeuralNetwork($g, $width, $height) {
    # Background circuit pattern
    $circuitPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(20, 0, 100, 150), 1)
    for ($i = 0; $i -lt 10; $i++) {
        $y = $i * 40
        $g.DrawLine($circuitPen, 0, $y, $width, $y)
    }
    $circuitPen.Dispose()
    
    # Draw connections
    foreach ($conn in $this.Connections) {
        if ($conn.Active -and $conn.Brightness -gt 0) {
            $fromNode = $this.Nodes[$conn.From]
            $toNode = $this.Nodes[$conn.To]
            
            $alpha = [Math]::Min(255, [Math]::Max(0, [int]$conn.Brightness))
            $thickness = 1 + ($conn.Weight * 2)
            
            $color = [System.Drawing.Color]::FromArgb($alpha, 0, 200, 255)
            $pen = New-Object System.Drawing.Pen($color, $thickness)
            
            try {
                $g.DrawLine($pen, $fromNode.X, $fromNode.Y, $toNode.X, $toNode.Y)
            }
            finally {
                $pen.Dispose()
            }
        }
    }
    
    # Draw particles - FIXED
    foreach ($p in $this.Particles) {
        $alpha = [Math]::Min(255, [int](($p.Life / $p.MaxLife) * 255))
        $color = [System.Drawing.Color]::FromArgb($alpha, 0, 255, 150)
        $brush = New-Object System.Drawing.SolidBrush($color)
        
        try {
            $g.FillEllipse($brush, $p.X - $p.Size/2, $p.Y - $p.Size/2, $p.Size, $p.Size)
        }
        finally {
            $brush.Dispose()
        }
    }
    
    # Draw nodes - FIXED COLOR CALCULATIONS
    foreach ($node in $this.Nodes) {
        $activation = $node.Activation
        $radius = $node.Radius + $node.Pulse
        
        # Node glow - FIXED
        if ($activation -gt 0.2) {
            $glowRadius = $radius + 8
            $glowAlpha = [Math]::Min(255, [int]($activation * 100))
            $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, 0, 150, 255)
            $glowBrush = New-Object System.Drawing.SolidBrush($glowColor)
            
            try {
                $g.FillEllipse($glowBrush, $node.X - $glowRadius, $node.Y - $glowRadius, $glowRadius * 2, $glowRadius * 2)
            }
            finally {
                $glowBrush.Dispose()
            }
        }
        
        # Node core - FIXED
        $intensity = [Math]::Min(255, [int]($activation * 255))
        $green = [Math]::Min(255, 150 + $intensity)
        $nodeColor = [System.Drawing.Color]::FromArgb(255, 0, $green, 255)
        $nodeBrush = New-Object System.Drawing.SolidBrush($nodeColor)
        
        try {
            $g.FillEllipse($nodeBrush, $node.X - $radius, $node.Y - $radius, $radius * 2, $radius * 2)
        }
        finally {
            $nodeBrush.Dispose()
        }
        
        # Node outline
        $outlinePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 0, 200, 255), 2)
        try {
            $g.DrawEllipse($outlinePen, $node.X - $radius, $node.Y - $radius, $radius * 2, $radius * 2)
        }
        finally {
            $outlinePen.Dispose()
        }
    }
    
    # Draw prediction orbs - FIXED
    foreach ($orb in $this.PredictionOrbs) {
        $orbRadius = 12 + ($orb.Pulse * 8)
        
        # Orb glow - FIXED
        $glowAlpha = [Math]::Min(80, [int]($orb.Confidence * 80))
        $glowColor = [System.Drawing.Color]::FromArgb($glowAlpha, 255, 150, 0)
        $glowBrush = New-Object System.Drawing.SolidBrush($glowColor)
        try {
            $g.FillEllipse($glowBrush, $orb.X - $orbRadius - 5, $orb.Y - $orbRadius - 5, ($orbRadius + 5) * 2, ($orbRadius + 5) * 2)
        }
        finally {
            $glowBrush.Dispose()
        }
        
        # Orb body - FIXED
        $orbAlpha = [Math]::Min(255, [int]($orb.Confidence * 200))
        $orbColor = [System.Drawing.Color]::FromArgb($orbAlpha, 255, 200, 0)
        $orbBrush = New-Object System.Drawing.SolidBrush($orbColor)
        try {
            $g.FillEllipse($orbBrush, $orb.X - $orbRadius, $orb.Y - $orbRadius, $orbRadius * 2, $orbRadius * 2)
        }
        finally {
            $orbBrush.Dispose()
        }
        
        # Value text
        $valueText = "$([Math]::Round($orb.Value))%"
        $font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        try {
            $textSize = $g.MeasureString($valueText, $font)
            $g.DrawString($valueText, $font, $textBrush, $orb.X - $textSize.Width/2, $orb.Y - $textSize.Height/2)
        }
        finally {
            $font.Dispose()
            $textBrush.Dispose()
        }
    }
    
    # Layer labels
    $layerNames = @("INPUT", "HIDDEN 1", "HIDDEN 2", "OUTPUT")
    $labelFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $labelBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 0, 200, 255))
    
    try {
        for ($i = 0; $i -lt $this.layerX.Count; $i++) {
            $g.DrawString($layerNames[$i], $labelFont, $labelBrush, $this.layerX[$i] - 25, 10)
        }
    }
    finally {
        $labelFont.Dispose()
        $labelBrush.Dispose()
    }
}

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Canvas.Add_Paint({
            param($sender, $e)
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            
            $self.RenderNeuralNetwork($g, $sender.Width, $sender.Height)
        }.GetNewClosure())
    }

    hidden [void] SetupVisibleChanged() {
        $self = $this
        $this.Panel.Add_VisibleChanged({
            param($s, $e)
            if ($self.Panel.Visible) {
                $Show9Messages = @(
                    "🧠 AI NEURAL PREDICTION ENGINE - Visualizing Intelligence",
                    "⚡ Neural networks processing real-time predictions",
                    "🔮 Watch the digital brain think and learn",
                    "💡 Synaptic connections firing across the network"
                )
                $global:messages = $Show9Messages
                if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
            }
        }.GetNewClosure())
    }
}

# Legacy compatibility
function Stop-Show9 {
    Write-Host "🛑 [Show9] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show9")) {
        $Global:ShowManager.Shows["show9"].Stop()
    }
}

Write-Host "✅ COMPLETE Show9 FIXED - LIVE ANIMATIONS!" -ForegroundColor Green
Write-Host "🧠 TreeView → Show9 → Particles flowing + synapses firing!" -ForegroundColor Cyan
