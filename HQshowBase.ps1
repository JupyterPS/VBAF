# ============================================
# HQshowBase.ps1 - Presentation Layer Foundation
# ============================================
Write-Host "`n=> _____ HQshowBase (Game Machine Core) _____ <=`n" -ForegroundColor Cyan

# ============================================
# BaseShow - Abstract base class for all shows
# ============================================
class BaseShow {
    # ========================================
    # Properties (Encapsulation)
    # ========================================
    [string] $Name
    [System.Windows.Forms.Panel] $Panel
    [bool] $IsRunning = $false
    [Company] $Company = $null  # Reference to domain model
    
    # Protected (hidden) properties
    hidden [System.Windows.Forms.Timer] $AnimationTimer
    hidden [hashtable] $State = @{}
    
    # ========================================
    # Constructor
    # ========================================
    BaseShow([string]$name, [System.Windows.Forms.Panel]$panel) {
        $this.Name = $name
        $this.Panel = $panel
        Write-Host "  📦 Created show: $name" -ForegroundColor DarkCyan
    }
    
    # ========================================
    # Public API (Abstraction)
    # ========================================
    
    # Start the show (called by ShowManager)
    [void] Start() {
        if ($this.IsRunning) {
            Write-Host "  ⚠️ [$($this.Name)] Already running" -ForegroundColor Yellow
            return
        }
        
        Write-Host "  ▶️ [$($this.Name)] Starting..." -ForegroundColor Green
        $this.IsRunning = $true
        $this.Panel.Visible = $true
        $this.Panel.BringToFront()
        
        try {
            $this.OnStart()  # Polymorphism: child's implementation
        } catch {
            Write-Host "  ❌ [$($this.Name)] Start error: $_" -ForegroundColor Red
            $this.Stop()
        }
    }
    
    # Stop the show (called by ShowManager)
    [void] Stop() {
        if (-not $this.IsRunning) {
            return
        }
        
        Write-Host "  ⏹️ [$($this.Name)] Stopping..." -ForegroundColor Yellow
        
        try {
            $this.OnStop()  # Polymorphism: child's cleanup
        } catch {
            Write-Host "  ⚠️ [$($this.Name)] Stop error: $_" -ForegroundColor Red
        }
        
        $this.Panel.Visible = $false
        $this.IsRunning = $false
    }
    
    # Update loop (called by MasterTimer)
    [void] Update() {
        if (-not $this.IsRunning) {
            return
        }
        
        try {
            $this.OnUpdate()  # Polymorphism: child's animation
        } catch {
            Write-Host "  ⚠️ [$($this.Name)] Update error: $_" -ForegroundColor Red
        }
    }
    
    # Link show to company (dependency injection)
    [void] SetCompany([Company]$company) {
        $this.Company = $company
        Write-Host "  🔗 [$($this.Name)] Linked to: $($company.Name)" -ForegroundColor DarkCyan
    }
    
    # ========================================
    # Virtual Methods (Override in children)
    # ========================================
    
    # Called when show starts (override this)
    [void] OnStart() {
        Write-Host "  ⚠️ [$($this.Name)] OnStart() not implemented" -ForegroundColor DarkYellow
    }
    
    # Called when show stops (override this)
    [void] OnStop() {
        # Default: stop animation timer if exists
        if ($this.AnimationTimer) {
            $this.AnimationTimer.Stop()
            $this.AnimationTimer.Dispose()
            $this.AnimationTimer = $null
        }
    }
    
    # Called every frame (override this)
    [void] OnUpdate() {
        # Override in child for animation
    }
    
    # ========================================
    # Protected Helper Methods
    # ========================================
    
    # Create animation timer (helper for children)
    hidden [void] CreateAnimationTimer([int]$interval, [scriptblock]$tickHandler) {
        $this.AnimationTimer = New-Object System.Windows.Forms.Timer
        $this.AnimationTimer.Interval = $interval
        $this.AnimationTimer.Add_Tick($tickHandler)
    }
    
