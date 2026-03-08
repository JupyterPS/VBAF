#Requires -Version 5.1
<#
.SYNOPSIS
    Enterprise Automation Environments for VBAF Phase 9
.DESCRIPTION
    Provides standardized RL environments connected to real Windows systems.
    Inherits from VBAFEnvironment - compatible with DQN, PPO, A3C algorithms.
    Features:
      - JobSchedulerEnvironment  : learns optimal Windows task scheduling
      - ResourceOptimizerEnvironment : optimizes CPU/memory allocation
      - AlertRouterEnvironment   : learns intelligent event log routing
    All environments use real Windows data via Get-Counter and Get-WinEvent.
.NOTES
    Part of VBAF - Phase 9 Enterprise Automation Engine
    PS 5.1 compatible
    Requires VBAF.RL.Environment.ps1 loaded first
#>

# ============================================================
# JOB SCHEDULER ENVIRONMENT - Pillar 4: Adaptive Automation
# State  : [cpuLoad, memLoad, pendingJobs, timeOfDay] normalized 0-1
# Actions: 0=RunNow, 1=Delay, 2=Skip
# ============================================================
class JobSchedulerEnvironment : VBAFEnvironment {
    [double] $CpuLoad
    [double] $MemLoad
    [int]    $PendingJobs
    [double] $TimeOfDay
    [int]    $JobsCompleted
    [int]    $JobsSkipped
    hidden [System.Random] $Rng

