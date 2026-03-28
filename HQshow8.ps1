# ====================================================
# HQshow8.ps1 — COMPLETE DUAL PANEL AI MONTAGE v3
# Panel 1: Animated Brain → CLICK → Panel 2: 6-Scene Montage
# 100% Original Behavior + Game Machine Architecture
# ====================================================

class Show8 : BaseShow {
    # State tracking
    hidden [string] $Mode = "Brain"  # "Brain" or "Montage"
    hidden [System.Windows.Forms.Button] $NextButton
    hidden [System.Windows.Forms.TableLayoutPanel] $Stage
    hidden [object[]] $SceneControls = @()
    hidden [object[]] $InputDots = @()
    hidden [object[]] $ActivationBars = @()
    hidden [object[]] $OutputLabels = @()
    hidden [object[]] $Buildings = @()
    hidden [System.Windows.Forms.Label] $OutputLabel
    hidden [System.Windows.Forms.TextBox] $Explanation
    hidden [int] $BrainStep = 0
    
    # Constructor - FIXED for BaseShow
    Show8([System.Windows.Forms.Panel]$panel) : base("show8", $panel) {
        Write-Host " 🧠 [Show8] Constructor initialized" -ForegroundColor Cyan
    }
    
    # ========================================
    # OnStart - Begin with Animated Brain (ORIGINAL)
    # ========================================
    [void] OnStart() {
        Write-Host " 📊 [Show8] **BRAIN PANEL** - DUAL PANEL v3 STARTING..." -ForegroundColor Magenta
        
        # Ticker messages (ORIGINAL)
        $Show8Messages = @(
            "📊 Analytics running smoothly...",
            "🧠 Neural network updating weights...",
            "⚡ Signals propagating through layers",
            "🔍 Evaluating brain lobes activity",
            "✅ Decisions being finalized"
        )
        $Global:messages = $Show8Messages
        
        # Show Brain Panel FIRST (ORIGINAL behavior)
        $this.ShowBrainPanel()
        
        Write-Host " ✅ [Show8] **BRAIN PANEL READY** → Click 'Next Step'!" -ForegroundColor Green
    }
    
    # ========================================
    # OnUpdate - Mode-specific animations
    # ========================================
    [void] OnUpdate() {
        switch ($this.Mode) {
            "Brain" { $this.UpdateBrain() }
            "Montage" { $this.UpdateMontage() }
        }
    }
    
    # ========================================
    # PANEL 1: ANIMATED BRAIN (100% ORIGINAL)
    # ========================================
    hidden [void] ShowBrainPanel() {
    $this.Panel.Controls.Clear()
    $this.Mode = "Brain"
    
    # Main content panel
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = 'Fill'
    $panel.BackColor = 'White'
    $this.Panel.Controls.Add($panel)
    
    # Input dots
    $this.InputDots = @()
    for ($i = 0; $i -lt 3; $i++) {
        $dot = New-Object System.Windows.Forms.Label
        $dot.Size = [System.Drawing.Size]::new(20, 20)
        $dot.BackColor = 'DarkCyan'
        $dot.Location = [System.Drawing.Point]::new(30, 50 + ($i * 60))
        $panel.Controls.Add($dot)
        $this.InputDots += $dot
    }
    
    # Activation bars
    $this.ActivationBars = @()
    for ($i = 0; $i -lt 4; $i++) {
        $bar = New-Object System.Windows.Forms.ProgressBar
        $bar.Width = 120
        $bar.Height = 20
        $bar.Style = 'Continuous'
        $bar.Location = [System.Drawing.Point]::new(150, 50 + ($i * 50))
        $panel.Controls.Add($bar)
        $this.ActivationBars += $bar
    }
    
    # Output labels
    $this.OutputLabels = @()
    foreach ($name in @("Class A", "Class B")) {
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $name
        $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $label.AutoSize = $true
        $label.Location = [System.Drawing.Point]::new(320, 60 + ($this.OutputLabels.Count * 80))
        $panel.Controls.Add($label)
        $this.OutputLabels += $label
    }
    
    # Explanation box
    $this.Explanation = New-Object System.Windows.Forms.TextBox
    $this.Explanation.Multiline = $true
    $this.Explanation.ReadOnly = $true
    $this.Explanation.ScrollBars = 'Vertical'
    $this.Explanation.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $this.Explanation.Size = [System.Drawing.Size]::new(280, 100)
    $this.Explanation.Location = [System.Drawing.Point]::new(20, 250)
    $panel.Controls.Add($this.Explanation)
    
    # === FIXED NEXT STEP BUTTON ===
    $self = $this  # Capture class reference for closure [web:104]
    $this.NextButton = New-Object System.Windows.Forms.Button
    $this.NextButton.Text = "▶ Next Step"
    $this.NextButton.Dock = "Bottom"
    $this.NextButton.Height = 35
    $this.NextButton.BackColor = [System.Drawing.Color]::LightBlue
    $this.NextButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $this.NextButton.Add_Click({
        $self.ShowMontagePanel()  # Use captured $self reference
    }.GetNewClosure())
    $this.Panel.Controls.Add($this.NextButton)
}

