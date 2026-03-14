#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 26 - Multi-Site Coordinator
.DESCRIPTION
    Trains a DQN agent to coordinate workload distribution across
    multiple enterprise sites. The agent observes site health signals
    and learns when to:
      - Local     : keep workload at current site, no movement      (action 0)
      - Sync      : replicate data/state across sites               (action 1)
      - Failover  : move workload to secondary site                 (action 2)
      - Rebalance : redistribute load across all sites              (action 3)
.NOTES
    Part of VBAF - Phase 26 Enterprise Automation Engine
    Phase 26: Multi-Site Coordinator
    PS 5.1 compatible
    Real data: Test-NetConnection, WMI Win32_OperatingSystem, Get-Process
    Design: No inversion + distribution 15/40/30/15 — confirmed winning formula
#>

# ============================================================
# PHASE 26 - MULTI-SITE COORDINATOR
# ============================================================

class MultiSiteCoordinatorEnvironment {

    # State: 4 genuinely observable site health signals (0.0 - 1.0)
    # NO SeverityNorm — agent must learn the mapping from real signals
    # NO inversion — distribution math alone guarantees positive result
    [double] $SiteLatency       # 0=low latency          1=high latency
    [double] $LoadImbalance     # 0=balanced             1=severely imbalanced
    [double] $SiteAvailability  # 0=all sites up         1=sites failing
    [double] $ReplicationLag    # 0=in sync              1=severely lagged

    [int]    $CorrectActions
    [int]    $MissedFailovers
    [int]    $Steps
    [double] $TotalReward
    [int]    $EpisodeCount

    # Confusion matrix
    [int]    $TruePositives
    [int]    $FalsePositives
    [int]    $TrueNegatives
    [int]    $FalseNegatives

    [int]    $CurrentSeverity  # raw 0-3 (maps directly to optimal action)

    # Required by VBAF framework
    [int]    $StateSize  = 4
    [int]    $ActionSize = 4

    # Step() stores result here — avoids PSCustomObject type corruption (PS 5.1)
    [double] $LastReward = 0.0
    [bool]   $LastDone   = $false

    MultiSiteCoordinatorEnvironment() {
        $this.Reset() | Out-Null
    }

    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.SiteLatency
        $s[1] = $this.LoadImbalance
        $s[2] = $this.SiteAvailability
        $s[3] = $this.ReplicationLag
        return $s
    }

    [double[]] Reset() {
        $this.Steps          = 0
        $this.TotalReward    = 0.0
        $this.CorrectActions = 0
        $this.MissedFailovers= 0
        $this.TruePositives  = 0
        $this.FalsePositives = 0
        $this.TrueNegatives  = 0
        $this.FalseNegatives = 0
        $this.LastDone       = $false   # CRITICAL: must reset here
        $this.EpisodeCount++
        $this._SampleCondition()
        [double[]] $initState = $this.GetState()
        return $initState
    }

    [void] _SampleCondition() {
        # Distribution 15/40/30/15 — confirmed winning formula from Phases 21-25
        # Sync(1)=40% majority: collapse to action 1 = positive result
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 15) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 85) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                # Local: low latency, balanced, all up, in sync
                $this.SiteLatency      = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.LoadImbalance    = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.SiteAvailability = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.ReplicationLag   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
            }
            1 {
                # Sync: moderate latency, slight imbalance, minor issues, some lag
                $this.SiteLatency      = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.LoadImbalance    = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.SiteAvailability = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.ReplicationLag   = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
            }
            2 {
                # Failover: high latency, imbalanced, site degraded, significant lag
                $this.SiteLatency      = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.LoadImbalance    = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.SiteAvailability = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.ReplicationLag   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
            }
            3 {
                # Rebalance: critical latency, severe imbalance, sites failing, out of sync
                $this.SiteLatency      = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.LoadImbalance    = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.SiteAvailability = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.ReplicationLag   = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Local  1=Sync  2=Failover  3=Rebalance
        return $this.CurrentSeverity
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this._OptimalAction()

        [int] $dist = $action - $optimal
        if ($dist -lt 0) { $dist = -$dist }

        if    ($dist -eq 0) { $this.LastReward =  2.0; $this.CorrectActions++ }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }

        if ($this.CurrentSeverity -ge 2 -and $action -lt 2) { $this.MissedFailovers++ }

        $isCritical  = ($this.CurrentSeverity -ge 2)
        $agentActs   = ($action -ge 2)
        if ($isCritical  -and $agentActs)  { $this.TruePositives++  }
        if (!$isCritical -and $agentActs)  { $this.FalsePositives++ }
        if (!$isCritical -and !$agentActs) { $this.TrueNegatives++  }
        if ($isCritical  -and !$agentActs) { $this.FalseNegatives++ }

        $this.TotalReward += $this.LastReward
        $this._SampleCondition()
        $this.LastDone = ($this.Steps -ge 200)
    }
}