    JobSchedulerEnvironment() : base("JobScheduler", 50) {
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, 0.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   3, 0.0, 2.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    JobSchedulerEnvironment([int]$maxSteps) : base("JobScheduler", $maxSteps) {
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, 0.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   3, 0.0, 2.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    [double[]] Reset() {
        try {
            $s = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1).CounterSamples[0].CookedValue
            $this.CpuLoad = [double]$s / 100.0
        } catch { $this.CpuLoad = $this.Rng.NextDouble() }
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $this.MemLoad = [double](($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize)
        } catch { $this.MemLoad = $this.Rng.NextDouble() }
        $this.PendingJobs   = $this.Rng.Next(1, 10)
        $this.TimeOfDay     = [double]([System.DateTime]::Now.Hour) / 23.0
        $this.JobsCompleted = 0
        $this.JobsSkipped   = 0
        $this.Steps         = 0
        $this.TotalReward   = 0.0
        $this.EpisodeCount++
        return $this.GetState()
    }

    [double[]] GetState() {
        [double[]] $arr = @(0.0, 0.0, 0.0, 0.0)
        $arr[0] = $this.CpuLoad
        $arr[1] = $this.MemLoad
        $arr[2] = [double]$this.PendingJobs / 10.0
        $arr[3] = $this.TimeOfDay
        return $arr
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        [double] $reward = 0.0
        switch ($action) {
            0 {
                if ($this.CpuLoad -lt 0.7 -and $this.MemLoad -lt 0.8) {
                    $reward = 2.0
                    $this.JobsCompleted++
                    $this.PendingJobs = [Math]::Max(0, $this.PendingJobs - 1)
                } else { $reward = -2.0 }
            }
            1 {
                if ($this.CpuLoad -gt 0.7 -or $this.MemLoad -gt 0.8) { $reward = 1.0 }
                else { $reward = -0.5 }
            }
            2 {
                $reward = -1.0
                $this.JobsSkipped++
                $this.PendingJobs = [Math]::Max(0, $this.PendingJobs - 1)
            }
        }
        $this.CpuLoad  = [Math]::Max(0.0, [Math]::Min(1.0, $this.CpuLoad + ($this.Rng.NextDouble() - 0.5) * 0.1))
        $this.MemLoad  = [Math]::Max(0.0, [Math]::Min(1.0, $this.MemLoad + ($this.Rng.NextDouble() - 0.5) * 0.05))
        $this.TimeOfDay = [double]([System.DateTime]::Now.Hour) / 23.0
        [bool] $done = ($this.Steps -ge $this.MaxSteps) -or ($this.PendingJobs -le 0)
        $this.TotalReward += $reward
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}

# ============================================================
# RESOURCE OPTIMIZER ENVIRONMENT - Pillar 5: IT Optimization
# State  : [cpuLoad, memLoad, processCount, diskIO] normalized 0-1
# Actions: 0=Throttle, 1=Normal, 2=Boost
# ============================================================
class ResourceOptimizerEnvironment : VBAFEnvironment {
    [double] $CpuLoad
    [double] $MemLoad
    [int]    $ProcessCount
    [double] $DiskIO
    [double] $TargetCpu
    hidden [System.Random] $Rng

    ResourceOptimizerEnvironment() : base("ResourceOptimizer", 50) {
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, 0.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   3, 0.0, 2.0)
        $this.TargetCpu        = 0.6
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    [double[]] Reset() {
        try {
            $s = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1).CounterSamples[0].CookedValue
            $this.CpuLoad = [double]$s / 100.0
        } catch { $this.CpuLoad = $this.Rng.NextDouble() }
        try {
            $os = Get-CimInstance Win32_OperatingSystem
            $this.MemLoad = [double](($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize)
        } catch { $this.MemLoad = $this.Rng.NextDouble() * 0.8 }
        $this.ProcessCount = (Get-Process).Count
        $this.DiskIO       = $this.Rng.NextDouble() * 0.5
        $this.Steps        = 0
        $this.TotalReward  = 0.0
        $this.EpisodeCount++
        return $this.GetState()
    }

    [double[]] GetState() {
        [double[]] $arr = @(0.0, 0.0, 0.0, 0.0)
        $arr[0] = $this.CpuLoad
        $arr[1] = $this.MemLoad
        $arr[2] = [double]$this.ProcessCount / 300.0
        $arr[3] = $this.DiskIO
        return $arr
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        [double] $adj = 0.0
        switch ($action) {
            0 { $adj = -0.1 }
            1 { $adj =  0.0 }
            2 { $adj =  0.1 }
        }
        $this.CpuLoad = [Math]::Max(0.0, [Math]::Min(1.0, $this.CpuLoad + $adj + ($this.Rng.NextDouble() - 0.5) * 0.05))
        [double] $distance = [Math]::Abs($this.CpuLoad - $this.TargetCpu)
        [double] $reward   = 1.0 - ($distance * 2.0)
        if ($this.CpuLoad -gt 0.9) { $reward -= 2.0 }
        if ($this.MemLoad  -gt 0.9) { $reward -= 1.0 }
        $this.MemLoad = [Math]::Max(0.0, [Math]::Min(1.0, $this.MemLoad + ($this.Rng.NextDouble() - 0.5) * 0.03))
        $this.DiskIO  = [Math]::Max(0.0, [Math]::Min(1.0, $this.DiskIO  + ($this.Rng.NextDouble() - 0.5) * 0.05))
        [bool] $done = ($this.Steps -ge $this.MaxSteps)
        $this.TotalReward += $reward
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}

# ============================================================
# ALERT ROUTER ENVIRONMENT - Pillar 6: Enterprise Scripting
# State  : [severity, frequency, timeOfDay, repeatCount] normalized 0-1
# Actions: 0=Ignore, 1=Log, 2=Alert, 3=Escalate
# ============================================================
class AlertRouterEnvironment : VBAFEnvironment {
    [double] $Severity
    [double] $Frequency
    [double] $TimeOfDay
    [int]    $RepeatCount
    [int]    $CorrectRoutes
    [int]    $MissedAlerts
    hidden [System.Random] $Rng

    AlertRouterEnvironment() : base("AlertRouter", 50) {
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, 0.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   4, 0.0, 3.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    [double[]] Reset() {
        try {
            $events = Get-WinEvent -LogName System -MaxEvents 10 -ErrorAction SilentlyContinue
            $crit   = ($events | Where-Object { $_.Level -le 2 }).Count
            $this.Severity  = [double]$crit / 10.0
            $this.Frequency = [double]$events.Count / 10.0
        } catch {
            $this.Severity  = $this.Rng.NextDouble()
            $this.Frequency = $this.Rng.NextDouble()
        }
        $this.TimeOfDay    = [double]([System.DateTime]::Now.Hour) / 23.0
        $this.RepeatCount  = $this.Rng.Next(0, 5)
        $this.CorrectRoutes = 0
        $this.MissedAlerts  = 0
        $this.Steps         = 0
        $this.TotalReward   = 0.0
        $this.EpisodeCount++
        return $this.GetState()
    }

    [double[]] GetState() {
        [double[]] $arr = @(0.0, 0.0, 0.0, 0.0)
        $arr[0] = $this.Severity
        $arr[1] = $this.Frequency
        $arr[2] = $this.TimeOfDay
        $arr[3] = [double]$this.RepeatCount / 5.0
        return $arr
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        [double] $reward = 0.0
        if ($this.Severity -lt 0.2) {
            if ($action -eq 0)     { $reward = 1.0 }
            elseif ($action -eq 1) { $reward = 0.5 }
            else                   { $reward = -0.5 }
        } elseif ($this.Severity -lt 0.6) {
            if ($action -eq 1)     { $reward = 1.0 }
            elseif ($action -eq 2) { $reward = 0.8 }
            else                   { $reward = -0.5 }
        } else {
            if ($action -eq 2)     { $reward = 1.0 }
            elseif ($action -eq 3) { $reward = 1.5 }
            elseif ($action -eq 0) { $reward = -2.0; $this.MissedAlerts++ }
            else                   { $reward = 0.3 }
        }
        if ($reward -gt 0) { $this.CorrectRoutes++ }
        $this.Severity    = [Math]::Max(0.0, [Math]::Min(1.0, $this.Severity  + ($this.Rng.NextDouble() - 0.5) * 0.2))
        $this.Frequency   = [Math]::Max(0.0, [Math]::Min(1.0, $this.Frequency + ($this.Rng.NextDouble() - 0.5) * 0.1))
        $this.RepeatCount = [Math]::Max(0, $this.RepeatCount + $this.Rng.Next(-1, 2))
        $this.TimeOfDay   = [double]([System.DateTime]::Now.Hour) / 23.0
        [bool] $done = ($this.Steps -ge $this.MaxSteps)
        $this.TotalReward += $reward
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}

# ============================================================
# ============================================================
# SUPPLY CHAIN ENVIRONMENT - Pillar 7: Multi-Agent Strategy
# Agent learns optimal inventory ordering strategy
# State  : [inventory, demand, price, backlog] normalized 0-1
# Actions: 0=OrderSmall, 1=OrderMedium, 2=OrderLarge, 3=Hold
# ============================================================
class SupplyChainEnvironment : VBAFEnvironment {
    [double] $Inventory
    [double] $Demand
    [double] $Price
    [double] $Backlog
    [double] $TotalProfit
    [int]    $StockOuts
    hidden [System.Random] $Rng

    SupplyChainEnvironment() : base("SupplyChain", 50) {
        $this.ObservationSpace = [VBAFSpace]::new("continuous", 4, 0.0, 1.0)
        $this.ActionSpace      = [VBAFSpace]::new("discrete",   4, 0.0, 3.0)
        $this.Rng              = [System.Random]::new()
        $this.Reset()
    }

    [double[]] Reset() {
        $this.Inventory    = 0.5
        $this.Demand       = [double]$this.Rng.Next(10, 50) / 100.0
        $this.Price        = [double]$this.Rng.Next(20, 80) / 100.0
        $this.Backlog      = 0.0
        $this.TotalProfit  = 0.0
        $this.StockOuts    = 0
        $this.Steps        = 0
        $this.TotalReward  = 0.0
        $this.EpisodeCount++
        return $this.GetState()
    }

    [double[]] GetState() {
        [double[]] $arr = @(0.0, 0.0, 0.0, 0.0)
        $arr[0] = [Math]::Max(0.0, [Math]::Min(1.0, $this.Inventory))
        $arr[1] = $this.Demand
        $arr[2] = $this.Price
        $arr[3] = [Math]::Min(1.0, $this.Backlog)
        return $arr
    }

    [hashtable] Step([int]$action) {
        $this.Steps++
        [double] $orderQty = 0.0
        [double] $orderCost = 0.0
        switch ($action) {
            0 { $orderQty = 0.1; $orderCost = 0.05 }  # OrderSmall
            1 { $orderQty = 0.3; $orderCost = 0.12 }  # OrderMedium
            2 { $orderQty = 0.5; $orderCost = 0.18 }  # OrderLarge
            3 { $orderQty = 0.0; $orderCost = 0.0  }  # Hold
        }

        # Add ordered stock
        $this.Inventory += $orderQty

        # Fulfill demand
        [double] $reward = 0.0
        if ($this.Inventory -ge $this.Demand) {
            $reward           = $this.Demand * $this.Price * 2.0  # Sales revenue
            $this.Inventory  -= $this.Demand
            $this.Backlog     = [Math]::Max(0.0, $this.Backlog - 0.1)
        } else {
            $reward           = $this.Inventory * $this.Price     # Partial sales
            $this.Backlog    += ($this.Demand - $this.Inventory)  # Unfulfilled
            $this.Inventory   = 0.0
            $this.StockOuts++
        }

        # Subtract order cost and holding cost
        $reward          -= $orderCost
        $reward          -= $this.Inventory * 0.02  # Holding cost
        $reward          -= $this.Backlog   * 0.05  # Backlog penalty

        # Simulate market changes
        $this.Demand  = [Math]::Max(0.05, [Math]::Min(0.9, $this.Demand + ($this.Rng.NextDouble() - 0.5) * 0.1))
        $this.Price   = [Math]::Max(0.1,  [Math]::Min(0.9, $this.Price  + ($this.Rng.NextDouble() - 0.5) * 0.05))

        $this.TotalProfit += $reward
        [bool] $done = ($this.Steps -ge $this.MaxSteps)
        $this.TotalReward += $reward
        return @{ NextState = $this.GetState(); Reward = $reward; Done = $done }
    }
}

# ENTERPRISE ENVIRONMENT FACTORY
# ============================================================
function New-EnterpriseEnvironment {
    param(
        [string] $Name     = "JobScheduler",
        [int]    $MaxSteps = 50
    )
    switch ($Name) {
        "JobScheduler"       { return [JobSchedulerEnvironment]::new($MaxSteps) }
        "ResourceOptimizer"  { return [ResourceOptimizerEnvironment]::new() }
        "AlertRouter"        { return [AlertRouterEnvironment]::new() }
        "SupplyChain"        { return [SupplyChainEnvironment]::new() }
        default {
            Write-Host "❌ Unknown: $Name" -ForegroundColor Red
            Write-Host "   Available: JobScheduler, ResourceOptimizer, AlertRouter" -ForegroundColor Yellow
            return $null
        }
    }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1
# 2. QUICK TEST - Job Scheduler
#    $env = New-EnterpriseEnvironment -Name "JobScheduler"
#    $env.PrintInfo()
#    Invoke-VBAFBenchmark -Environment $env -Episodes 5 -Label "JobScheduler Random"
# 3. QUICK TEST - Resource Optimizer
#    $env = New-EnterpriseEnvironment -Name "ResourceOptimizer"
#    $env.PrintInfo()
#    Invoke-VBAFBenchmark -Environment $env -Episodes 5 -Label "ResourceOptimizer Random"
# 4. QUICK TEST - Alert Router
#    $env = New-EnterpriseEnvironment -Name "AlertRouter"
#    $env.PrintInfo()
#    Invoke-VBAFBenchmark -Environment $env -Episodes 5 -Label "AlertRouter Random"
# 5. TRAIN DQN ON REAL WINDOWS DATA
#    $env   = New-EnterpriseEnvironment -Name "ResourceOptimizer"
#    $agent = (Invoke-DQNTraining -Episodes 50 -PrintEvery 10 -FastMode)[-1]
#    Invoke-VBAFBenchmark -Agent $agent -Environment $env -Episodes 10 -Label "DQN ResourceOptimizer"
# ============================================================
Write-Host "📦 VBAF.Enterprise.Environment.ps1 loaded  [v3.0.0 🏢]" -ForegroundColor Green
Write-Host "   Environments: JobScheduler, ResourceOptimizer, AlertRouter, SupplyChain" -ForegroundColor Cyan
Write-Host "   Function    : New-EnterpriseEnvironment"                    -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $env = New-EnterpriseEnvironment -Name "JobScheduler"'     -ForegroundColor White
Write-Host '   $env.PrintInfo()'                                           -ForegroundColor White
Write-Host '   Invoke-VBAFBenchmark -Environment $env -Episodes 5'        -ForegroundColor White
Write-Host ""


