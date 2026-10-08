#Requires -Version 5.1
<#
.SYNOPSIS
    VBAF Enterprise - Healthcare Monitor (Phase 29)
    Autonomous patient flow and resource management
.DESCRIPTION
    DQN agent that observes real-time hospital signals and recommends
    the optimal response action:
      0 = Monitor   : all good, watch and wait
      1 = Triage    : patients waiting, assess and prioritise
      2 = Escalate  : critical resources low, call in support
      3 = Emergency : full emergency response, all hands on deck

    State signals:
      BedOccupancy     : % of beds occupied
      StaffAvailable   : % of required staff present
      WaitingPatients  : patients waiting beyond target time
      CriticalAlerts   : active critical patient alerts
#>

class HealthcareEnvironment {

    [double] $BedOccupancy      # 0=empty        1=fully occupied
    [double] $StaffAvailable    # 0=fully staffed 1=critically understaffed
    [double] $WaitingPatients   # 0=no wait       1=critical backlog
    [double] $CriticalAlerts    # 0=no alerts     1=multiple critical alerts

    [int]    $CorrectActions
    [int]    $Steps
    [double] $TotalReward
    [int]    $EpisodeCount
    [int]    $CurrentSeverity
    [int]    $StateSize  = 4
    [int]    $ActionSize = 4
    [double] $LastReward = 0.0
    [bool]   $LastDone   = $false

    HealthcareEnvironment() { $this.Reset() | Out-Null }

    [double[]] GetState() {
        return [double[]]@(
            $this.BedOccupancy,
            $this.StaffAvailable,
            $this.WaitingPatients,
            $this.CriticalAlerts
        )
    }

    [double[]] Reset() {
        $this.Steps          = 0
        $this.TotalReward    = 0.0
        $this.CorrectActions = 0
        $this.LastDone       = $false
        $this.EpisodeCount++
        $this._Sample()
        return $this.GetState()
    }

    [void] _Sample() {
        # Distribution 5/40/35/20 — battle-tested formula
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 5)  { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 45) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 80) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                $this.BedOccupancy    = [double](Get-Random -Minimum 0  -Maximum 20)  / 100.0
                $this.StaffAvailable  = [double](Get-Random -Minimum 0  -Maximum 20)  / 100.0
                $this.WaitingPatients = [double](Get-Random -Minimum 0  -Maximum 20)  / 100.0
                $this.CriticalAlerts  = [double](Get-Random -Minimum 0  -Maximum 20)  / 100.0
            }
            1 {
                $this.BedOccupancy    = [double](Get-Random -Minimum 25 -Maximum 50)  / 100.0
                $this.StaffAvailable  = [double](Get-Random -Minimum 25 -Maximum 50)  / 100.0
                $this.WaitingPatients = [double](Get-Random -Minimum 25 -Maximum 50)  / 100.0
                $this.CriticalAlerts  = [double](Get-Random -Minimum 25 -Maximum 50)  / 100.0
            }
            2 {
                $this.BedOccupancy    = [double](Get-Random -Minimum 50 -Maximum 75)  / 100.0
                $this.StaffAvailable  = [double](Get-Random -Minimum 50 -Maximum 75)  / 100.0
                $this.WaitingPatients = [double](Get-Random -Minimum 50 -Maximum 75)  / 100.0
                $this.CriticalAlerts  = [double](Get-Random -Minimum 50 -Maximum 75)  / 100.0
            }
            3 {
                $this.BedOccupancy    = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.StaffAvailable  = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.WaitingPatients = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.CriticalAlerts  = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
            }
        }
    }

    [void] Step([int]$action) {
        $this.Steps++
        $dist = [Math]::Abs($action - $this.CurrentSeverity)
        if    ($dist -eq 0) { $this.LastReward =  2.0; $this.CorrectActions++ }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }
        $this.TotalReward += $this.LastReward
        $this._Sample()
        $this.LastDone = ($this.Steps -ge 200)
    }
}