    hidden [void] UpdateBrain() {
        $this.BrainStep++
        
        # Animate input dots (ORIGINAL)
        if ($this.InputDots) {
            foreach ($dot in $this.InputDots) {
                $dot.BackColor = [System.Drawing.Color]::FromArgb(
                    (Get-Random -Minimum 50 -Maximum 200), 0, 128
                )
            }
        }
        
        # Animate activation bars (ORIGINAL)
        if ($this.ActivationBars) {
            foreach ($bar in $this.ActivationBars) {
                $bar.Value = Get-Random -Minimum 10 -Maximum 100
            }
        }
        
        # Update output decision (ORIGINAL)
        if ($this.OutputLabels -and $this.Explanation) {
            $decision = if ($this.BrainStep % 2 -eq 0) { "Class A" } else { "Class B" }
            foreach ($label in $this.OutputLabels) {
                $label.ForeColor = if ($label.Text -eq $decision) { 'Red' } else { 'Black' }
            }
            $this.Explanation.Text = "Processing input #$($this.BrainStep)`r`n→ Neurons firing...`r`n→ Decision: $decision"
        }
    }
    
    # ========================================
    # PANEL 2: 6-SCENE MONTAGE (100% ORIGINAL)
    # ========================================
    hidden [void] ShowMontagePanel() {
        Write-Host " 📊 [Show8] → Switched to 6-Scene Montage!" -ForegroundColor Cyan
        $this.Panel.Controls.Clear()
        $this.Mode = "Montage"
        $this.BuildAllScenes()
    }
    
    hidden [void] BuildAllScenes() {
        # Ticker messages for montage
        $Global:messages = @(
            "Here are news from SHOW8... ",
            "🔵 Input signals fluctuating...",
            "⚡ Neurons firing rapidly",
            "🧮 Weights recalculated",
            "🤖 Brain leans towards decision"
        )
        
        $this.Stage = New-Object System.Windows.Forms.TableLayoutPanel
        $this.Stage.Dock = "Fill"
        $this.Stage.RowCount = 2
        $this.Stage.ColumnCount = 3
        $this.Stage.CellBorderStyle = "Single"
        $this.Stage.AutoScroll = $true
        $this.Panel.Controls.Add($this.Stage)
        $this.SceneControls = @()
        
        # === SCENE 1: Decision Tree ===
        $tree = New-Object System.Windows.Forms.TreeView
        $root = New-Object System.Windows.Forms.TreeNode("Buy Wine?")
        $root.Nodes.Add("Age < 30 → No")
        $root.Nodes.Add("Age ≥ 30 → Income Check")
        $root.Nodes[1].Nodes.Add("Income < 50k → No")
        $root.Nodes[1].Nodes.Add("Income ≥ 50k → Yes")
        $tree.Nodes.Add($root)
        $tree.ExpandAll()
        $this.AddSceneBox("Decision Tree", $tree)
        
        # === SCENE 2: Regression Chart ===
        try {
            Add-Type -AssemblyName "System.Windows.Forms.DataVisualization"
            $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
            $chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
            $chart.ChartAreas.Add($chartArea)
            
            $seriesActual = New-Object System.Windows.Forms.DataVisualization.Charting.Series("Actual")
            $seriesActual.ChartType = "Line"
            $seriesActual.Points.AddXY(1,100); $seriesActual.Points.AddXY(2,150)
            $seriesActual.Points.AddXY(3,200); $seriesActual.Points.AddXY(4,250)
            
            $seriesPred = New-Object System.Windows.Forms.DataVisualization.Charting.Series("Predicted")
            $seriesPred.ChartType = "Line"
            $seriesPred.BorderDashStyle = "Dash"
            $seriesPred.Color = [System.Drawing.Color]::Red
            $seriesPred.Points.AddXY(4,250); $seriesPred.Points.AddXY(5,280)
            $seriesPred.Points.AddXY(6,310)
            
            $chart.Series.Add($seriesActual)
            $chart.Series.Add($seriesPred)
            $this.AddSceneBox("Regression & Prediction", $chart)
        } catch {
            $lblChart = New-Object System.Windows.Forms.Label
            $lblChart.Text = "📈 Regression Chart`n(Actual vs Predicted)"
            $lblChart.TextAlign = "MiddleCenter"
            $this.AddSceneBox("Regression & Prediction", $lblChart)
        }
        
        # === SCENE 3: Neural Neuron ===
        $lblNeuron = New-Object System.Windows.Forms.Label
        $lblNeuron.Text = "⚡ Input → Weight → Output"
        $lblNeuron.TextAlign = "MiddleCenter"
        $lblNeuron.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $this.AddSceneBox("Neural Neuron", $lblNeuron)
        
        # === SCENE 4: Brain Lobes ===
        $brainPanel = New-Object System.Windows.Forms.TableLayoutPanel
        $brainPanel.RowCount = 2
        $brainPanel.ColumnCount = 2
        $brainPanel.Dock = "Fill"
        
        $colors = @("LightSkyBlue","LightGreen","LightPink","Khaki")
        $lobes = @("Research","Development","Collaboration","Evaluation")
        
        for ($i = 0; $i -lt $lobes.Count; $i++) {
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = $lobes[$i]
            $lbl.TextAlign = "MiddleCenter"
            $lbl.Dock = "Fill"
            $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
            $lbl.BackColor = [System.Drawing.Color]::FromName($colors[$i])
            $lbl.BorderStyle = "FixedSingle"
            $brainPanel.Controls.Add($lbl)
        }
        $this.AddSceneBox("Brain Lobes", $brainPanel)
        
        # === SCENE 5: Ethics & Compliance ===
        $traffic = New-Object System.Windows.Forms.FlowLayoutPanel
        $traffic.FlowDirection = "TopDown"
        $traffic.WrapContents = $false
        $traffic.Dock = "Fill"
        $traffic.AutoSize = $true
        
        $signals = @(
            @{Color="Red"; Text="Stop"},
            @{Color="Yellow"; Text="Caution"},
            @{Color="Green"; Text="Go"}
        )
        
        foreach ($sig in $signals) {
            $stack = New-Object System.Windows.Forms.Panel
            $stack.Width = 60; $stack.Height = 60
            $stack.BackColor = "White"
            
            $light = New-Object System.Windows.Forms.Panel
            $light.Size = [System.Drawing.Size]::new(30,30)
            $light.BackColor = [System.Drawing.Color]::FromName($sig.Color)
            $light.Left = 15; $light.Top = 5
            $light.BorderStyle = "FixedSingle"
            
            $label = New-Object System.Windows.Forms.Label
            $label.Text = $sig.Text
            $label.Dock = "Bottom"
            $label.TextAlign = "MiddleCenter"
            
            $stack.Controls.Add($light)
            $stack.Controls.Add($label)
            $traffic.Controls.Add($stack)
        }
        $this.AddSceneBox("Ethics & Compliance", $traffic)
        
        # === SCENE 6: Energy Optimization (ANIMATED) ===
        $city = New-Object System.Windows.Forms.FlowLayoutPanel
        $city.Dock = "Fill"
        $city.WrapContents = $false
        $city.AutoScroll = $false
        
        $this.Buildings = @()
        for ($i = 1; $i -le 8; $i++) {
            $b = New-Object System.Windows.Forms.Panel
            $b.Width = 20
            $b.Height = (Get-Random -Minimum 30 -Maximum 80)
            $b.BackColor = [System.Drawing.Color]::FromArgb((50 + $i*20) % 255, 100, 150)
            $city.Controls.Add($b)
            $this.Buildings += $b
        }
        $this.AddSceneBox("Energy Optimization", $city)
    }
    