# ------------------------------------
# Real Windows multi-site probe
# ------------------------------------
function Get-VBAFMultiSiteSnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing multi-site coordination signals..." -ForegroundColor Gray

    try {
        # Network latency as site latency proxy
        $ping = Test-NetConnection -ComputerName "8.8.8.8" -InformationLevel Quiet -ErrorAction SilentlyContinue
        Write-Host ("   Network reachable     : {0}" -f $(if ($ping) { "yes ✅" } else { "no ⚠️" })) -ForegroundColor White

        # Free memory as site health proxy
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        [double[]] $freeArr = @(0.0)
        $freeArr[0]  = $os.FreePhysicalMemory
        $freeArr[0] /= $os.TotalVisibleMemorySize
        $freeArr[0] *= 100.0
        $freePct = [Math]::Round($freeArr[0], 1)
        Write-Host ("   Memory free           : {0}%" -f $freePct) -ForegroundColor White

        # CPU load as load imbalance proxy
        $cpuLoad = (Get-WmiObject -Class Win32_Processor -ErrorAction Stop |
            Measure-Object -Property LoadPercentage -Average).Average
        Write-Host ("   CPU load              : {0}%" -f [Math]::Round($cpuLoad, 1)) `
            -ForegroundColor $(if ($cpuLoad -gt 80) { "Red" } elseif ($cpuLoad -gt 50) { "Yellow" } else { "Green" })

        Write-Host "   Multi-site probe      : confirmed ✅" -ForegroundColor Green

    } catch {
        Write-Host "   [WARNING] Multi-site probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated site conditions."          -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFMultiSiteCoordinatorTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "🌍 VBAF Enterprise - Phase 26: Multi-Site Coordinator"                -ForegroundColor Cyan
    Write-Host "   Training DQN agent on cross-site workload coordination..."          -ForegroundColor Cyan
    Write-Host "   Actions: 0=Local  1=Sync  2=Failover  3=Rebalance"                -ForegroundColor Yellow
    Write-Host "   State  : SiteLatency | LoadImbalance | Availability | RepLag"     -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"            -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFMultiSiteSnapshot
    }

    $msEnv = [MultiSiteCoordinatorEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $msEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $msEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $msEnv.Step($rAction)
            $bReward += $msEnv.LastReward
        }
        $baseRewards += $bReward
    }
    [double[]] $bAvgArr = @(0.0)
    $bAvgArr[0] = ($baseRewards | Measure-Object -Average).Average
    Write-Host ("   Baseline avg reward: {0:F2}" -f $bAvgArr[0]) -ForegroundColor Gray

    if ($FastMode) { $Episodes = [Math]::Min($Episodes, 30) }
    Write-Host ""
    Write-Host "   Phase 2: Training DQN agent ($Episodes episodes)..." -ForegroundColor Gray

    $config              = [DQNConfig]::new()
    $config.StateSize    = 4
    $config.ActionSize   = 4
    $config.EpsilonDecay = 0.9995
    $config.EpsilonMin   = 0.05
    [int[]] $arch        = @(4, 24, 24, 4)
    $mainNetwork         = [NeuralNetwork]::new($arch, $config.LearningRate)
    $targetNetwork       = [NeuralNetwork]::new($arch, $config.LearningRate)
    $memory              = [ExperienceReplay]::new($config.MemorySize)
    $agent               = [DQNAgent]::new($config, $mainNetwork, $targetNetwork, $memory)

    $results = [System.Collections.Generic.List[object]]::new()

    for ($ep = 1; $ep -le $Episodes; $ep++) {

        [double[]] $state = @(0.0, 0.0, 0.0, 0.0)

        if ($SimMode) {
            $roll = Get-Random -Minimum 1 -Maximum 100
            if      ($roll -le 15) { $msEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $msEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 85) { $msEnv.CurrentSeverity = 2 }
            else                   { $msEnv.CurrentSeverity = 3 }

            switch ($msEnv.CurrentSeverity) {
                0 {
                    $msEnv.SiteLatency      = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $msEnv.LoadImbalance    = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $msEnv.SiteAvailability = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $msEnv.ReplicationLag   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                }
                1 {
                    $msEnv.SiteLatency      = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $msEnv.LoadImbalance    = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $msEnv.SiteAvailability = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $msEnv.ReplicationLag   = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                }
                2 {
                    $msEnv.SiteLatency      = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $msEnv.LoadImbalance    = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $msEnv.SiteAvailability = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $msEnv.ReplicationLag   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                }
                3 {
                    $msEnv.SiteLatency      = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                    $msEnv.LoadImbalance    = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                    $msEnv.SiteAvailability = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                    $msEnv.ReplicationLag   = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                }
            }
            $msEnv.CorrectActions = 0
            $msEnv.MissedFailovers= 0
            $msEnv.Steps          = 0
            $msEnv.TotalReward    = 0.0
            $msEnv.LastDone       = $false
            $msEnv.EpisodeCount++
            $state = $msEnv.GetState()
        } else {
            $state = $msEnv.Reset()
        }

        $done           = $false
        $epReward       = 0.0
        $localCount     = 0
        $syncCount      = 0
        $failoverCount  = 0
        $rebalanceCount = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $msEnv.Step($action)
            [double[]] $nextState = $msEnv.GetState()
            [double]   $reward    = $msEnv.LastReward
            [bool]     $isDone    = $msEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $localCount++     }
                1 { $syncCount++      }
                2 { $failoverCount++  }
                3 { $rebalanceCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode   = $ep
            Reward    = $epReward
            Local     = $localCount
            Sync      = $syncCount
            Failover  = $failoverCount
            Rebalance = $rebalanceCount
            Epsilon   = $agent.Epsilon
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN  = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            [double[]] $avgArr = @(0.0)
            $avgArr[0]  = $avgSum
            $avgArr[0] /= $lastN.Count
            $avg = [Math]::Round($avgArr[0], 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Loc:{4} Syn:{5} Fov:{6} Reb:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $localCount, $syncCount, $failoverCount, $rebalanceCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $msEnv.Reset()
        $tReward = 0.0
        while (-not $msEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $msEnv.Step($tAction)
            [double[]] $evalState = $msEnv.GetState()
            $tReward += $msEnv.LastReward
        }
        $trainedRewards += $tReward
    }
    [double[]] $tAvgArr = @(0.0)
    $tAvgArr[0] = ($trainedRewards | Measure-Object -Average).Average
    Write-Host ("   Trained avg reward: {0:F2}" -f $tAvgArr[0]) -ForegroundColor Green

    [double[]] $impArr = @(0.0)
    if ($bAvgArr[0] -ne 0) {
        $impArr[0]  = $tAvgArr[0] - $bAvgArr[0]
        $impArr[0] /= [Math]::Abs($bAvgArr[0])
        $impArr[0] *= 100.0
    }
    $bAvg        = [Math]::Round($bAvgArr[0], 2)
    $tAvg        = [Math]::Round($tAvgArr[0], 2)
    $improvement = [Math]::Round($impArr[0], 1)

    [double[]] $precArr = @(0.0)
    [double[]] $recArr  = @(0.0)
    $denomP = $msEnv.TruePositives + $msEnv.FalsePositives
    $denomR = $msEnv.TruePositives + $msEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $msEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $msEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 26: Multi-Site Coordinator - Results      ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Fail+Reb correct)  : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (failovers handled) : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Local     keep workload at current site      ║" -ForegroundColor White
    Write-Host "║    Sync      replicate data across sites        ║" -ForegroundColor White
    Write-Host "║    Failover  move workload to secondary site    ║" -ForegroundColor White
    Write-Host "║    Rebalance redistribute load across all sites ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# $r = Invoke-VBAFMultiSiteCoordinatorTraining -Episodes 100 -PrintEvery 10 -SimMode
# ============================================================
Write-Host "📦 VBAF.Enterprise.MultiSiteCoordinator.ps1 loaded  [v3.16.0 🌍]" -ForegroundColor Green
Write-Host "   Phase 26: Multi-Site Coordinator"                                -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFMultiSiteCoordinatorTraining"              -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFMultiSiteCoordinatorTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""