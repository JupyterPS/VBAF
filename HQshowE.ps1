# ====================================================
# HQshowE.ps1 — System Health Monitor v3
# Converted to Game Machine Architecture
# ====================================================

Write-Host "`n=> _____ HQshowE (Health Monitor v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# ShowE - Inherits from BaseShow
# ============================================
class ShowE : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [hashtable] $History
    hidden [hashtable] $Problems
    hidden [System.Windows.Forms.Label] $StatusLabel
    hidden [System.Windows.Forms.Label] $VitalsLabel
    hidden [System.Windows.Forms.Label] $ProblemsLabel
    hidden [System.Windows.Forms.Label] $RecsLabel
    hidden [int] $UpdateCounter
    
    # ========================================
    # Constructor
    # ========================================
    ShowE([System.Windows.Forms.Panel]$panel) : base("showE", $panel) {
        # Initialize state
        $this.State = @{
            MaxHistoryPoints = 50
            CurrentStatus = "UNKNOWN"
            LastScan = $null
        }
        
        # Initialize history
        $this.History = @{
            Memory = [System.Collections.ArrayList]::new()
            Timers = [System.Collections.ArrayList]::new()
            Particles = [System.Collections.ArrayList]::new()
            Score = [System.Collections.ArrayList]::new()
            Timestamps = [System.Collections.ArrayList]::new()
        }
        
        # Initialize problems counter
        $this.Problems = @{
            TimerAccumulation = 0
            MemoryLeaks = 0
            DoubleInitialization = 0
        }
        
        $this.UpdateCounter = 0
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  🏥 [ShowE] Initializing Health Monitor..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(15, 20, 30)
        
        # Create UI
        $this.CreateHeader()
        $this.CreateContentArea()
        
        # Initial scan
        $this.UpdateDisplay()
        
        Write-Host "  ✅ [ShowE] Health Monitor ready" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM (~50ms)
    [void] OnUpdate() {
        $this.UpdateCounter++
        
        # Update every 40 ticks (2 seconds at 50ms = 2000ms)
        if ($this.UpdateCounter -ge 40) {
            $this.UpdateCounter = 0
            $this.UpdateDisplay()
        }
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [ShowE] Cleaning up..." -ForegroundColor Yellow
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset counter
        $this.UpdateCounter = 0
        
        Write-Host "  ✅ [ShowE] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
# Create header
hidden [void] CreateHeader() {
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Dock = "Top"
    $headerPanel.Height = 40   # Slimmer height
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(25, 35, 50)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "COMMERCE BANK - System Health Monitor"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) # Slightly smaller font
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.Location = New-Object System.Drawing.Point(20, 10) # Adjusted Y position
    $titleLabel.AutoSize = $true
    $headerPanel.Controls.Add($titleLabel)
    
    $this.Panel.Controls.Add($headerPanel)
}

    
    # Create content area with all boxes
    hidden [void] CreateContentArea() {
        $contentPanel = New-Object System.Windows.Forms.Panel
        $contentPanel.Dock = "Fill"
        $contentPanel.AutoScroll = $true
        $this.Panel.Controls.Add($contentPanel)
        
        # Status box
        $statusBox = New-Object System.Windows.Forms.GroupBox
        $statusBox.Text = "Current System Status"
        $statusBox.Location = New-Object System.Drawing.Point(20, 10)
        $statusBox.Size = New-Object System.Drawing.Size(300, 180)
        $statusBox.ForeColor = [System.Drawing.Color]::White
        $statusBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        
        $this.StatusLabel = New-Object System.Windows.Forms.Label
        $this.StatusLabel.Location = New-Object System.Drawing.Point(15, 25)
        $this.StatusLabel.Size = New-Object System.Drawing.Size(270, 140)
        $this.StatusLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.StatusLabel.ForeColor = [System.Drawing.Color]::LightGray
        $this.StatusLabel.Text = "Initializing..."
        $statusBox.Controls.Add($this.StatusLabel)
        $contentPanel.Controls.Add($statusBox)
        
        # Vitals box
        $vitalsBox = New-Object System.Windows.Forms.GroupBox
        $vitalsBox.Text = "6 Vital Signs"
        $vitalsBox.Location = New-Object System.Drawing.Point(340, 10)
        $vitalsBox.Size = New-Object System.Drawing.Size(280, 180)
        $vitalsBox.ForeColor = [System.Drawing.Color]::White
        $vitalsBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        
        $this.VitalsLabel = New-Object System.Windows.Forms.Label
        $this.VitalsLabel.Location = New-Object System.Drawing.Point(15, 25)
        $this.VitalsLabel.Size = New-Object System.Drawing.Size(250, 140)
        $this.VitalsLabel.Font = New-Object System.Drawing.Font("Consolas", 8)
        $this.VitalsLabel.ForeColor = [System.Drawing.Color]::LightGray
        $this.VitalsLabel.Text = "Scanning..."
        $vitalsBox.Controls.Add($this.VitalsLabel)
        $contentPanel.Controls.Add($vitalsBox)
        
        # Problems box
        $problemsBox = New-Object System.Windows.Forms.GroupBox
        $problemsBox.Text = "3 Core Problems Detected"
        $problemsBox.Location = New-Object System.Drawing.Point(20, 200)
        $problemsBox.Size = New-Object System.Drawing.Size(600, 120)
        $problemsBox.ForeColor = [System.Drawing.Color]::White
        $problemsBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        
        $this.ProblemsLabel = New-Object System.Windows.Forms.Label
        $this.ProblemsLabel.Location = New-Object System.Drawing.Point(15, 25)
        $this.ProblemsLabel.Size = New-Object System.Drawing.Size(570, 80)
        $this.ProblemsLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.ProblemsLabel.ForeColor = [System.Drawing.Color]::Yellow
        $this.ProblemsLabel.Text = "Monitoring..."
        $problemsBox.Controls.Add($this.ProblemsLabel)
        $contentPanel.Controls.Add($problemsBox)
        
        # Recommendations box
        $recsBox = New-Object System.Windows.Forms.GroupBox
        $recsBox.Text = "Recommendations"
        $recsBox.Location = New-Object System.Drawing.Point(20, 330)
        $recsBox.Size = New-Object System.Drawing.Size(600, 60)
        $recsBox.ForeColor = [System.Drawing.Color]::White
        $recsBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        
        $this.RecsLabel = New-Object System.Windows.Forms.Label
        $this.RecsLabel.Location = New-Object System.Drawing.Point(15, 25)
        $this.RecsLabel.Size = New-Object System.Drawing.Size(570, 30)
        $this.RecsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $this.RecsLabel.ForeColor = [System.Drawing.Color]::Cyan
        $this.RecsLabel.Text = "No recommendations yet..."
        $recsBox.Controls.Add($this.RecsLabel)
        $contentPanel.Controls.Add($recsBox)
    }
    
    # Get system vitals (comprehensive health check)
    hidden [hashtable] GetSystemVitals() {
        $vitals = @{
            Timestamp = Get-Date
            Checks = @{}
            Score = 0
            MaxScore = 100
            Status = "UNKNOWN"
            Problems = @()
        }
        
        # CHECK 1: Memory Usage
        $memoryMB = [Math]::Round([System.GC]::GetTotalMemory($false) / 1MB, 2)
        $memoryScore = 0
        $memoryStatus = "UNKNOWN"
        
        if ($memoryMB -lt 50) {
            $memoryScore = 25
            $memoryStatus = "EXCELLENT"
        } elseif ($memoryMB -lt 100) {
            $memoryScore = 20
            $memoryStatus = "GOOD"
        } elseif ($memoryMB -lt 150) {
            $memoryScore = 15
            $memoryStatus = "FAIR"
            $vitals.Problems += "Memory usage elevated"
        } elseif ($memoryMB -lt 200) {
            $memoryScore = 10
            $memoryStatus = "WARNING"
            $vitals.Problems += "High memory usage"
        } else {
            $memoryScore = 0
            $memoryStatus = "CRITICAL"
            $vitals.Problems += "CRITICAL: Memory overload"
        }
        
        $vitals.Checks.Memory = @{
            Value = $memoryMB
            Score = $memoryScore
            Status = $memoryStatus
            MaxScore = 25
        }
        
        # CHECK 2: Active Timers (V1 only - GM has 1 timer)
        $activeTimers = @()
        $vars = Get-Variable -Scope Global -ErrorAction SilentlyContinue
        foreach ($var in $vars) {
            if ($var.Name -like '*Timer' -and $var.Value -is [System.Windows.Forms.Timer]) {
                if ($var.Value.Enabled) {
                    $activeTimers += $var.Name
                }
            }
        }
        
        $timerCount = $activeTimers.Count
        $timerScore = 0
        $timerStatus = "UNKNOWN"
        
        if ($timerCount -le 1) {
            $timerScore = 30
            $timerStatus = "EXCELLENT"
        } elseif ($timerCount -le 2) {
            $timerScore = 25
            $timerStatus = "GOOD"
        } elseif ($timerCount -le 4) {
            $timerScore = 15
            $timerStatus = "WARNING"
            $vitals.Problems += "Multiple timers active ($timerCount)"
            $this.Problems.TimerAccumulation++
        } else {
            $timerScore = 0
            $timerStatus = "CRITICAL"
            $vitals.Problems += "CRITICAL: Too many timers ($timerCount)"
            $this.Problems.TimerAccumulation++
        }
        
        $vitals.Checks.Timers = @{
            Value = $timerCount
            ActiveTimers = $activeTimers
            Score = $timerScore
            Status = $timerStatus
            MaxScore = 30
        }
        
        # CHECK 3: Particle Buildup
        $totalParticles = 0
        for ($i = 1; $i -le 60; $i++) {
            $dataVarName = "show${i}Data"
            if (Get-Variable -Name $dataVarName -Scope Global -ErrorAction SilentlyContinue) {
                $data = (Get-Variable -Name $dataVarName -Scope Global -ValueOnly)
                if ($data) {
                    $particleProps = @('Rockets', 'Particles', 'FinalLetters', 'KPIorbs', 'Sparks', 'Trees')
                    foreach ($prop in $particleProps) {
                        if ($data.PSObject.Properties.Name -contains $prop) {
                            $count = $data.$prop.Count
                            if ($count -gt 0) {
                                $totalParticles += $count
                            }
                        }
                    }
                }
            }
        }
        
        $particleScore = 0
        $particleStatus = "UNKNOWN"
        
        if ($totalParticles -eq 0) {
            $particleScore = 20
            $particleStatus = "CLEAN"
        } elseif ($totalParticles -lt 500) {
            $particleScore = 15
            $particleStatus = "ACCEPTABLE"
        } elseif ($totalParticles -lt 1000) {
            $particleScore = 10
            $particleStatus = "HEAVY"
            $vitals.Problems += "High particle count ($totalParticles)"
            $this.Problems.MemoryLeaks++
        } else {
            $particleScore = 0
            $particleStatus = "OVERLOADED"
            $vitals.Problems += "CRITICAL: Particle overload ($totalParticles)"
            $this.Problems.MemoryLeaks++
        }
        
        $vitals.Checks.Particles = @{
            Value = $totalParticles
            Score = $particleScore
            Status = $particleStatus
            MaxScore = 20
        }
        
        # CHECK 4: Visible Panels
        $visiblePanels = @()
        if ($Global:floorshows) {
            foreach ($key in $Global:floorshows.Keys) {
                try {
                    if ($Global:floorshows[$key].Visible) {
                        $visiblePanels += $key
                    }
                } catch { }
            }
        }
        
        $panelScore = 0
        if ($visiblePanels.Count -eq 0) {
            $panelScore = 10
        } elseif ($visiblePanels.Count -eq 1) {
            $panelScore = 8
        } else {
            $panelScore = 0
            $vitals.Problems += "Multiple panels visible ($($visiblePanels.Count))"
        }
        
        $vitals.Checks.VisiblePanels = @{
            Value = $visiblePanels.Count
            Panels = $visiblePanels
            Score = $panelScore
            MaxScore = 10
        }
        
        # CHECK 5: Popup Forms
        $openForms = @()
        $allVars = Get-Variable -Scope Global -ErrorAction SilentlyContinue
        foreach ($var in $allVars) {
            if ($var.Name -like '*Form' -and $var.Name -ne 'form' -and $var.Name -ne 'mainForm') {
                if ($var.Value -is [System.Windows.Forms.Form]) {
                    if ($var.Value.Visible) {
                        $openForms += $var.Name
                    }
                }
            }
        }
        
        $formScore = if ($openForms.Count -eq 0) { 10 } else { 5 }
        
        $vitals.Checks.PopupForms = @{
            Value = $openForms.Count
            Forms = $openForms
            Score = $formScore
            MaxScore = 10
        }
        
        # CHECK 6: System Responsiveness
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        [System.Windows.Forms.Application]::DoEvents()
        $stopwatch.Stop()
        $responseMs = $stopwatch.ElapsedMilliseconds
        
        $responseScore = 0
        if ($responseMs -lt 10) {
            $responseScore = 5
        } elseif ($responseMs -lt 50) {
            $responseScore = 3
        } else {
            $responseScore = 0
            $vitals.Problems += "System responding slowly ($responseMs ms)"
        }
        
        $vitals.Checks.Responsiveness = @{
            Value = $responseMs
            Score = $responseScore
            MaxScore = 5
        }
        
        # Calculate final score
        $vitals.Score = $memoryScore + $timerScore + $particleScore + $panelScore + $formScore + $responseScore
        
        # Determine status
        if ($vitals.Score -ge 85) {
            $vitals.Status = "GO"
        } elseif ($vitals.Score -ge 70) {
            $vitals.Status = "CAUTION"
        } elseif ($vitals.Score -ge 50) {
            $vitals.Status = "WARNING"
        } else {
            $vitals.Status = "NO-GO"
        }
        
        return $vitals
    }
    
    # Update display with current vitals
    hidden [void] UpdateDisplay() {
        try {
            $vitals = $this.GetSystemVitals()
            $this.State.LastScan = $vitals
            
            # Determine status color and icon
            $statusColor = [System.Drawing.Color]::Gray
            $statusIcon = "UNKN"
            
            switch ($vitals.Status) {
                "GO" {
                    $statusColor = [System.Drawing.Color]::LightGreen
                    $statusIcon = "✅ OK"
                }
                "CAUTION" {
                    $statusColor = [System.Drawing.Color]::Yellow
                    $statusIcon = "⚠️ WARN"
                }
                "WARNING" {
                    $statusColor = [System.Drawing.Color]::Orange
                    $statusIcon = "⚠️ WARN"
                }
                "NO-GO" {
                    $statusColor = [System.Drawing.Color]::Red
                    $statusIcon = "❌ FAIL"
                }
            }
            
            # Update status label
            $this.StatusLabel.ForeColor = $statusColor
            $timeStr = $vitals.Timestamp.ToString('HH:mm:ss')

            $this.StatusLabel.Text = "STATUS: $($vitals.Status)`nScore: $($vitals.Score)/100`nLast Scan: $timeStr`nHealth: $($vitals.Status)"
            
            # Update vitals label
            $v = $vitals.Checks
            $this.VitalsLabel.Text = "Memory:    $($v.Memory.Value) Memory:    $($v.Memory.Value) Memory:    $($v.Memory.Value) Memory:    $($v.Memory.Value) Memory:    $($v.Memory.Value) MB [$($v.Memory.Status)]`nTimers:    $($v.Timers.Value) active [$($v.Timers.Status)]`nParticles: $($v.Particles.Value) [$($v.Particles.Status)]`nPanels:    $($v.VisiblePanels.Value) visible`nPopups:    $($v.PopupForms.Value) open`nResponse:  $($v.Responsiveness.Value) ms"
            
            # Update problems label
            $this.ProblemsLabel.Text = "Timer Accumulation:    $($this.Problems.TimerAccumulation) incidents`nMemory Leaks:          $($this.Problems.MemoryLeaks) incidents`nDouble-Initialization: $($this.Problems.DoubleInitialization) incidents"
            
            # Update recommendations
            if ($vitals.Problems.Count -gt 0) {
                $this.RecsLabel.Text = "- " + ($vitals.Problems -join "`n- ")
            } else {
                $this.RecsLabel.Text = "All systems healthy! No action needed."
            }
            
        } catch {
            Write-Host "  ❌ [ShowE] Update error: $_" -ForegroundColor Red
        }
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-ShowE {
    Write-Host "🛑 [ShowE] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("showE")) {
        $show = $Global:ShowManager.Shows["showE"]
        $show.Stop()
    }
    
    Write-Host "✅ [ShowE] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshowE class loaded (v3)" -ForegroundColor Green
