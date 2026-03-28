# ====================================================
# HQshowD.ps1 — Comprehensive Cleanup Tool v3
# Converted to Game Machine Architecture
# ====================================================

Write-Host "`n=> _____ HQshowD (Cleanup Tool v3) ___________ <=`n" -ForegroundColor Cyan

# ============================================
# ShowD - Inherits from BaseShow
# ============================================
class ShowD : BaseShow {
    # ========================================
    # Private Properties (Encapsulation)
    # ========================================
    hidden [System.Windows.Forms.Label] $StatusLabel
    hidden [hashtable] $CleanupStats
    hidden [array] $ShowsToClean
    
    # ========================================
    # Constructor
    # ========================================
    ShowD([System.Windows.Forms.Panel]$panel) : base("showD", $panel) {
        # Initialize cleanup stats
        $this.CleanupStats = @{
            TimersStopped = 0
            ShowsHidden = 0
            PanelsCleared = 0
            DataCleared = 0
            FormsClosed = 0
        }
        
        # Define shows to clean (from your list)
        $this.ShowsToClean = @(
            1,2,3,4,5,6,7,8,9,10,15,16,17,18,19,21,23,26,27,28,29,30,
            31,32,33,36,37,38,39,40,50,51,52,53,54,55,56,57,58,59,60
        )
    }
    
    # ========================================
    # Lifecycle Methods (Polymorphism)
    # ========================================
    
    # OnStart - Called when show activates
    [void] OnStart() {
        Write-Host "  🧹 [ShowD] Initializing Cleanup Tool..." -ForegroundColor Cyan
        
        # Setup UI
        $this.Panel.SuspendLayout()
        $this.Panel.Controls.Clear()
        $this.Panel.BackColor = [System.Drawing.Color]::FromArgb(20, 30, 40)
        
        # Create status label
        $this.StatusLabel = New-Object System.Windows.Forms.Label
        $this.StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $this.StatusLabel.ForeColor = [System.Drawing.Color]::Yellow
        $this.StatusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $this.StatusLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
        $this.StatusLabel.Text = "🧼 Deep cleaning in progress...`nPlease wait..."
        
        $this.Panel.Controls.Add($this.StatusLabel)
        $this.Panel.ResumeLayout()
        $this.Panel.Refresh()
        
        # Execute cleanup
        $this.ExecuteCleanup()
        
        Write-Host "  ✅ [ShowD] Cleanup Tool ready" -ForegroundColor Green
    }
    
    # OnUpdate - Called every frame by GM
    [void] OnUpdate() {
        # ShowD is static once cleanup is done
        # No animation needed
    }
    
    # OnStop - Called when show deactivates
    [void] OnStop() {
        Write-Host "  🛑 [ShowD] Cleaning up..." -ForegroundColor Yellow
        
        # Clear panel
        $this.Panel.Controls.Clear()
        
        # Reset stats
        $this.CleanupStats.TimersStopped = 0
        $this.CleanupStats.ShowsHidden = 0
        $this.CleanupStats.PanelsCleared = 0
        $this.CleanupStats.DataCleared = 0
        $this.CleanupStats.FormsClosed = 0
        
        Write-Host "  ✅ [ShowD] Cleanup complete" -ForegroundColor Green
    }
    
    # ========================================
    # Private Helper Methods
    # ========================================
    
    # Execute full cleanup sequence
    hidden [void] ExecuteCleanup() {
        Write-Host "`n🧹 [ShowD] Starting comprehensive cleanup..." -ForegroundColor Cyan
        
        try {
            # Phase 1: Hide other shows
            $this.HideOtherShows()
            $this.UpdateStatus("Phase 1: Hiding shows...`n$($this.CleanupStats.ShowsHidden) hidden")
            
            # Phase 2: Stop V1 timers
            $this.StopV1Timers()
            $this.UpdateStatus("Phase 2: Stopping timers...`n$($this.CleanupStats.TimersStopped) stopped")
            Start-Sleep -Milliseconds 300
            
            # Phase 3: Clear panels
            $this.ClearPanels()
            $this.UpdateStatus("Phase 3: Clearing panels...`n$($this.CleanupStats.PanelsCleared) cleared")
            
            # Phase 4: Clear data
            $this.ClearShowData()
            $this.UpdateStatus("Phase 4: Clearing data...`n$($this.CleanupStats.DataCleared) cleared")
            
            # Phase 5: Close popups
            $this.ClosePopups()
            $this.UpdateStatus("Phase 5: Cleaning memory...`nPlease wait...")
            
            # Phase 6: Garbage collection
            [System.GC]::Collect()
            Start-Sleep -Milliseconds 200
            
            # Phase 7: Show final report
            $this.ShowFinalReport()
            
        } catch {
            Write-Host "`n❌ [ShowD] Cleanup error: $_" -ForegroundColor Red
            $this.StatusLabel.Text = "❌ Cleanup Error!`n$($_.Exception.Message)`n`nCheck console for details"
            $this.StatusLabel.ForeColor = [System.Drawing.Color]::Red
            $this.StatusLabel.Refresh()
        }
    }
    
