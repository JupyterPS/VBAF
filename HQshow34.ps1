# ==============================================
# Show34 - Forest of Impact (BaseShow)
# ==============================================

class Tree {
    [float]$X; [float]$Y; [float]$Height
    [System.Drawing.Color]$Color; [bool]$Growing; [int]$Layer
    [System.Collections.ArrayList]$Leaves

    Tree([float]$x,[float]$y,[float]$height,[System.Drawing.Color]$color,[int]$layer) {
        $this.X = $x; $this.Y = $y; $this.Height = $height
        $this.Color = $color; $this.Growing = $true; $this.Layer = $layer
        $this.Leaves = [System.Collections.ArrayList]::new()
        
        $leafCount = Get-Random -Minimum 2 -Maximum 4
        for ($i = 0; $i -lt $leafCount; $i++) {
            [void]$this.Leaves.Add(@{
                OffsetX = Get-Random -Minimum -10 -Maximum 10
                OffsetY = Get-Random -Minimum -10 -Maximum 10
                Size = 10 + (Get-Random -Minimum 0 -Maximum 10)
            })
        }
    }
    
    [void] Grow() {
        if ($this.Growing) {
            $this.Height += 0.5
            if ($this.Height -ge 120) { $this.Growing = $false }
        }
    }
}

class Spark {
    [float]$X; [float]$Y; [float]$DX; [float]$DY
    [int]$Life; [System.Drawing.Color]$Color

    Spark([float]$x,[float]$y,[float]$dx,[float]$dy,[System.Drawing.Color]$color) {
        $this.X = $x; $this.Y = $y; $this.DX = $dx; $this.DY = $dy
        $this.Color = $color; $this.Life = Get-Random -Minimum 30 -Maximum 80
    }
    
    [void] Move() { $this.X += $this.DX; $this.Y += $this.DY; $this.Life-- }
    [bool] IsAlive() { return ($this.Life -gt 0) }
}

class Show34 : BaseShow {
    hidden [System.Collections.ArrayList] $Trees = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $Sparks = [System.Collections.ArrayList]::new()
    hidden [System.Collections.ArrayList] $Stars = [System.Collections.ArrayList]::new()
    hidden [System.Windows.Forms.Label] $TickerLabel
    hidden [int] $TickerIndex = 0
    hidden [int] $TickerTickCount = 0      # <<< NEW: controls ticker speed
    hidden [hashtable[]] $LayerSettings = @(
        @{ Scale=1.0; Opacity=255; VerticalOffset=0 },
        @{ Scale=0.75; Opacity=180; VerticalOffset=20 },
        @{ Scale=0.5; Opacity=120; VerticalOffset=40 }
    )
    
    hidden [string[]] $Messages = @(
        "✨ Every tree represents a life touched by care",
        "✨ Growth is resilience, diversity, and purpose",
        "✨ Innovation takes root when science meets compassion",
        "✨ Novo Nordisk: Cultivating health, one life at a time",
        "✨ A forest of progress, rooted in global impact"
    )

    Show34([System.Windows.Forms.Panel]$panel) : base("show34", $panel) {
        $this.InitializeForest()
        $this.InitializeStars()
    }

    [void] OnStart() {
        Write-Host "🌲 [Show34] Forest of Impact initializing..." -ForegroundColor Magenta
        
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::Black
        
        # Enable double buffering
        $prop = $this.Panel.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }
        
        # Ticker label
        $this.TickerLabel = New-Object System.Windows.Forms.Label
        $this.TickerLabel.AutoSize = $false
        $this.TickerLabel.Width = 800
        $this.TickerLabel.Height = 28
        $this.TickerLabel.ForeColor = [System.Drawing.Color]::White
        $this.TickerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $this.TickerLabel.BackColor = [System.Drawing.Color]::Transparent
        $this.TickerLabel.Location = New-Object System.Drawing.Point(16,16)
        $this.TickerLabel.Text = $this.Messages[0]
        $this.Panel.Controls.Add($this.TickerLabel)
        
        # Ticker messages
        $global:messages = $this.Messages
        if (Get-Command Update-Ticker -ErrorAction SilentlyContinue) { Update-Ticker }
        
        $this.SetupPaintEvent()
        $this.SetupVisibleChanged()
        
