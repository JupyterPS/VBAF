# ====================================================
# HQshowF.ps1 — Emergency Control Panel v3
# Converted to Game Machine Architecture
# ====================================================

Write-Host "`n=> _____ HQshowF (Emergency Panel v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# ShowF - Inherits from BaseShow
# ============================================
class ShowF : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [hashtable] $State
    hidden [System.Collections.ArrayList] $ActionsLog
    hidden [System.Windows.Forms.Label] $TimerStatus
    hidden [System.Windows.Forms.Label] $MemoryStatus
    hidden [System.Windows.Forms.Label] $PanelStatus
    hidden [System.Windows.Forms.Label] $ActionLog
    hidden [System.Windows.Forms.TrackBar] $TimerSlider
    hidden [System.Windows.Forms.TrackBar] $MemorySlider
    hidden [int] $UpdateCounter
    
    # ========================================
    # Constructor
    # ========================================
    ShowF([System.Windows.Forms.Panel]$panel) : base("showF", $panel) {
        # Initialize state
        $this.State = @{
            AutoCleanup = $false
            MonitoringActive = $true
            LastAction = "None"
        }
        
        $this.ActionsLog = [System.Collections.ArrayList]::new()
        $this.UpdateCounter = 0
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  ☢️ [ShowF] Initializing Emergency Control Panel..." -ForegroundColor Cyan
        
        # Clear panel
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 25)
        
        # Create UI
        $this.CreateHeader()
        $this.CreateContentArea()
        
        Write-Host "  ✅ [ShowF] Emergency Control Panel ready" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM (~50ms)
    [void] OnUpdate() {
        $this.UpdateCounter++
        
        # Update monitoring every 20 ticks (1 second)
        if ($this.UpdateCounter -ge 20) {
            $this.UpdateCounter = 0
            $this.UpdateMonitoring()
        }
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [ShowF] Cleaning up..." -ForegroundColor Yellow
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset counter
        $this.UpdateCounter = 0
        
        Write-Host "  ✅ [ShowF] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Create header
    hidden [void] CreateHeader() {
        $headerPanel = New-Object System.Windows.Forms.Panel
        $headerPanel.Dock = "Top"
        $headerPanel.Height = 70
        $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(40, 20, 20)
        
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = "COMMERCE BANK - Emergency Control Panel"
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $titleLabel.ForeColor = [System.Drawing.Color]::White
        $titleLabel.Location = New-Object System.Drawing.Point(20, 10)
        $titleLabel.AutoSize = $true
        $headerPanel.Controls.Add($titleLabel)
        
        $subtitleLabel = New-Object System.Windows.Forms.Label
        $subtitleLabel.Text = "Real-time system intervention • Use with caution"
        $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
        $subtitleLabel.ForeColor = [System.Drawing.Color]::Orange
        $subtitleLabel.Location = New-Object System.Drawing.Point(20, 40)
        $subtitleLabel.AutoSize = $true
        $headerPanel.Controls.Add($subtitleLabel)
        
        $this.Panel.Controls.Add($headerPanel)
    }
    
    # Create content area with all controls
    hidden [void] CreateContentArea() {
        $contentPanel = New-Object System.Windows.Forms.Panel
        $contentPanel.Dock = "Fill"
        $contentPanel.AutoScroll = $true
        $this.Panel.Controls.Add($contentPanel)
        
        # Create 4 control boxes
        $this.CreateTimerControl($contentPanel)
        $this.CreateMemoryControl($contentPanel)
        $this.CreatePanelControl($contentPanel)
        $this.CreateNuclearControl($contentPanel)
        $this.CreateActionLog($contentPanel)
    }
    
    # Create timer control
    hidden [void] CreateTimerControl([System.Windows.Forms.Panel]$parent) {
        $timerBox = New-Object System.Windows.Forms.GroupBox
        $timerBox.Text = "⏱️ Timer Limiter"
        $timerBox.Location = New-Object System.Drawing.Point(20, 20)
        $timerBox.Size = New-Object System.Drawing.Size(280, 160)
        $timerBox.ForeColor = [System.Drawing.Color]::White
        $timerBox.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        
        $timerLabel = New-Object System.Windows.Forms.Label
        $timerLabel.Name = "TimerValueLabel"
        $timerLabel.Text = "Max Timers Allowed: 2"
        $timerLabel.Location = New-Object System.Drawing.Point(15, 30)
        $timerLabel.Size = New-Object System.Drawing.Size(250, 20)
        $timerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $timerLabel.ForeColor = [System.Drawing.Color]::LightGray
        $timerBox.Controls.Add($timerLabel)
        
        $this.TimerSlider = New-Object System.Windows.Forms.TrackBar
        $this.TimerSlider.Location = New-Object System.Drawing.Point(15, 55)
        $this.TimerSlider.Size = New-Object System.Drawing.Size(250, 45)
        $this.TimerSlider.Minimum = 0
        $this.TimerSlider.Maximum = 10
        $this.TimerSlider.Value = 2
        $this.TimerSlider.TickFrequency = 1
        $timerBox.Controls.Add($this.TimerSlider)
        
        $this.TimerStatus = New-Object System.Windows.Forms.Label        
        $this.TimerStatus.Location = New-Object System.Drawing.Point(15, 112)  # was 105
        $this.TimerStatus.Size = New-Object System.Drawing.Size(250, 20)
        $this.TimerStatus.Font = New-Object System.Drawing.Font("Consolas", 8)
        $this.TimerStatus.ForeColor = [System.Drawing.Color]::Cyan
        $this.TimerStatus.Text = "Status: Monitoring..."
        $timerBox.Controls.Add($this.TimerStatus)
        
        $timerButton = New-Object System.Windows.Forms.Button
        $timerButton.Text = "KILL EXCESS TIMERS NOW"        
        $timerButton.Location = New-Object System.Drawing.Point(15, 135)  # was 125
        $timerButton.Size = New-Object System.Drawing.Size(250, 25)
        $timerButton.BackColor = [System.Drawing.Color]::DarkRed
        $timerButton.ForeColor = [System.Drawing.Color]::White
        $timerButton.FlatStyle = "Flat"
        $timerBox.Controls.Add($timerButton)
        
        # Attach event handlers
        $self = $this
        
        $this.TimerSlider.Add_ValueChanged({
            $label = $this.Parent.Controls | Where-Object { $_.Name -eq "TimerValueLabel" }
            if ($label) {
                $label.Text = "Max Timers Allowed: $($this.Value)"
            }
            Write-Host "Timer slider moved to $($this.Value)"
        }.GetNewClosure())
           
        $timerButton.Add_Click({
            param($sender, $args)
            $result = $self.InvokeEmergencyTimerKill($self.TimerSlider.Value)
            $self.TimerStatus.Text = "Killed: $($result.Killed) | Remaining: $($result.Remaining)"
            $self.TimerStatus.ForeColor = [System.Drawing.Color]::Red
            $self.LogAction("Killed $($result.Killed) timers")
        }.GetNewClosure())
        
        $parent.Controls.Add($timerBox)
    }
    
    # Create memory control
    hidden [void] CreateMemoryControl([System.Windows.Forms.Panel]$parent) {
        $memoryBox = New-Object System.Windows.Forms.GroupBox
        $memoryBox.Text = "💾 Memory Flusher"
        $memoryBox.Location = New-Object System.Drawing.Point(320, 20)
        $memoryBox.Size = New-Object System.Drawing.Size(280, 160)        
        $memoryBox.ForeColor = [System.Drawing.Color]::White
        $memoryBox.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        
        $memoryLabel = New-Object System.Windows.Forms.Label
        $memoryLabel.Name = "MemoryValueLabel"
        $memoryLabel.Text = "Target Memory: 100 MB"
        $memoryLabel.Location = New-Object System.Drawing.Point(15, 30)
        $memoryLabel.Size = New-Object System.Drawing.Size(250, 20)
        $memoryLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $memoryLabel.ForeColor = [System.Drawing.Color]::LightGray
        $memoryBox.Controls.Add($memoryLabel)
       
        $this.MemorySlider = New-Object System.Windows.Forms.TrackBar
        $this.MemorySlider.Location = New-Object System.Drawing.Point(15, 55)
        $this.MemorySlider.Size = New-Object System.Drawing.Size(250, 45)
        $this.MemorySlider.Minimum = 50
        $this.MemorySlider.Maximum = 200
        $this.MemorySlider.Value = 100
        $this.MemorySlider.TickFrequency = 25
        $memoryBox.Controls.Add($this.MemorySlider)
        
        $this.MemoryStatus = New-Object System.Windows.Forms.Label       
        $this.MemoryStatus.Location = New-Object System.Drawing.Point(15, 112) # was 105
        $this.MemoryStatus.Size = New-Object System.Drawing.Size(250, 20)             
        $this.MemoryStatus.Font = New-Object System.Drawing.Font("Consolas", 8)
        $this.MemoryStatus.ForeColor = [System.Drawing.Color]::Cyan
        $this.MemoryStatus.Text = "Current: Calculating..."
        $memoryBox.Controls.Add($this.MemoryStatus)
        
        $memoryButton = New-Object System.Windows.Forms.Button
        $memoryButton.Text = "FLUSH MEMORY NOW"        
        $memoryButton.Location = New-Object System.Drawing.Point(15, 135) # was 125
        $memoryButton.Size = New-Object System.Drawing.Size(250, 25)
        $memoryButton.BackColor = [System.Drawing.Color]::DarkOrange
        $memoryButton.ForeColor = [System.Drawing.Color]::White
        $memoryButton.FlatStyle = "Flat"
        $memoryBox.Controls.Add($memoryButton)
        
        # Attach event handlers
        $self = $this
       
        $this.MemorySlider.Add_ValueChanged({
            $label = $this.Parent.Controls | Where-Object { $_.Name -eq "MemoryValueLabel" }
            if ($label) {
                $label.Text = "Target Memory: $($this.Value) MB"
            }
            Write-Host "Memory slider moved to $($this.Value)"
        }.GetNewClosure())
     
        $memoryButton.Add_Click({
            param($sender, $args)
            $result = $self.InvokeEmergencyMemoryFlush($self.MemorySlider.Value)
            $self.MemoryStatus.Text = "Freed: $($result.FreedMB)MB | Now: $($result.AfterMB)MB"
            $self.MemoryStatus.ForeColor = [System.Drawing.Color]::Green
            $self.LogAction("Flushed memory: $($result.FreedMB)MB freed")
        }.GetNewClosure())
        
        $parent.Controls.Add($memoryBox)
    }
    
    # Create panel control
    hidden [void] CreatePanelControl([System.Windows.Forms.Panel]$parent) {
        $panelBox = New-Object System.Windows.Forms.GroupBox
        $panelBox.Text = "🔄 Panel Reset"
        $panelBox.Location = New-Object System.Drawing.Point(20, 190)
        $panelBox.Size = New-Object System.Drawing.Size(280, 100)
        $panelBox.ForeColor = [System.Drawing.Color]::White
        $panelBox.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        
        $panelLabel = New-Object System.Windows.Forms.Label
        $panelLabel.Text = "Clear all panels and reset UI"
        $panelLabel.Location = New-Object System.Drawing.Point(15, 25)
        $panelLabel.Size = New-Object System.Drawing.Size(250, 20)
        $panelLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $panelLabel.ForeColor = [System.Drawing.Color]::LightGray
        $panelBox.Controls.Add($panelLabel)
        
        $this.PanelStatus = New-Object System.Windows.Forms.Label
        $this.PanelStatus.Location = New-Object System.Drawing.Point(15, 45)
        $this.PanelStatus.Size = New-Object System.Drawing.Size(250, 20)
        $this.PanelStatus.Font = New-Object System.Drawing.Font("Consolas", 8)
        $this.PanelStatus.ForeColor = [System.Drawing.Color]::Cyan
        $this.PanelStatus.Text = "Status: Ready"
        $panelBox.Controls.Add($this.PanelStatus)
        
        $panelButton = New-Object System.Windows.Forms.Button
        $panelButton.Text = "RESET ALL PANELS"
        $panelButton.Location = New-Object System.Drawing.Point(15, 65)
        $panelButton.Size = New-Object System.Drawing.Size(250, 25)
        $panelButton.BackColor = [System.Drawing.Color]::DarkCyan
        $panelButton.ForeColor = [System.Drawing.Color]::White
        $panelButton.FlatStyle = "Flat"
        $panelBox.Controls.Add($panelButton)
        
        # Attach event handler
        $self = $this
        
        $panelButton.Add_Click({
            param($sender, $args)
            $result = $self.InvokeEmergencyPanelReset()
            $self.PanelStatus.Text = "Reset: $($result.ResetCount) panels cleared"
            $self.PanelStatus.ForeColor = [System.Drawing.Color]::Cyan
            $self.LogAction("Reset $($result.ResetCount) panels")
        }.GetNewClosure())
        
        $parent.Controls.Add($panelBox)
    }
    
    # Create nuclear control
    hidden [void] CreateNuclearControl([System.Windows.Forms.Panel]$parent) {
        $nuclearBox = New-Object System.Windows.Forms.GroupBox
        $nuclearBox.Text = "☢️ NUCLEAR OPTION"
        $nuclearBox.Location = New-Object System.Drawing.Point(320, 190)
        $nuclearBox.Size = New-Object System.Drawing.Size(280, 100)
        $nuclearBox.ForeColor = [System.Drawing.Color]::Red
        $nuclearBox.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        
        $nuclearLabel = New-Object System.Windows.Forms.Label
        $nuclearLabel.Text = "⚠️ Complete system reset"
        $nuclearLabel.Location = New-Object System.Drawing.Point(15, 25)
        $nuclearLabel.Size = New-Object System.Drawing.Size(250, 20)
        $nuclearLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $nuclearLabel.ForeColor = [System.Drawing.Color]::Yellow
        $nuclearBox.Controls.Add($nuclearLabel)
        
        $nuclearWarning = New-Object System.Windows.Forms.Label
        $nuclearWarning.Text = "Stops ALL timers, clears ALL data"
        $nuclearWarning.Location = New-Object System.Drawing.Point(15, 45)
        $nuclearWarning.Size = New-Object System.Drawing.Size(250, 20)
        $nuclearWarning.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
        $nuclearWarning.ForeColor = [System.Drawing.Color]::Orange
        $nuclearBox.Controls.Add($nuclearWarning)
        
        $nuclearButton = New-Object System.Windows.Forms.Button
        $nuclearButton.Text = "☢️ NUCLEAR RESET ☢️"
        $nuclearButton.Location = New-Object System.Drawing.Point(15, 65)
        $nuclearButton.Size = New-Object System.Drawing.Size(250, 25)
        $nuclearButton.BackColor = [System.Drawing.Color]::DarkRed
        $nuclearButton.ForeColor = [System.Drawing.Color]::Yellow
        $nuclearButton.FlatStyle = "Flat"
        $nuclearButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $nuclearBox.Controls.Add($nuclearButton)
        
        # Attach event handler
        $self = $this
        
        $nuclearButton.Add_Click({
            param($sender, $args)
            $confirm = [System.Windows.Forms.MessageBox]::Show(
                "This will STOP ALL TIMERS, CLEAR ALL DATA, and RESET ALL PANELS.`n`nAre you sure?",
                "Nuclear Reset Confirmation",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            
            if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
                Write-Host "`n☢️☢️☢️ NUCLEAR RESET INITIATED ☢️☢️☢️" -ForegroundColor Red
                
                $timerResult = $self.InvokeEmergencyTimerKill(0)
                $memoryResult = $self.InvokeEmergencyMemoryFlush(50)
                $panelResult = $self.InvokeEmergencyPanelReset()
                
                $self.LogAction("☢️ NUCLEAR RESET: $($timerResult.Killed) timers, $($memoryResult.FreedMB)MB, $($panelResult.ResetCount) panels")
                
                [System.Windows.Forms.MessageBox]::Show(
                    "Nuclear Reset Complete!`n`nTimers: $($timerResult.Killed) killed`nMemory: $($memoryResult.FreedMB)MB freed`nPanels: $($panelResult.ResetCount) reset",
                    "Reset Complete",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
        }.GetNewClosure())
        
        $parent.Controls.Add($nuclearBox)
    }
    
    # Create action log
    hidden [void] CreateActionLog([System.Windows.Forms.Panel]$parent) {
        $logBox = New-Object System.Windows.Forms.GroupBox
        $logBox.Text = "📋 Action Log"
        $logBox.Location = New-Object System.Drawing.Point(20, 300)
        $logBox.Size = New-Object System.Drawing.Size(580, 80)
        $logBox.ForeColor = [System.Drawing.Color]::White
        $logBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        
        $this.ActionLog = New-Object System.Windows.Forms.Label
        $this.ActionLog.Location = New-Object System.Drawing.Point(15, 25)
        $this.ActionLog.Size = New-Object System.Drawing.Size(550, 50)
        $this.ActionLog.Font = New-Object System.Drawing.Font("Consolas", 8)
        $this.ActionLog.ForeColor = [System.Drawing.Color]::LightGray
        $this.ActionLog.Text = "No actions yet..."
        $logBox.Controls.Add($this.ActionLog)
        
        $parent.Controls.Add($logBox)
    }
    
    # Emergency action methods
    hidden [hashtable] InvokeEmergencyTimerKill([int]$maxTimers) {
        $killed = 0
        $report = @()
        
        Write-Host "`n🚨 [ShowF] EMERGENCY TIMER KILL - Max allowed: $maxTimers" -ForegroundColor Red
        
        $allTimers = @()
        Get-Variable -Scope Global -ErrorAction SilentlyContinue | Where-Object { 
            $_.Name -match 'Timer$' -and 
            $_.Value -is [System.Windows.Forms.Timer]
        } | ForEach-Object {
            if ($_.Value.Enabled) {
                $allTimers += @{
                    Name = $_.Name
                    Timer = $_.Value
                }
            }
        }
        
        if ($allTimers.Count -gt $maxTimers) {
            $toKill = $allTimers.Count - $maxTimers
            
            for ($i = 0; $i -lt $toKill; $i++) {
                try {
                    $timerInfo = $allTimers[$i]
                    $timerInfo.Timer.Stop()
                    $timerInfo.Timer.Dispose()
                    $killed++
                    $report += $timerInfo.Name
                    Write-Host "  💀 Killed: $($timerInfo.Name)" -ForegroundColor Red
                } catch { }
            }
        }
        
        return @{
            Killed = $killed
            Report = $report
            Remaining = $allTimers.Count - $killed
        }
    }
    
    hidden [hashtable] InvokeEmergencyMemoryFlush([int]$targetMB) {
        Write-Host "`n🧹 [ShowF] EMERGENCY MEMORY FLUSH - Target: ${targetMB}MB" -ForegroundColor Yellow
        
        $beforeMB = [Math]::Round([System.GC]::GetTotalMemory($false) / 1MB, 2)
        $clearedShows = @()
        
        for ($i = 1; $i -le 60; $i++) {
            $dataVarName = "show${i}Data"
            
            if (Get-Variable -Name $dataVarName -Scope Global -ErrorAction SilentlyContinue) {
                try {
                    $data = Get-Variable -Name $dataVarName -Scope Global -ValueOnly
                    
                    if ($data) {
                        $cleared = $false
                        $propertiesToClear = @('Rockets', 'Particles', 'FinalLetters', 'KPIorbs', 'Sparks', 'Trees', 'Trail')
                        
                        foreach ($prop in $propertiesToClear) {
                            if ($data.PSObject.Properties.Name -contains $prop) {
                                if ($data.$prop.Count -gt 0) {
                                    $data.$prop = @()
                                    $cleared = $true
                                }
                            }
                        }
                        
                        if ($cleared) {
                            $clearedShows += "show$i"
                        }
                    }
                } catch { }
            }
        }
        
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
        
        $afterMB = [Math]::Round([System.GC]::GetTotalMemory($false) / 1MB, 2)
        $freedMB = [Math]::Round($beforeMB - $afterMB, 2)
        
        Write-Host "  ♻️ Memory: ${beforeMB}MB → ${afterMB}MB (freed: ${freedMB}MB)" -ForegroundColor Green
        
        return @{
            BeforeMB = $beforeMB
            AfterMB = $afterMB
            FreedMB = $freedMB
            ClearedShows = $clearedShows
        }
    }
    
    hidden [hashtable] InvokeEmergencyPanelReset() {
        Write-Host "`n🔄 [ShowF] EMERGENCY PANEL RESET" -ForegroundColor Cyan
        
        $resetCount = 0
        
        if ($Global:floorshows) {
            foreach ($key in $Global:floorshows.Keys) {
                if ($key -ne "showF" -and $key -ne "showE") {
                    try {
                        $panel = $Global:floorshows[$key]
                        if ($panel.Visible -or $panel.Controls.Count -gt 0) {
                            $panel.Visible = $false
                            $panel.Controls.Clear()
                            $resetCount++
                        }
                    } catch { }
                }
            }
        }
        
        return @{
            ResetCount = $resetCount
        }
    }
    
    # Log action
    hidden [void] LogAction([string]$message) {
        $logEntry = "$(Get-Date -Format 'HH:mm:ss') - $message"
        [void]$this.ActionsLog.Add($logEntry)
        $this.ActionLog.Text = ($this.ActionsLog | Select-Object -Last 8) -join "`r`n"
    }
    
    # Update monitoring displays
    hidden [void] UpdateMonitoring() {
        # Update current memory
        $currentMB = [Math]::Round([System.GC]::GetTotalMemory($false) / 1MB, 2)
        $this.MemoryStatus.Text = "Current: ${currentMB}MB"
        
        if ($currentMB -gt 150) {
            $this.MemoryStatus.ForeColor = [System.Drawing.Color]::Yellow
        } elseif ($currentMB -gt 100) {
            $this.MemoryStatus.ForeColor = [System.Drawing.Color]::Yellow
        } else {
            $this.MemoryStatus.ForeColor = [System.Drawing.Color]::Yellow
        }
        
        # Update timer count
        $timerCount = 0
        Get-Variable -Scope Global -ErrorAction SilentlyContinue | Where-Object { 
            $_.Name -match 'Timer$' -and 
            $_.Value -is [System.Windows.Forms.Timer]
        } | ForEach-Object {
            if ($_.Value.Enabled) {
                $timerCount++
            }
        }
        
        $this.TimerStatus.Text = "Active: $timerCount timers"
        
        if ($timerCount -gt 4) {
            $this.TimerStatus.ForeColor = [System.Drawing.Color]::Red
        } elseif ($timerCount -gt 2) {
            $this.TimerStatus.ForeColor = [System.Drawing.Color]::Yellow
        } else {
            $this.TimerStatus.ForeColor = [System.Drawing.Color]::Green
        }
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-ShowF {
    Write-Host "🛑 [ShowF] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("showF")) {
        $show = $Global:ShowManager.Shows["showF"]
        $show.Stop()
    }
    
    Write-Host "✅ [ShowF] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshowF class loaded (v3)" -ForegroundColor Green