    # Phase 1: Hide other shows
    hidden [void] HideOtherShows() {
        if (-not $Global:floorshows) { return }
        
        foreach ($key in @($Global:floorshows.Keys)) {
            if ($key -ne "showD") {
                try {
                    $panel = $Global:floorshows[$key]
                    if ($panel.Visible) {
                        $panel.Visible = $false
                        $this.CleanupStats.ShowsHidden++
                    }
                } catch { }
            }
        }
        
        Write-Host "  👁️ Hidden $($this.CleanupStats.ShowsHidden) shows" -ForegroundColor Green
    }
    
    # Phase 2: Stop V1 timers (doesn't affect GM)
    hidden [void] StopV1Timers() {
        $stoppedTimers = @()
        
        # Method 1: Stop known timer patterns
        foreach ($showNum in $this.ShowsToClean) {
            $timerNames = @(
                "show${showNum}Timer",
                "show${showNum}AnimTimer",
                "show${showNum}LetterTimer",
                "show${showNum}TickerTimer",
                "show${showNum}UpdateTimer",
                "show${showNum}RefreshTimer"
            )
            
            foreach ($timerName in $timerNames) {
                if (Get-Variable -Name $timerName -Scope Global -ErrorAction SilentlyContinue) {
                    $timer = Get-Variable -Name $timerName -Scope Global -ValueOnly
                    if ($timer -and $timer -is [System.Windows.Forms.Timer]) {
                        try {
                            if ($timer.Enabled) {
                                $timer.Stop()
                                $stoppedTimers += $timerName
                            }
                        } catch { }
                    }
                }
            }
        }
        
        # Method 2: Scan all global variables for timers
        $allVars = Get-Variable -Scope Global -ErrorAction SilentlyContinue
        foreach ($var in $allVars) {
            # Skip showD's own resources and main dashboard timers
            if ($var.Name -match 'showD|tickerTimer|newsTimer') { continue }
            
            if ($var.Value -is [System.Windows.Forms.Timer]) {
                try {
                    $timer = $var.Value
                    if ($timer.Enabled -and $stoppedTimers -notcontains $var.Name) {
                        $timer.Stop()
                        $stoppedTimers += $var.Name
                    }
                } catch { }
            }
        }
        
        $this.CleanupStats.TimersStopped = $stoppedTimers.Count
        Write-Host "  ⏹️ Stopped $($this.CleanupStats.TimersStopped) timers" -ForegroundColor Green
        
        if ($stoppedTimers.Count -gt 0 -and $stoppedTimers.Count -le 10) {
            Write-Host "    └─ $($stoppedTimers -join ', ')" -ForegroundColor DarkGreen
        }
    }
    
    # Phase 3: Clear panels
    hidden [void] ClearPanels() {
        if (-not $Global:floorshows) { return }
        
        foreach ($showNum in $this.ShowsToClean) {
            $showKey = "show$showNum"
            if ($Global:floorshows.ContainsKey($showKey)) {
                try {
                    $panel = $Global:floorshows[$showKey]
                    if ($panel.Controls.Count -gt 0) {
                        $panel.SuspendLayout()
                        $panel.Controls.Clear()
                        $panel.ResumeLayout()
                        $this.CleanupStats.PanelsCleared++
                    }
                } catch { }
            }
        }
        
        Write-Host "  🗑️ Cleared $($this.CleanupStats.PanelsCleared) panels" -ForegroundColor Green
    }
    