    hidden [void] UpdateMontage() {
        # Animate skyline buildings (ORIGINAL)
        if ($this.Buildings -and $this.Buildings.Count -gt 0) {
            foreach ($b in $this.Buildings) {
                $b.Height = (Get-Random -Minimum 30 -Maximum 100)
            }
        }
        if ($this.Stage) { 
            $this.Stage.Invalidate() 
        }
    }
    
    hidden [void] AddSceneBox([string]$title, [object]$control) {
        $box = New-Object System.Windows.Forms.Panel
        $box.Dock = "Fill"
        $box.BackColor = [System.Drawing.Color]::White
        
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $title
        $lbl.Dock = "Top"
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $lbl.TextAlign = "MiddleCenter"
        $lbl.Height = 24
        $box.Controls.Add($lbl)
        
        $control.Dock = "Fill"
        $box.Controls.Add($control)
        $this.Stage.Controls.Add($box)
        $this.SceneControls += $box
    }
    
    # ========================================
    # OnStop - Cleanup both panels (ORIGINAL)
    # ========================================
    [void] OnStop() {
        Write-Host " 🛑 [Show8] Dual panel cleanup..." -ForegroundColor Yellow
        
        if ($this.NextButton) {
            try { $this.NextButton.Remove_Click($null) } catch {}
            $this.NextButton.Dispose()
            $this.NextButton = $null
        }
        
        # Clear all collections
        $this.SceneControls = @()
        $this.InputDots = @()
        $this.ActivationBars = @()
        $this.OutputLabels = @()
        $this.Buildings = @()
        $this.Explanation = $null
        $this.OutputLabel = $null
        
        $this.Panel.Controls.Clear()
        Write-Host " ✅ [Show8] Dual panel cleanup complete" -ForegroundColor Green
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-Show8 {
    Write-Host "🛑 [Show8] Stop called (v3 dual-panel version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show8")) {
        $show = $Global:ShowManager.Shows["show8"]
        $show.Stop()
    }
    
    Write-Host "✅ [Show8] Stopped" -ForegroundColor Green
}

Write-Host "✅ COMPLETE HQshow8 DUAL PANEL v3 LOADED!" -ForegroundColor Green
Write-Host "   → Starts with ANIMATED BRAIN + Next Step button" -ForegroundColor Green
Write-Host "   → Click → 6-SCENE MONTAGE with animated skyline" -ForegroundColor Green


