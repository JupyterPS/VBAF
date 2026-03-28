# ===============================
# Show20 — Wine Castles ULTIMATE (Agent v1)
# Adaptive AI/ML Simulation in PowerShell
# ===============================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -------------------------------
# Agent Class
# -------------------------------
class Show20Agent {
    [hashtable]$State
    [double]$LearningRate

    Show20Agent([double]$learningRate = 0.1) {
        $this.State = @{
            SpeedMean      = 0.5
            TowerCountMean = 4
            CastleTypeWeights = @{
                "Gothic"=1; "FairyTale"=1; "Fortress"=1; "Palace"=1; 
                "Wizard"=1; "Cathedral"=1; "Oriental"=1; "Ruins"=1
            }
        }
        $this.LearningRate = $learningRate
    }

    [string] DecideCastleType() {
        $total = ($this.State.CastleTypeWeights.Values | Measure-Object -Sum).Sum
        $r = Get-Random -Minimum 0 -Maximum $total
        $acc = 0
        foreach ($type in $this.State.CastleTypeWeights.Keys) {
            $acc += $this.State.CastleTypeWeights[$type]
            if ($r -le $acc) { return $type }
        }
        return "Gothic"
    }

    [double] DecideSpeed() {
        return [Math]::Max(0.1, $this.State.SpeedMean + ((Get-Random -Minimum -0.2 -Maximum 0.2)))
    }

    [int] DecideTowerCount() {
        $base = $this.State.TowerCountMean
        return [Math]::Max(1, [int]($base + (Get-Random -Minimum -1 -Maximum 2)))
    }

    [void] Learn([string]$castleType, [double]$reward) {
        $oldWeight = $this.State.CastleTypeWeights[$castleType]
        $this.State.CastleTypeWeights[$castleType] = $oldWeight + $reward * $this.LearningRate
    }
}

# -------------------------------
# Show20 Class
# -------------------------------
class Show20 {
    [System.Windows.Forms.Panel]$Panel
    [System.Collections.ArrayList]$Castles
    [hashtable]$State
    [Show20Agent]$Agent

    Show20([System.Windows.Forms.Panel]$panel, [Show20Agent]$agent) {
        $this.Panel = $panel
        $this.Castles = [System.Collections.ArrayList]::new()
        $this.State = @{ TickCount=0; Stars=@() }
        $this.Agent = $agent
        $this.InitializeStars()
        $this.InitializeCastles()
        $this.SetupEvents()
        $this.SetupHotkeys()
    }

    [void] InitializeStars() {
        $this.State.Stars = @()
        for ($i=0; $i -lt 80; $i++) {
            $this.State.Stars += @{
                X = Get-Random -Minimum 0 -Maximum 1200
                Y = Get-Random -Minimum 0 -Maximum 250
                Brightness = Get-Random -Minimum 100 -Maximum 255
                Size = Get-Random -Minimum 1 -Maximum 3
            }
        }
    }

    [void] InitializeCastles() {
        $this.Castles.Clear()
        for ($i=0; $i -lt 7; $i++) {
            $castle = @{
                X=0; Y=0; Width=0; Height=0; Speed=0; Type=""; Towers=@(); Flags=@(); Torches=@()
            }
            $this.Castles.Add($castle) | Out-Null
        }
        $width = $this.Panel.Width
        foreach ($c in $this.Castles) {
            $this.RandomizeCastle($c, $width)
        }
    }

    [void] RandomizeCastle($castle, [int]$canvasWidth) {
        $groundY = [math]::Max(260, [int]($this.Panel.Height*0.6))
        # Agent decides
        $castle.Type   = $this.Agent.DecideCastleType()
        $castle.Speed  = $this.Agent.DecideSpeed()
        $towerCount    = $this.Agent.DecideTowerCount()

        $castle.X = $canvasWidth + (Get-Random -Minimum 60 -Maximum 350)
        $castle.Width  = 100
        $castle.Height = 100
        $castle.Y = $groundY - $castle.Height

        # Build towers
        $castle.Towers = @()
        for ($t=0; $t -lt $towerCount; $t++) {
            $castle.Towers += @{ X=($t*20); Width=20; Height=50; HasRoof=$true; RoofType="Pointed"; HasFlag=(Get-Random -Minimum 0 -Maximum 2) -eq 1 }
        }

        $this.AddFlags($castle)
        $this.AddTorches($castle, [Math]::Max(1,[int]($towerCount/2)))

        # Reward feedback
        $reward = (Get-Random -Minimum 0.5 -Maximum 1.5)
        $this.Agent.Learn($castle.Type, $reward)
        Write-Host "[Agent] CastleType=$($castle.Type), Reward=$reward" -ForegroundColor Cyan
    }

    [void] AddFlags($castle) {
        $flags = @()
        foreach ($t in $castle.Towers) {
            if ($t.HasFlag) {
                $flags += @{ X=$t.X; Y=-$t.Height-10; Phase=Get-Random -Minimum 0 -Maximum 6.28; WaveOffset=0; Color=[System.Drawing.Color]::Red }
            }
        }
        $castle.Flags = $flags
    }

    [void] AddTorches($castle, [int]$count) {
        $torches=@()
        for ($i=0; $i -lt $count; $i++) {
            $torches += @{ X=Get-Random -Minimum 0 -Maximum $castle.Width; Y=Get-Random -Minimum 0 -Maximum $castle.Height; Phase=Get-Random -Minimum 0 -Maximum 6.28; FlickerOffset=0; FlickerSize=1 }
        }
        $castle.Torches = $torches
    }

