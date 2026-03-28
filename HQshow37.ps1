# ===============================
# HQshow37.ps1 — Molecule Interactions v3 (GM v3)
# Novo Nordisk: Pharmaceutical Chemistry Visualization
# ===============================
Write-Host "`n=> _____ HQshow37 (Molecule Interactions v3 - GM3) ___________ <=`n" -ForegroundColor Cyan

class Show37 : BaseShow {
    # ========================================
    # Private Properties (GM3-style)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $Molecules
    hidden [System.Collections.ArrayList] $Reactions

    # ========================================
    # Constructor
    # ========================================
    Show37([System.Windows.Forms.Panel]$panel) : base("show37", $panel) {
        $this.State = @{
            TickCount        = 0
            SelectedMolecule = $null
            ReactionMode     = "Bonding"
            TickerOffset     = 0
        }
        $this.Molecules = [System.Collections.ArrayList]::new()
        $this.Reactions = [System.Collections.ArrayList]::new()
    }

    # ========================================
    # Lifecycle Methods
    # ========================================
    [void] OnStart() {
        Write-Host "  ⚛️ [Show37] Initializing Molecule Interactions (GM3)..." -ForegroundColor Cyan

        # Panel setup
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(10, 15, 25)

        # Double-buffering
        $prop = $this.Panel.GetType().GetProperty(
            "DoubleBuffered",
            [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
        )
        if ($prop) { $prop.SetValue($this.Panel, $true, $null) }

        # Ticker messages for GM
        $Show37Messages = @(
            "⚛️ MOLECULE INTERACTIONS - Pharmaceutical Chemistry in Motion",
            "💊 Watch drug compounds form and interact at molecular level",
            "🔬 Real-time simulation of chemical bonding",
            "🧬 Novo Nordisk - Pioneering Life-Changing Medicines",
            "⚡ From atoms to treatments - chemistry comes alive"
        )
        $Global:messages = $Show37Messages

        # Initialize data
        $this.Molecules.Clear()
        $this.Reactions.Clear()
        $this.InitializeMolecules()

        # Paint hook
        $this.SetupPaintEvent()

        Write-Host "  ✅ [Show37] Ready with $($this.Molecules.Count) molecular structures (GM3)" -ForegroundColor Green
    }

    [void] OnUpdate() {
        # Called every 50 ms by GM
        $this.State.TickCount++

        # Ticker scroll
        $this.State.TickerOffset += 2
        if ($this.State.TickerOffset -gt 800) {
            $this.State.TickerOffset = 0
        }

        # Simulation
        $this.UpdateMolecules()
        $this.UpdateReactions()

        # Request repaint
        $this.Panel.Invalidate()
    }

    [void] OnStop() {
        Write-Host "  🛑 [Show37] Cleaning up (GM3)..." -ForegroundColor Yellow

        # Clear collections
        if ($this.Molecules) { $this.Molecules.Clear() }
        if ($this.Reactions) { $this.Reactions.Clear() }

        # Reset state
        $this.State.TickCount        = 0
        $this.State.SelectedMolecule = $null
        $this.State.TickerOffset     = 0

        # Remove paint event & clear UI
        $this.Panel.Remove_Paint($null)
        $this.Panel.Controls.Clear()

        Write-Host "  ✅ [Show37] Cleanup complete (GM3)" -ForegroundColor Green
    }

    # ========================================
    # Helper Methods (GM3 style)
    # ========================================

    hidden [void] SetupPaintEvent() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderScene($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }

    hidden [void] InitializeMolecules() {
        $compounds = @(
            @{Name="Insulin";        Atoms=@("C","H","O","N","S"); Color=[System.Drawing.Color]::FromArgb(100, 150, 255); Count=12},
            @{Name="GLP-1";         Atoms=@("C","H","O","N");     Color=[System.Drawing.Color]::FromArgb(255, 100, 150); Count=10},
            @{Name="Semaglutide";   Atoms=@("C","H","O","N");     Color=[System.Drawing.Color]::FromArgb(150, 255, 100); Count=14},
            @{Name="Enzyme";        Atoms=@("C","H","O","N","P"); Color=[System.Drawing.Color]::FromArgb(255, 200, 100); Count=8}
        )

        foreach ($compound in $compounds) {
            $centerX = 150 + (Get-Random -Minimum 0 -Maximum 400)
            $centerY = 150 + (Get-Random -Minimum 0 -Maximum 200)

            $molecule = @{
                Name          = $compound.Name
                CenterX       = $centerX
                CenterY       = $centerY
                Color         = $compound.Color
                Atoms         = [System.Collections.ArrayList]::new()
                Bonds         = [System.Collections.ArrayList]::new()
                Rotation      = 0.0
                RotationSpeed = (Get-Random -Minimum 5 -Maximum 15) / 100.0
                Energy        = 100
                Stability     = 80 + (Get-Random -Minimum 0 -Maximum 20)
                Active        = $false
            }

            $atomTypes = $compound.Atoms
            $radius    = 40 + (Get-Random -Minimum 0 -Maximum 20)

            for ($i = 0; $i -lt $compound.Count; $i++) {
                $angle = ($i * 360 / $compound.Count) * [Math]::PI / 180
                $atomType = $atomTypes[$i % $atomTypes.Count]

                $atomColor = switch ($atomType) {
                    "C" { [System.Drawing.Color]::FromArgb(80, 80, 80) }
                    "H" { [System.Drawing.Color]::FromArgb(255, 255, 255) }
                    "O" { [System.Drawing.Color]::FromArgb(255, 50, 50) }
                    "N" { [System.Drawing.Color]::FromArgb(50, 100, 255) }
                    "S" { [System.Drawing.Color]::FromArgb(255, 200, 50) }
                    "P" { [System.Drawing.Color]::FromArgb(255, 128, 0) }
                    default { [System.Drawing.Color]::Gray }
                }

                $size = switch ($atomType) {
                    "H" { 8 }
                    "C" { 12 }
                    "O" { 11 }
                    "N" { 11 }
                    "S" { 14 }
                    "P" { 13 }
                    default { 10 }
                }

                $atom = @{
                    Element   = $atomType
                    Color     = $atomColor
                    LocalX    = $radius * [Math]::Cos($angle)
                    LocalY    = $radius * [Math]::Sin($angle)
                    Size      = $size
                    Electrons = [System.Collections.ArrayList]::new()
                    Charge    = 0
                }

                for ($e = 0; $e -lt 3; $e++) {
                    [void]$atom.Electrons.Add(@{
                        Angle    = Get-Random -Minimum 0 -Maximum 360
                        Distance = 15 + (Get-Random -Minimum 0 -Maximum 5)
                        Speed    = 0.1 + (Get-Random -Minimum 0 -Maximum 5) / 100.0
                    })
                }

                [void]$molecule.Atoms.Add($atom)
            }

            # Bonds
            for ($i = 0; $i -lt $molecule.Atoms.Count; $i++) {
                $nextIndex = ($i + 1) % $molecule.Atoms.Count
                [void]$molecule.Bonds.Add(@{
                    Atom1    = $i
                    Atom2    = $nextIndex
                    Type     = if ((Get-Random -Minimum 0 -Maximum 10) -gt 7) { "Double" } else { "Single" }
                    Strength = 0.8 + (Get-Random -Minimum 0 -Maximum 20) / 100.0
                    Pulse    = 0.0
                })
            }

            [void]$this.Molecules.Add($molecule)
        }
    }

    hidden [void] UpdateMolecules() {
        $tick = $this.State.TickCount

        foreach ($molecule in $this.Molecules) {
            # Rotation
            $molecule.Rotation += $molecule.RotationSpeed
            if ($molecule.Rotation -gt 6.28) { $molecule.Rotation -= 6.28 }

            # Electrons
            foreach ($atom in $molecule.Atoms) {
                foreach ($electron in $atom.Electrons) {
                    $electron.Angle += $electron.Speed * 50
                    if ($electron.Angle -gt 360) { $electron.Angle -= 360 }
                }
            }

            # Bonds pulse
            foreach ($bond in $molecule.Bonds) {
                $bond.Pulse += 0.1
                if ($bond.Pulse -gt 6.28) { $bond.Pulse -= 6.28 }
            }

            # Random activity
            if ((Get-Random -Minimum 0 -Maximum 200) -lt 2) {
                $molecule.Active = $true
                [void]$this.Reactions.Add(@{
                    X    = $molecule.CenterX
                    Y    = $molecule.CenterY
                    Size = 30
                    Life = 80
                })
            }

            if ($molecule.Active -and $tick % 100 -eq 0) {
                $molecule.Active = $false
            }

            # Stability fluctuation
            if ($tick % 100 -eq 0) {
                $molecule.Stability += (Get-Random -Minimum -5 -Maximum 5)
                $molecule.Stability = [Math]::Max(50, [Math]::Min(100, $molecule.Stability))
            }

            # Slow drift
            $molecule.CenterX += ([Math]::Sin($tick * 0.01 + $molecule.CenterY * 0.01)) * 0.3
            $molecule.CenterY += ([Math]::Cos($tick * 0.01 + $molecule.CenterX * 0.01)) * 0.3

            # Bounds
            $molecule.CenterX = [Math]::Max(100, [Math]::Min(550, $molecule.CenterX))
            $molecule.CenterY = [Math]::Max(100, [Math]::Min(350, $molecule.CenterY))
        }
    }

    hidden [void] UpdateReactions() {
        $active = [System.Collections.ArrayList]::new()
        foreach ($reaction in $this.Reactions) {
            $reaction.Life -= 1
            $reaction.Size += 2
            if ($reaction.Life -gt 0) { [void]$active.Add($reaction) }
        }
        $this.Reactions = $active
    }

    # ========================================
    # Rendering
    # ========================================
    hidden [void] RenderScene([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        if ($width -le 0 -or $height -le 0) { return }

        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        # Background
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            [System.Drawing.Point]::new(0, 0),
            [System.Drawing.Point]::new(0, $height),
            [System.Drawing.Color]::FromArgb(10, 15, 25),
            [System.Drawing.Color]::FromArgb(15, 20, 35)
        )
        $g.FillRectangle($bgBrush, 0, 0, $width, $height)
        $bgBrush.Dispose()

        # Grid
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(20, 100, 150, 200), 1)
        for ($i = 0; $i -lt 30; $i++) {
            $x = $i * 30
            $g.DrawLine($gridPen, $x, 0, $x, $height)
            $y = $i * 20
            $g.DrawLine($gridPen, 0, $y, $width, $y)
        }
        $gridPen.Dispose()

        # Effects & molecules
        $this.DrawReactions($g)
        $this.DrawMolecules($g)

        # Ticker + title
        $this.DrawTicker($g, $width, $height)
        $this.DrawTitle($g, $width)
    }

