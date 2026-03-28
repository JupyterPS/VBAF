 
 # ====================================================
# HQshow7.ps1 — Neural Network Playground v3
# Converted to Game Machine Architecture
# INTERACTIVE - Click neurons to activate!
# ====================================================
Write-Host "`n=> _____ HQshow7 (Neural Network v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# Show7 - Inherits from BaseShow (Interactive)
# ============================================
class Show7 : BaseShow {
    # Private properties for interactive elements
    hidden [System.Windows.Forms.Panel] $MainPanel
    hidden [System.Windows.Forms.Button[]] $Neurons
    hidden [System.Windows.Forms.Label[]] $Outputs
    hidden [int] $PulseStep = 0
    
    # Constructor
    Show7([System.Windows.Forms.Panel]$panel) : base("show7", $panel) {
        $this.Neurons = @()
        $this.Outputs = @()
    }
    
    # OnStart - Initialize interactive neural network
    [void] OnStart() {
        Write-Host " 🧠 [Show7] Initializing Neural Network Playground..." -ForegroundColor Cyan
        
        # Clear and setup main panel
        $this.Panel.Controls.Clear()
        $this.MainPanel = New-Object System.Windows.Forms.Panel
        $this.MainPanel.Dock = 'Fill'
        $this.MainPanel.BackColor = [System.Drawing.Color]::White
        $this.Panel.Controls.Add($this.MainPanel)
        
        # Ticker messages
        $Show7Messages = @(
            "🧠 Neural Network Playground",
            "⚡ Click neurons to activate them",
            "📊 Watch predictions update in real-time"
        )
        $Global:messages = $Show7Messages
        
        # Initialize neurons and outputs
        $this.InitializeNeurons()
        $this.InitializeOutputs()
        $this.SetupEvents()
        
        Write-Host " ✅ [Show7] Neural Network Playground ready (Interactive!)" -ForegroundColor Green
    }
    
    # OnUpdate - Pulsing animation
    [void] OnUpdate() {
        $this.PulseStep++
        foreach ($btn in $this.Neurons) {
            if ($btn.BackColor -eq [System.Drawing.Color]::Yellow) {
                $btn.BackColor = if ($this.PulseStep % 2 -eq 0) { 
                    [System.Drawing.Color]::Gold 
                } else { 
                    [System.Drawing.Color]::Yellow 
                }
            }
        }
        $this.MainPanel.Invalidate()
    }
    
    # OnStop - Cleanup interactive elements
    [void] OnStop() {
        Write-Host " 🛑 [Show7] Cleaning up..." -ForegroundColor Yellow
        
        # Remove event handlers
        foreach ($btn in $this.Neurons) {
            try { $btn.Remove_Click($null) } catch {}
        }
        
        # Clear collections
        $this.Neurons = @()
        $this.Outputs = @()
        $this.PulseStep = 0
        
        # Clear controls
        if ($this.MainPanel) {
            $this.MainPanel.Controls.Clear()
            $this.MainPanel.Dispose()
            $this.MainPanel = $null
        }
        $this.Panel.Controls.Clear()
        
        Write-Host " ✅ [Show7] Cleanup complete" -ForegroundColor Green
    }
    
    # Private initialization methods
    hidden [void] InitializeNeurons() {
        for ($i = 0; $i -lt 5; $i++) {
            $btn = New-Object System.Windows.Forms.Button
            $btn.Size = [Drawing.Size]::new(50, 50)
            $btn.Location = [Drawing.Point]::new(30, 30 + ($i * 70))
            $btn.Text = "$i"
            $btn.Font = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $btn.BackColor = [System.Drawing.Color]::LightGray
            $this.MainPanel.Controls.Add($btn)
            $this.Neurons += $btn
        }
    }
    
    hidden [void] InitializeOutputs() {
        $outputNames = @("Class A", "Class B", "Class C")
        for ($j = 0; $j -lt $outputNames.Count; $j++) {
            $lbl = New-Object System.Windows.Forms.Label
            $lbl.Text = $outputNames[$j]
            $lbl.Font = [System.Drawing.Font]::new("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $lbl.AutoSize = $true
            $lbl.Location = [Drawing.Point]::new(250, 50 + ($j * 70))
            $lbl.BackColor = [System.Drawing.Color]::White
            $this.MainPanel.Controls.Add($lbl)
            $this.Outputs += $lbl
        }
    }
    
    hidden [void] SetupEvents() {
        # Neuron click events (interactive!)
        for ($i = 0; $i -lt $this.Neurons.Length; $i++) {
            $neuron = $this.Neurons[$i]
            $outputsCopy = $this.Outputs  # Capture for closure
            
            $neuron.Add_Click({
                param($s, $e)
                # Toggle neuron activation
                $this.BackColor = if ($this.BackColor -eq [System.Drawing.Color]::LightGray) {
                    [System.Drawing.Color]::Yellow
                } else {
                    [System.Drawing.Color]::LightGray
                }
                
                # Update predictions (random color-coded)
                $colors = @(
                    [System.Drawing.Color]::LightGreen, 
                    [System.Drawing.Color]::LightBlue, 
                    [System.Drawing.Color]::LightCoral
                )
                for ($k = 0; $k -lt $outputsCopy.Count; $k++) {
                    $outputsCopy[$k].BackColor = $colors[(Get-Random -Minimum 0 -Maximum $colors.Count)]
                }
            }.GetNewClosure())
        }
        
        # Paint event for connecting lines
        $self = $this
        $this.MainPanel.Add_Paint({
            param($s, $e)
            $g = $e.Graphics
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gray, 2)
            
            foreach ($n in $self.Neurons) {
                $nx = $n.Left + $n.Width
                $ny = $n.Top + $n.Height / 2
                foreach ($o in $self.Outputs) {
                    $ox = $o.Left
                    $oy = $o.Top + $o.Height / 2
                    $g.DrawLine($pen, $nx, $ny, $ox, $oy)
                }
            }
            $pen.Dispose()
        }.GetNewClosure())
    }
}

# Legacy compatibility
function Stop-Show7 {
    Write-Host "🛑 [Show7] Stop called (v3 version)" -ForegroundColor Yellow
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("show7")) {
        $Global:ShowManager.Shows["show7"].Stop()
    }
    Write-Host "✅ [Show7] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshow7 class loaded (v3) - INTERACTIVE!" -ForegroundColor Green