    [void] SetupEvents() {
        $self = $this
        $this.Panel.Add_Paint({
            param($s, $e)
            $self.RenderCanvas($e.Graphics, $s.Width, $s.Height)
        }.GetNewClosure())
    }

    [void] OnUpdate() {
        $this.State.TickCount++
        foreach ($c in $this.Castles) {
            $c.X -= $c.Speed
            if ($c.X + $c.Width -lt -50) { $this.RandomizeCastle($c, $this.Panel.Width) }
        }
        $this.Panel.Invalidate()
    }

    [void] RenderCanvas([System.Drawing.Graphics]$g, [int]$w, [int]$h) {
        if ($w -le 0 -or $h -le 0) { return }
        $g.Clear([System.Drawing.Color]::FromArgb(8,6,15))

        # Stars
        foreach ($star in $this.State.Stars) {
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($star.Brightness,255,255,230))
            $g.FillEllipse($brush, $star.X, $star.Y, $star.Size, $star.Size)
            $brush.Dispose()
        }

        $groundY = [math]::Max(260, [int]($h*0.6))

        # Castles
        foreach ($c in $this.Castles) {
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180,150,120))
            $g.FillRectangle($brush, [int]$c.X, [int]$c.Y, [int]$c.Width, [int]$c.Height)
            $brush.Dispose()
        }
    }
        # ---------- BULLETPROOF DEBUGGING ----------

    # Generic method invoker using reflection (case‑safe, event‑safe)
    hidden [void] InvokeMethod([string]$methodName) {
        $type = $this.GetType()
        $method = $type.GetMethod($methodName)

        if ($method -ne $null) {
            $method.Invoke($this, @())
        } else {
            Write-Host "Method '$methodName' not found on Show20" -ForegroundColor Red
        }
    }

    # The actual dump method (rename/extend as you like)
[void] DumpState() {
    $line = ('=' * 60)

    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host " SHOW20 — STATE DUMP" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
    Write-Host ("Timestamp: {0}" -f (Get-Date)) -ForegroundColor DarkGray

    # ----- STATE -----
    Write-Host "`n[STATE]" -ForegroundColor Yellow
    if ($this.State) {
        $this.State.GetEnumerator() |
            Sort-Object Name |
            ForEach-Object {
                Write-Host ("{0} = {1}" -f $_.Name, ($_.Value -join ', '))
            }
    } else {
        Write-Host "(State is null)" -ForegroundColor DarkGray
    }

    # ----- CASTLES -----
    Write-Host "`n[CASTLES]" -ForegroundColor Yellow
    if ($this.Castles -and $this.Castles.Count -gt 0) {
        $i = 0
        foreach ($c in $this.Castles) {
            Write-Host ("[{0}] X={1,6:N1}  Y={2,4}  W={3,3}  H={4,3}  Speed={5:N3}" -f `
                $i, $c.X, $c.Y, $c.Width, $c.Height, $c.Speed)
            $i++
        }
    } else {
        Write-Host "(No castles)" -ForegroundColor DarkGray
    }

    # ----- AGENT -----
    Write-Host "`n[AGENT]" -ForegroundColor Yellow
    if ($this.Agent) {
        Write-Host ("LearningRate = {0}" -f $this.Agent.LearningRate)
        if ($this.Agent.State) {
            $this.Agent.State.GetEnumerator() |
                Sort-Object Name |
                ForEach-Object {
                    Write-Host ("State.{0} = {1}" -f $_.Name, $_.Value)
                }
        }
    } else {
        Write-Host "(Agent is null)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

    # Hotkeys for live debug inside the running form
    [void] SetupHotkeys() {
        $form = $this.Panel.Parent
        $form.KeyPreview = $true
        $self = $this

        $form.Add_KeyDown({
            param($s,$e)

            # Ctrl+D → QuickDump
            if ($e.Control -and $e.KeyCode -eq 'D') {
                Write-Host "`n=== QUICK DUMP (Ctrl+D) ==="
                $self.InvokeMethod("DumpState")
            }

            # Ctrl+Shift+D → QuickDump
            if ($e.Control -and $e.Shift -and $e.KeyCode -eq 'D') {
                Write-Host "`n=== QUICK DUMP (Ctrl+Shift+D) ==="
                $self.InvokeMethod("DumpState")
            }

            # Optional: F12 → QuickDump
            if ($e.KeyCode -eq 'F12') {
                Write-Host "`n=== QUICK DUMP (F12) ==="
                $self.InvokeMethod("DumpState")
            }

        }.GetNewClosure())
    }
}

# -------------------------------
# Initialize Form & Panel
# -------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Width = 1200
$form.Height = 400
$form.Text = "Wine Castle Parade - AI Agent Demo"

$panel = New-Object System.Windows.Forms.Panel
$panel.Dock = "Fill"
$form.Controls.Add($panel)

# -------------------------------
# Initialize Agent and Show
# -------------------------------
$agent = [Show20Agent]::new(0.2)
$show20 = [Show20]::new($panel, $agent)

# -------------------------------
# Timer Loop
# -------------------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 50
$timer.Add_Tick({ $show20.OnUpdate() })
$timer.Start()

$form.ShowDialog()