    hidden [void] DrawReactions([System.Drawing.Graphics]$g) {
        foreach ($reaction in $this.Reactions) {
            $alpha = [math]::Min(255, $reaction.Life * 3)

            for ($r = 0; $r -lt 5; $r++) {
                $ringSize  = $reaction.Size + ($r * 15)
                $ringAlpha = [int]($alpha / (1 + $r * 0.5))
                $ringColor = [System.Drawing.Color]::FromArgb($ringAlpha, 100, 200, 255)
                $ringPen   = New-Object System.Drawing.Pen($ringColor, 2)
                $g.DrawEllipse($ringPen, $reaction.X - $ringSize/2, $reaction.Y - $ringSize/2, $ringSize, $ringSize)
                $ringPen.Dispose()
            }

            for ($p = 0; $p -lt 8; $p++) {
                $angle = ($p * 45) * [Math]::PI / 180
                $dist  = $reaction.Size * 0.8
                $px    = $reaction.X + ($dist * [Math]::Cos($angle))
                $py    = $reaction.Y + ($dist * [Math]::Sin($angle))
                $pBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, 255, 255, 100))
                $g.FillEllipse($pBrush, $px - 4, $py - 4, 8, 8)
                $pBrush.Dispose()
            }
        }
    }

    hidden [void] DrawMolecules([System.Drawing.Graphics]$g) {
        foreach ($molecule in $this.Molecules) {
            $cx  = $molecule.CenterX
            $cy  = $molecule.CenterY
            $rot = $molecule.Rotation

            if ($molecule.Active) {
                $glowSize = 100
                $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 100, 200, 255))
                $g.FillEllipse($glowBrush, $cx - $glowSize/2, $cy - $glowSize/2, $glowSize, $glowSize)
                $glowBrush.Dispose()
            }

            # Bonds
            foreach ($bond in $molecule.Bonds) {
                $atom1 = $molecule.Atoms[$bond.Atom1]
                $atom2 = $molecule.Atoms[$bond.Atom2]

                $x1 = $cx + ($atom1.LocalX * [Math]::Cos($rot) - $atom1.LocalY * [Math]::Sin($rot))
                $y1 = $cy + ($atom1.LocalX * [Math]::Sin($rot) + $atom1.LocalY * [Math]::Cos($rot))
                $x2 = $cx + ($atom2.LocalX * [Math]::Cos($rot) - $atom2.LocalY * [Math]::Sin($rot))
                $y2 = $cy + ($atom2.LocalX * [Math]::Sin($rot) + $atom2.LocalY * [Math]::Cos($rot))

                $bondAlpha = [int]($bond.Strength * 200)
                $bondColor = [System.Drawing.Color]::FromArgb($bondAlpha, 150, 150, 150)
                $bondWidth = if ($bond.Type -eq "Double") { 3 } else { 2 }
                $bondPen   = New-Object System.Drawing.Pen($bondColor, $bondWidth)

                $g.DrawLine($bondPen, $x1, $y1, $x2, $y2)

                if ($bond.Type -eq "Double") {
                    $offset = 4
                    $dx = $y2 - $y1
                    $dy = $x1 - $x2
                    $len = [Math]::Sqrt($dx * $dx + $dy * $dy)
                    if ($len -gt 0) {
                        $dx = ($dx / $len) * $offset
                        $dy = ($dy / $len) * $offset
                        $g.DrawLine($bondPen, $x1 + $dx, $y1 + $dy, $x2 + $dx, $y2 + $dy)
                    }
                }

                $bondPen.Dispose()
            }

            # Atoms
            foreach ($atom in $molecule.Atoms) {
                $x = $cx + ($atom.LocalX * [Math]::Cos($rot) - $atom.LocalY * [Math]::Sin($rot))
                $y = $cy + ($atom.LocalX * [Math]::Sin($rot) + $atom.LocalY * [Math]::Cos($rot))

                foreach ($electron in $atom.Electrons) {
                    $eAngle = $electron.Angle * [Math]::PI / 180
                    $ex = $x + ($electron.Distance * [Math]::Cos($eAngle))
                    $ey = $y + ($electron.Distance * [Math]::Sin($eAngle))
                    $eBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 100, 150, 255))
                    $g.FillEllipse($eBrush, $ex - 2, $ey - 2, 4, 4)
                    $eBrush.Dispose()
                }

                $glowSize = $atom.Size * 2
                $atomGlowBrush = New-Object System.Drawing.SolidBrush(
                    [System.Drawing.Color]::FromArgb(30, $atom.Color.R, $atom.Color.G, $atom.Color.B)
                )
                $g.FillEllipse($atomGlowBrush, $x - $glowSize/2, $y - $glowSize/2, $glowSize, $glowSize)
                $atomGlowBrush.Dispose()

                $atomPath  = New-Object System.Drawing.Drawing2D.GraphicsPath
                $atomPath.AddEllipse($x - $atom.Size, $y - $atom.Size, $atom.Size * 2, $atom.Size * 2)
                $atomBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($atomPath)
                $atomBrush.CenterColor = [System.Drawing.Color]::FromArgb(
                    255,
                    [Math]::Min(255, $atom.Color.R + 80),
                    [Math]::Min(255, $atom.Color.G + 80),
                    [Math]::Min(255, $atom.Color.B + 80)
                )
                $atomBrush.SurroundColors = @($atom.Color)
                $g.FillPath($atomBrush, $atomPath)
                $atomBrush.Dispose()
                $atomPath.Dispose()

                $symbolFont  = New-Object System.Drawing.Font("Arial", [int]($atom.Size * 0.7), [System.Drawing.FontStyle]::Bold)
                $symbolBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
                $symbolSize  = $g.MeasureString($atom.Element, $symbolFont)
                $g.DrawString($atom.Element, $symbolFont, $symbolBrush, $x - $symbolSize.Width/2, $y - $symbolSize.Height/2)
                $symbolFont.Dispose()
                $symbolBrush.Dispose()
            }

            # Name label
            $nameFont  = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $nameBrush = New-Object System.Drawing.SolidBrush($molecule.Color)
            $nameSize  = $g.MeasureString($molecule.Name, $nameFont)

            $labelBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(150, 0, 0, 0))
            $g.FillRectangle($labelBg, $cx - $nameSize.Width/2 - 5, $cy - 80, $nameSize.Width + 10, $nameSize.Height + 4)
            $labelBg.Dispose()

            $g.DrawString($molecule.Name, $nameFont, $nameBrush, $cx - $nameSize.Width/2, $cy - 78)
            $nameFont.Dispose()
            $nameBrush.Dispose()

            # Stability bar
            $stabilityWidth  = 60
            $stabilityHeight = 6
            $stabilityX      = $cx - $stabilityWidth/2
            $stabilityY      = $cy + 70

            $stabilityBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 50, 50, 50))
            $g.FillRectangle($stabilityBg, $stabilityX, $stabilityY, $stabilityWidth, $stabilityHeight)
            $stabilityBg.Dispose()

            $stabilityFill  = ($molecule.Stability / 100) * $stabilityWidth
            $stabilityColor = if ($molecule.Stability -gt 80) {
                [System.Drawing.Color]::FromArgb(100, 255, 100)
            } elseif ($molecule.Stability -gt 60) {
                [System.Drawing.Color]::FromArgb(255, 200, 100)
            } else {
                [System.Drawing.Color]::FromArgb(255, 100, 100)
            }
            $stabilityBrush = New-Object System.Drawing.SolidBrush($stabilityColor)
            $g.FillRectangle($stabilityBrush, $stabilityX, $stabilityY, $stabilityFill, $stabilityHeight)
            $stabilityBrush.Dispose()
        }
    }

    hidden [void] DrawTicker([System.Drawing.Graphics]$g, [int]$width, [int]$height) {
        $tickerHeight = 35
        $tickerY      = $height - $tickerHeight - 5

        $tickerBg = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
        $g.FillRectangle($tickerBg, 0, $tickerY, $width, $tickerHeight)
        $tickerBg.Dispose()

        $tickerBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 100, 150, 255), 2)
        $g.DrawRectangle($tickerBorder, 0, $tickerY, $width - 1, $tickerHeight - 1)
        $tickerBorder.Dispose()

        $tickerText = "  COMPOUNDS: "
        foreach ($mol in $this.Molecules) {
            $tickerText += "$($mol.Name) (Stability: $($mol.Stability)%) • "
        }
        $tickerText += "   |   "

        $tickerFont  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $tickerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 200, 255))

        $textSize = $g.MeasureString($tickerText, $tickerFont)
        $tickerX  = $width - $this.State.TickerOffset

        $g.DrawString($tickerText, $tickerFont, $tickerBrush, $tickerX,               $tickerY + 8)
        $g.DrawString($tickerText, $tickerFont, $tickerBrush, $tickerX + $textSize.Width, $tickerY + 8)

        $tickerFont.Dispose()
        $tickerBrush.Dispose()
    }

    hidden [void] DrawTitle([System.Drawing.Graphics]$g, [int]$width) {
        $titleFont  = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(220, 100, 200, 255))
        $titleText  = "✨ MOLECULE INTERACTIONS"
        $titleSize  = $g.MeasureString($titleText, $titleFont)
        $g.DrawString($titleText, $titleFont, $titleBrush, ($width - $titleSize.Width) / 2, 10)
        $titleFont.Dispose()
        $titleBrush.Dispose()
    }
}

# ============================================
# GM v3 Compatibility Function
# ============================================
function Stop-Show37 {
    Write-Host "[Show37] Stop called (GM3 version)" -ForegroundColor Yellow

    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show37")) {
        $show = $Global:ShowManager.Shows["show37"]
        $show.Stop()
    }

    Write-Host "✅ [Show37] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow37 class loaded (GM3)" -ForegroundColor Green