    # Phase 4: Clear show data
    hidden [void] ClearShowData() {
        $propertiesToClear = @(
            'Rockets', 'Particles', 'FinalLetters', 'KPIorbs', 
            'Sparks', 'Nodes', 'Edges', 'Items', 'Points',
            'Charts', 'Graphs', 'Tables', 'Metrics', 'Stats',
            'Trees', 'Trail', 'Animations', 'Queue'
        )
        
        foreach ($showNum in $this.ShowsToClean) {
            $dataVarName = "show${showNum}Data"
            
            if (Get-Variable -Name $dataVarName -Scope Global -ErrorAction SilentlyContinue) {
                try {
                    $data = Get-Variable -Name $dataVarName -Scope Global -ValueOnly
                    
                    if ($data) {
                        $cleared = $false
                        foreach ($prop in $propertiesToClear) {
                            if ($data.PSObject.Properties.Name -contains $prop) {
                                if ($data.$prop -and $data.$prop.Count -gt 0) {
                                    $data.$prop = @()
                                    $cleared = $true
                                }
                            }
                        }
                        
                        if ($cleared) {
                            $this.CleanupStats.DataCleared++
                        }
                    }
                } catch { }
            }
        }
        
        Write-Host "  💾 Cleared $($this.CleanupStats.DataCleared) data stores" -ForegroundColor Green
    }
    
    # Phase 5: Close popup forms
    hidden [void] ClosePopups() {
        # Close company dropdown
        if ($Global:CompanyDropdownForm) {
            try {
                $Global:CompanyDropdownForm.Close()
                $Global:CompanyDropdownForm = $null
                $this.CleanupStats.FormsClosed++
            } catch { }
        }
        
        # Look for other popups (NOT main form!)
        $popupForms = Get-Variable -Scope Global -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match 'Form$' -and 
            $_.Value -is [System.Windows.Forms.Form] -and
            $_.Name -ne 'form' -and
            $_.Name -ne 'mainForm'
        }
        
        foreach ($formVar in $popupForms) {
            try {
                if ($formVar.Value.Visible) {
                    $formVar.Value.Hide()
                    $this.CleanupStats.FormsClosed++
                }
            } catch { }
        }
        
        if ($this.CleanupStats.FormsClosed -gt 0) {
            Write-Host "  🪟 Closed $($this.CleanupStats.FormsClosed) popup forms" -ForegroundColor Green
        }
    }
    
    # Show final report
    hidden [void] ShowFinalReport() {
        $memoryMB = [Math]::Round([System.GC]::GetTotalMemory($false) / 1MB, 2)
        
        $report = @"
        DEEP CLEAN COMPLETE

        Timers Stopped: $($this.CleanupStats.TimersStopped)
        Shows Hidden: $($this.CleanupStats.ShowsHidden)
        Panels Cleared: $($this.CleanupStats.PanelsCleared)
        Data Cleared: $($this.CleanupStats.DataCleared) shows
        Forms Closed: $($this.CleanupStats.FormsClosed)
        Memory: $memoryMB MB
        
        All systems cleaned!
        Ready for fresh start!
        
        Click any company to continue...
"@
        
        $this.StatusLabel.Text = $report
        $this.StatusLabel.ForeColor = [System.Drawing.Color]::LightGreen
        $this.StatusLabel.Refresh()
        
        # Console report
        Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║     ShowD CLEANUP REPORT (v3)         ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host "Stopped timers   : $($this.CleanupStats.TimersStopped)" -ForegroundColor Green
        Write-Host "Hidden shows     : $($this.CleanupStats.ShowsHidden)" -ForegroundColor Green
        Write-Host "Cleared panels   : $($this.CleanupStats.PanelsCleared)" -ForegroundColor Green
        Write-Host "Cleared data     : $($this.CleanupStats.DataCleared)" -ForegroundColor Green
        Write-Host "Closed forms     : $($this.CleanupStats.FormsClosed)" -ForegroundColor Green
        Write-Host "Memory usage     : $memoryMB MB" -ForegroundColor Green
        Write-Host "Status           : ✅ Ready (v3 GM Clean!)`n" -ForegroundColor Green
        
        # Bring main form forward
        if ($Global:form) {
            try {
                $Global:form.Activate()
            } catch { }
        }
    }
    
    # Update status label
    hidden [void] UpdateStatus([string]$message) {
        if ($this.StatusLabel) {
            $this.StatusLabel.Text = $message
            $this.StatusLabel.Refresh()
        }
    }
}

# ============================================
# Legacy V1 Compatibility Function
# ============================================
function Stop-ShowD {
    Write-Host "🛑 [ShowD] Stop called (v3 version)" -ForegroundColor Yellow
    
    if ($Global:ShowManager -and $Global:ShowManager.Shows.ContainsKey("showD")) {
        $show = $Global:ShowManager.Shows["showD"]
        $show.Stop()
    }
    
    Write-Host "✅ [ShowD] Stopped" -ForegroundColor Green
}

Write-Host "✅ HQshowD class loaded (v3)" -ForegroundColor Green