    # Access company data safely
    hidden [hashtable] GetCompanyMetrics() {
        if (-not $this.Company) {
            Write-Host "  ⚠️ [$($this.Name)] No company linked!" -ForegroundColor Yellow
            return @{}
        }
        
        return @{
            Name = $this.Company.Name
            Location = $this.Company.Location
            EmployeeCount = $this.Company.Employees.Count
            CustomerCount = $this.Company.Customers.Count
        }
    }
}

# ============================================
# ShowManager - State Machine
# ============================================
class ShowManager {
    # ========================================
    # Properties
    # ========================================
    [hashtable] $Shows = @{}
    [string] $ActiveShow = $null
    [hashtable] $Companies = @{}  # Reference to domain models
    
    # ========================================
    # Company Management
    # ========================================
    
    # Register a company (domain model)
    [void] RegisterCompany([Company]$company) {
        $this.Companies[$company.Name] = $company
        Write-Host "🏢 Registered company: $($company.Name)" -ForegroundColor Green
    }
    
    # Get company by name
    [Company] GetCompany([string]$name) {
        return $this.Companies[$name]
    }
    
    # ========================================
    # Show Management
    # ========================================
    
    # Register a show
    [void] RegisterShow([BaseShow]$show) {
        $this.Shows[$show.Name] = $show
        Write-Host "📺 Registered show: $($show.Name)" -ForegroundColor Cyan
    }
    
    # Load and activate a show (State Machine transition)
    [void] LoadShow([string]$showName) {
        if (-not $this.Shows.ContainsKey($showName)) {
            Write-Host "❌ Show not found: $showName" -ForegroundColor Red
            return
        }
        
        # Stop current show (if any)
        if ($this.ActiveShow -and $this.Shows.ContainsKey($this.ActiveShow)) {
            $currentShow = $this.Shows[$this.ActiveShow]
            $currentShow.Stop()
        }
        
        # Start new show
        $newShow = $this.Shows[$showName]
        $newShow.Start()
        $this.ActiveShow = $showName
        
        Write-Host "🎬 Active show: $showName" -ForegroundColor Magenta
    }
    
    # Update active show (called by MasterTimer)
    [void] UpdateActive() {
        if ($this.ActiveShow -and $this.Shows.ContainsKey($this.ActiveShow)) {
            $show = $this.Shows[$this.ActiveShow]
            if ($show.IsRunning) {
                $show.Update()
            }
        }
    }
    
    # Stop all shows (cleanup utility)
    [void] StopAll() {
        Write-Host "🛑 Stopping all shows..." -ForegroundColor Yellow
        
        foreach ($showName in $this.Shows.Keys) {
            $show = $this.Shows[$showName]
            if ($show.IsRunning) {
                $show.Stop()
            }
        }
        
        $this.ActiveShow = $null
        Write-Host "✅ All shows stopped" -ForegroundColor Green
    }
    
    # Get status report
    [hashtable] GetStatus() {
        return @{
            TotalShows = $this.Shows.Count
            ActiveShow = $this.ActiveShow
            RegisteredCompanies = $this.Companies.Count
        }
    }
}

# ============================================
# GameLoop - Master Timer (Simplified)
# ============================================
function Start-GameLoop {
    param([ShowManager]$Manager)
    
    $Global:MasterTimer = New-Object System.Windows.Forms.Timer
    $Global:MasterTimer.Interval = 50  # 20 FPS
    
    # CRITICAL: Store manager reference globally for timer access
    $Global:GameLoopManager = $Manager
    
    $Global:MasterTimer.Add_Tick({
        if ($Global:GameLoopManager) {
            $Global:GameLoopManager.UpdateActive()
        }
    })
    
    $Global:MasterTimer.Start()
    Write-Host "⏱️ Game loop started (20 FPS)" -ForegroundColor Green
    
    # Debug: Verify timer is actually running
    Write-Host "  🔍 Timer Enabled: $($Global:MasterTimer.Enabled)" -ForegroundColor DarkGray
}

function Stop-GameLoop {
    if ($Global:MasterTimer) {
        $Global:MasterTimer.Stop()
        $Global:MasterTimer.Dispose()
        Write-Host "⏱️ Game loop stopped" -ForegroundColor Yellow
    }
}

Write-Host "✅ HQshowBase loaded: BaseShow, ShowManager, GameLoop" -ForegroundColor Green