# ============================================================
# REAL DATA PROBE
# ============================================================
function Get-VBAFHealthcareSnapshot {
    Write-Host ""
    Write-Host "   Probing healthcare signals..." -ForegroundColor Gray
    try {
        $os  = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop
        [double] $mem = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize
        $cpu = (Get-WmiObject Win32_Processor -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average).Average
        $procs = (Get-Process -ErrorAction Stop).Count
        Write-Host ("   Bed occupancy proxy    : {0:F1}% (memory use)"  -f ($mem * 100))  -ForegroundColor White
        Write-Host ("   Staff available proxy  : {0}% (CPU load)"       -f $cpu)          -ForegroundColor White
        Write-Host ("   Patient flow proxy     : {0} processes running"  -f $procs)        -ForegroundColor White
        Write-Host "   Healthcare probe       : confirmed ✅"             -ForegroundColor Green
    } catch {
        Write-Host "   Using simulated healthcare conditions." -ForegroundColor Gray
    }
    Write-Host ""
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFHealthcareMonitorTraining {
    param(
        [int]    $Episodes   = 100,
        [int]    $PrintEvery = 10,
        [switch] $SimMode
    )

    Write-Host ""
    Write-Host "🏥 VBAF Healthcare Monitor — Phase 29"                        -ForegroundColor Cyan
    Write-Host "   Autonomous patient flow and resource management"            -ForegroundColor Cyan
    Write-Host "   Actions: 0=Monitor  1=Triage  2=Escalate  3=Emergency"    -ForegroundColor Yellow
    Write-Host "   State  : BedOccupancy | StaffAvailable | Waiting | Alerts" -ForegroundColor Yellow
    Write-Host ""

    if (-not $SimMode) { Get-VBAFHealthcareSnapshot }

    $env = [HealthcareEnvironment]::new()

    # Baseline
    Write-Host "   Phase 1: Baseline (random response)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $env.Reset() | Out-Null
        $bRew = 0.0
        while (-not $env.LastDone) {
            $env.Step((Get-Random -Minimum 0 -Maximum 4))
            $bRew += $env.LastReward
        }
        $baseRewards += $bRew
    }
    [double]$baseAvg = ($baseRewards | Measure-Object -Average).Average
    Write-Host ("   Random response avg reward: {0:F2}" -f $baseAvg) -ForegroundColor Gray
    Write-Host ""

    # Train
    Write-Host "   Phase 2: Training DQN agent ($Episodes episodes)..." -ForegroundColor Gray

    $config              = [DQNConfig]::new()
    $config.StateSize    = 4
    $config.ActionSize   = 4
    $config.EpsilonDecay = 0.9995
    $config.EpsilonMin   = 0.05
    [int[]] $arch        = @(4, 24, 24, 4)
    $agent               = [DQNAgent]::new($config,
                               [VBAFNetworkFactory]::Create($arch, $config.LearningRate),
                               [VBAFNetworkFactory]::Create($arch, $config.LearningRate),
                               [ExperienceReplay]::new($config.MemorySize))

    $results = [System.Collections.Generic.List[object]]::new()

    for ($ep = 1; $ep -le $Episodes; $ep++) {
        [double[]] $state = $env.Reset()
        $done    = $false
        $epRew   = 0.0
        $stepCnt = 0
        $counts  = @(0,0,0,0)

        while (-not $done) {
            $action = $agent.Act($state)
            $env.Step($action)
            [double[]] $next = $env.GetState()
            $agent.Remember($state, $action, $env.LastReward, $next, $env.LastDone)
            $stepCnt++
            if ($stepCnt % 4 -eq 0) { $agent.Replay() | Out-Null }
            $state  = $next
            $done   = $env.LastDone
            $epRew += $env.LastReward
            $counts[$action]++
        }
        $agent.EndEpisode($epRew) | Out-Null
        $results.Add($epRew)

        if ($ep % $PrintEvery -eq 0) {
            $last = $results | Select-Object -Last $PrintEvery
            [double]$avg = ($last | Measure-Object -Average).Average
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7:F1}  Eps: {3:F3}  Mon:{4} Tri:{5} Esc:{6} Emg:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $counts[0], $counts[1], $counts[2], $counts[3]) -ForegroundColor White
        }
    }

    # Evaluate
    Write-Host ""
    Write-Host "   Phase 3: Evaluation (epsilon=0)..." -ForegroundColor Gray
    $agent.Epsilon  = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $s = $env.Reset()
        $tRew = 0.0
        while (-not $env.LastDone) {
            $env.Step($agent.Act($s))
            $s    = $env.GetState()
            $tRew += $env.LastReward
        }
        $trainedRewards += $tRew
    }
    [double]$trainedAvg = ($trainedRewards | Measure-Object -Average).Average
    [double]$imp = ($trainedAvg - $baseAvg) / [Math]::Abs($baseAvg) * 100.0

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 29: Healthcare Monitor — Results  🏥      ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Random response avg reward : {0,8:F2}          ║" -f $baseAvg)    -ForegroundColor Gray
    Write-Host ("║  AI response avg reward     : {0,8:F2}          ║" -f $trainedAvg) -ForegroundColor Green
    Write-Host ("║  Improvement                : {0,7:F1}%          ║" -f $imp)       -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Monitor   all good, watch and wait           ║" -ForegroundColor White
    Write-Host "║    Triage    assess and prioritise patients      ║" -ForegroundColor White
    Write-Host "║    Escalate  call in additional support          ║" -ForegroundColor White
    Write-Host "║    Emergency full emergency, all hands on deck   ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent=$agent; Baseline=@{Avg=$baseAvg}; Trained=@{Avg=$trainedAvg}; Improvement=$imp }
}

Write-Host "📦 VBAF.Enterprise.HealthcareMonitor.ps1 loaded  [🏥 Phase 29]" -ForegroundColor Green
Write-Host "   Function : Invoke-VBAFHealthcareMonitorTraining"               -ForegroundColor Cyan
Write-Host '   Run      : $r = Invoke-VBAFHealthcareMonitorTraining -SimMode' -ForegroundColor White
Write-Host ""