        Write-Host "✅ [Show34] Forest ready with $($this.Trees.Count) trees!" -ForegroundColor Green
    }

    [void] OnUpdate() {
        $width = $this.Panel.Width
        $height = $this.Panel.Height
        if ($width -le 0 -or $height -le 0) { return }
        
        # Grow trees and emit sparks
        foreach ($tree in $this.Trees) {
            $tree.Grow()
            if ($tree.Growing -and $this.Sparks.Count -lt 50 -and (Get-Random -Minimum 0 -Maximum 100) -lt 5) {
                $layerSetting = $this.LayerSettings[$tree.Layer]
                $scale = $layerSetting.Scale
                $vOffset = $layerSetting.VerticalOffset
                $trunkHeight = [Math]::Max(10, $tree.Height * $scale)
                $trunkTopY = ($tree.Y + $vOffset) - $trunkHeight
                
                $dx = ((Get-Random -Minimum -5 -Maximum 5) / 20.0)
                $dy = ((Get-Random -Minimum -5 -Maximum 5) / 20.0)
                $sparkColor = [System.Drawing.Color]::FromArgb(200, 255, 255, 180)
                [void]$this.Sparks.Add([Spark]::new($tree.X, $trunkTopY, $dx, $dy, $sparkColor))
            }
        }
        
        # Update sparks
        $aliveSparks = [System.Collections.ArrayList]::new()
        foreach ($spark in $this.Sparks) {
            $spark.Move()
            if ($spark.IsAlive()) { [void]$aliveSparks.Add($spark) }
        }
        $this.Sparks.Clear()
        foreach ($spark in $aliveSparks) { [void]$this.Sparks.Add($spark) }
        
        # Limit sparks
        while ($this.Sparks.Count -gt 50) { $this.Sparks.RemoveAt(0) }
        
        
# Update ticker (slower)
$this.TickerTickCount++

# Change message every 60 updates (adjust 60 as needed)
if ($this.TickerTickCount -ge 60) {
    $this.TickerTickCount = 0
    $this.TickerIndex = ($this.TickerIndex + 1) % $this.Messages.Count
    $this.TickerLabel.Text = $this.Messages[$this.TickerIndex]
}

        
        # GC every 100 ticks
        if ($this.TickCount % 100 -eq 0) {
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
        }
        
        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "🛑 [Show34] Forest cleanup..." -ForegroundColor Yellow
        
        $this.Sparks.Clear()
        $this.Trees.Clear()
        $this.Stars.Clear()
        if ($this.TickerLabel) {
            $this.Panel.Controls.Remove($this.TickerLabel)
            $this.TickerLabel.Dispose()
        }
        
        Write-Host "✔️ [Show34] Cleanup complete!" -ForegroundColor Green
    }

    hidden [void] InitializeStars() {
        for ($i = 0; $i -lt 20; $i++) {
            [void]$this.Stars.Add(@{
                X = Get-Random -Minimum 10 -Maximum 640
                Y = Get-Random -Minimum 10 -Maximum 100
            })
        }
    }

    hidden [void] InitializeForest() {
        $w = 650; $h = 410
        $rows = 10; $cols = 20
        
        $forestWidth = $w * 0.8
        $forestHeight = $h * 0.6
        $marginX = ($w - $forestWidth) / 2
        $marginY = ($h - $forestHeight) / 2 + 40
        
        for ($r = 0; $r -lt $rows; $r++) {
            for ($c = 0; $c -lt $cols; $c++) {
                $x = $marginX + ($forestWidth/($cols+1))*($c+1) + (Get-Random -Minimum -15 -Maximum 15)
                $y = ($marginY+$forestHeight) - ($r*($forestHeight/$rows)) + (Get-Random -Minimum -10 -Maximum 10)
                $height = Get-Random -Minimum 40 -Maximum 90
                $layer = $r % 3
                $baseGreen = 80 + (Get-Random -Minimum 0 -Maximum 120)
                $color = [System.Drawing.Color]::FromArgb(255, 60+(Get-Random -Minimum 0 -Maximum 100), $baseGreen, 100+(Get-Random -Minimum 0 -Maximum 100))
                [void]$this.Trees.Add([Tree]::new($x, $y, $height, $color, $layer))
            }
        }
    }

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            
            $width = $s.Width
            $height = $s.Height
            if ($width -le 0 -or $height -le 0) { return }
            
            # Background gradient
            $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                (New-Object System.Drawing.Point(0,0)),
                (New-Object System.Drawing.Point(0,$height)),
                [System.Drawing.Color]::FromArgb(15,25,35),
                [System.Drawing.Color]::FromArgb(35,55,75)
            )
            $g.FillRectangle($bgBrush, 0, 0, $width, $height)
            $bgBrush.Dispose()
            
            # Stars
            foreach ($star in $self.Stars) {
                $g.FillEllipse([System.Drawing.Brushes]::White, $star.X, $star.Y, 2, 2)
            }
            
            # Moon
            $moonBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,230,230,200))
            $g.FillEllipse($moonBrush, $width-140, 60, 80, 80)
            $moonBrush.Dispose()
            
            # Trees
            foreach ($tree in $self.Trees) {
                $layerSetting = $self.LayerSettings[$tree.Layer]
                $scale = $layerSetting.Scale
                $opacity = $layerSetting.Opacity
                $vOffset = $layerSetting.VerticalOffset
                
                $xScaled = $tree.X
                $yBase = $tree.Y + $vOffset
                $trunkHeight = [Math]::Max(10, $tree.Height * $scale)
                $trunkWidth = [Math]::Max(2, 3 * $scale)
                $trunkTopY = $yBase - $trunkHeight
                
                # Trunk
                $trunkColor = [System.Drawing.Color]::FromArgb($opacity, 85, 53, 30)
                $trunkBrush = New-Object System.Drawing.SolidBrush($trunkColor)
                $g.FillRectangle($trunkBrush, [int]$xScaled, [int]$trunkTopY, [int]$trunkWidth, [int]$trunkHeight)
                $trunkBrush.Dispose()
                
                # Leaves
                $leafColor = [System.Drawing.Color]::FromArgb($opacity, 20, 120, 40)
                $leafBrush = New-Object System.Drawing.SolidBrush($leafColor)
                foreach ($leaf in $tree.Leaves) {
                    $offsetX = $leaf.OffsetX * $scale
                    $offsetY = $leaf.OffsetY * $scale
                    $leafSize = $leaf.Size * $scale
                    $g.FillEllipse($leafBrush,
                        [int]($xScaled - $leafSize/2 + $offsetX),
                        [int]($trunkTopY - $leafSize/2 + $offsetY),
                        [int]$leafSize, [int]$leafSize)
                }
                $leafBrush.Dispose()
            }
            
            # Sparks
            foreach ($spark in $self.Sparks) {
                if ($spark.IsAlive()) {
                    $alpha = [int](255 * ($spark.Life / 80.0))
                    $sparkBrush = New-Object System.Drawing.SolidBrush(
                        [System.Drawing.Color]::FromArgb($alpha, $spark.Color.R, $spark.Color.G, $spark.Color.B))
                    $g.FillEllipse($sparkBrush, [int]$spark.X, [int]$spark.Y, 4, 4)
                    $sparkBrush.Dispose()
                }
            }
            
            # Title
            $title = "Novo Nordisk: The Forest of Impact"
            $font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,230,240,255))
            $tw = $g.MeasureString($title, $font).Width
            $g.DrawString($title, $font, $brush, ($width/2 - $tw/2), $height - 50)
            $font.Dispose()
            $brush.Dispose()
        }.GetNewClosure())
    }

    hidden [void] SetupVisibleChanged() {
        $self = $this
        $this.Panel.Add_VisibleChanged({
            param($s, $e)
            if (-not $self.Panel.Visible) {
                $self.Sparks.Clear()
                [GC]::Collect()
            }
        }.GetNewClosure())
    }
}

# Legacy compatibility
function Stop-Show34 {
    Write-Host "🛑 [Show34] Stop called" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show34")) {
        $Global:ShowManager.Shows["show34"].Stop()
    }
}

Write-Host "✅ COMPLETE Show34 - Forest of Impact (BaseShow)" -ForegroundColor Green
Write-Host "🌲 TreeView → Show34 → Watch trees grow + sparks fly! ✨" -ForegroundColor Cyan

