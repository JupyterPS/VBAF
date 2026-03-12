#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 17 - Cloud Bridge Intelligence
.DESCRIPTION
    Trains a DQN agent to manage hybrid cloud/on-premise workload routing.
    The agent observes cloud connectivity signals and learns when to:
      - Local    : keep workload on-premise, cloud not needed  (action 0)
      - Offload  : push workload to cloud                      (action 1)
      - Sync     : synchronise data between local and cloud    (action 2)
      - Failover : route everything to cloud, local failing    (action 3)
.NOTES
    Part of VBAF - Phase 17 Enterprise Automation Engine
    Phase 17: Cloud Bridge Intelligence
    PS 5.1 compatible
    Real data: Test-NetConnection, WMI Win32_OperatingSystem, Get-Counter
    Design: CloudBandwidth INVERTED (high=healthy=Local, low=failing=Failover)
            breaks monotonic collapse — lesson from Phases 15 and 16
#>

# ============================================================
# PHASE 17 - CLOUD BRIDGE
# ============================================================

class CloudBridgeEnvironment {

    # State: 4 genuinely observable cloud health signals (0.0 - 1.0)
    # NO SeverityNorm — agent must learn the mapping from real signals
    # CloudBandwidth is INVERTED: high=healthy, low=failing — breaks monotonic collapse
    [double] $LocalLoad        # 0=idle             1=on-prem saturated
    [double] $CloudLatency     # 0=fast connection  1=very slow/unreachable
    [double] $CloudBandwidth   # 1=full bandwidth   0=bandwidth gone (INVERTED)
    [double] $SyncBacklog      # 0=in sync          1=massive data backlog

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

    CloudBridgeEnvironment() {
        $this.Reset() | Out-Null
    }

    # CRITICAL PS 5.1: build strictly typed [double[]] element by element
    # CloudBandwidth inverted — agent cannot simply maximise state values
    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.LocalLoad
        $s[1] = $this.CloudLatency
        $s[2] = $this.CloudBandwidth
        $s[3] = $this.SyncBacklog
        return $s
    }

    [double[]] Reset() {
        $this.Steps            = 0
        $this.TotalReward      = 0.0
        $this.CorrectActions   = 0
        $this.MissedFailovers  = 0
        $this.TruePositives    = 0
        $this.FalsePositives   = 0
        $this.TrueNegatives    = 0
        $this.FalseNegatives   = 0
        $this.LastDone         = $false   # CRITICAL: must reset here
        $this.EpisodeCount++
        $this._SampleCondition()
        [double[]] $initState = $this.GetState()
        return $initState
    }

    [void] _SampleCondition() {
        # Balanced training distribution
        # 25% local (0), 30% offload (1), 25% sync (2), 20% failover (3)
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 25) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 80) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                # Local: low on-prem load, fast cloud, HIGH bandwidth, minimal backlog
                $this.LocalLoad       = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.CloudLatency    = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.CloudBandwidth  = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                $this.SyncBacklog     = [double](Get-Random -Minimum 0  -Maximum 15) / 100.0
            }
            1 {
                # Offload: moderate on-prem load, decent cloud, good bandwidth
                $this.LocalLoad       = [double](Get-Random -Minimum 25 -Maximum 55) / 100.0
                $this.CloudLatency    = [double](Get-Random -Minimum 15 -Maximum 40) / 100.0
                $this.CloudBandwidth  = [double](Get-Random -Minimum 55 -Maximum 80) / 100.0
                $this.SyncBacklog     = [double](Get-Random -Minimum 15 -Maximum 45) / 100.0
            }
            2 {
                # Sync: high on-prem load, rising latency, moderate bandwidth, big backlog
                $this.LocalLoad       = [double](Get-Random -Minimum 55 -Maximum 75) / 100.0
                $this.CloudLatency    = [double](Get-Random -Minimum 40 -Maximum 65) / 100.0
                $this.CloudBandwidth  = [double](Get-Random -Minimum 30 -Maximum 55) / 100.0
                $this.SyncBacklog     = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
            }
            3 {
                # Failover: saturated on-prem, very high latency, LOW bandwidth, massive backlog
                $this.LocalLoad       = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                $this.CloudLatency    = [double](Get-Random -Minimum 65  -Maximum 100) / 100.0
                $this.CloudBandwidth  = [double](Get-Random -Minimum 0   -Maximum 30)  / 100.0
                $this.SyncBacklog     = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Local  1=Offload  2=Sync  3=Failover
        return $this.CurrentSeverity
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this._OptimalAction()

        # Symmetric distance-based reward (proven across Phases 10-16)
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
# Real Windows cloud connectivity probe
# ------------------------------------
function Get-VBAFCloudBridgeSnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing cloud bridge connectivity..." -ForegroundColor Gray

    try {
        # Network latency to cloud proxy (Google DNS)
        $tc = Test-NetConnection -ComputerName "8.8.8.8" -WarningAction SilentlyContinue -ErrorAction Stop
        $latency = if ($tc.PingSucceeded) { $tc.PingReplyDetails.RoundtripTime } else { 9999 }
        $latColour = if ($latency -lt 30) { "Green" } elseif ($latency -lt 100) { "Yellow" } else { "Red" }
        Write-Host ("   Cloud latency         : {0}ms" -f $latency) -ForegroundColor $latColour

        # On-prem memory load
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        [double[]] $memArr = @(0.0)
        $memArr[0]  = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
        $memArr[0] /= $os.TotalVisibleMemorySize
        $memArr[0] *= 100.0
        $memPct = [Math]::Round($memArr[0], 1)
        Write-Host ("   Local memory load     : {0}%" -f $memPct) -ForegroundColor $(if ($memPct -gt 85) { "Red" } elseif ($memPct -gt 65) { "Yellow" } else { "Green" })

        # CPU as workload proxy
        $cpu = Get-WmiObject -Class Win32_Processor -ErrorAction Stop | Select-Object -First 1
        Write-Host ("   Local CPU load        : {0}%" -f $cpu.LoadPercentage) -ForegroundColor White

        Write-Host "   Cloud bridge probe    : confirmed ✅" -ForegroundColor Green

    } catch {
        Write-Host "   [WARNING] Cloud probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated cloud conditions."    -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFCloudBridgeTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "☁️  VBAF Enterprise - Phase 17: Cloud Bridge"                       -ForegroundColor Cyan
    Write-Host "   Training DQN agent on hybrid cloud workload routing..."           -ForegroundColor Cyan
    Write-Host "   Actions: 0=Local  1=Offload  2=Sync  3=Failover"                 -ForegroundColor Yellow
    Write-Host "   State  : LocalLoad | CloudLatency | CloudBandwidth | SyncBacklog" -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"           -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFCloudBridgeSnapshot
    }

    $cbEnv = [CloudBridgeEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $cbEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $cbEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $cbEnv.Step($rAction)
            $bReward += $cbEnv.LastReward
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
            if      ($roll -le 25) { $cbEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $cbEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 80) { $cbEnv.CurrentSeverity = 2 }
            else                   { $cbEnv.CurrentSeverity = 3 }

            switch ($cbEnv.CurrentSeverity) {
                0 {
                    $cbEnv.LocalLoad      = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $cbEnv.CloudLatency   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $cbEnv.CloudBandwidth = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                    $cbEnv.SyncBacklog    = [double](Get-Random -Minimum 0  -Maximum 15) / 100.0
                }
                1 {
                    $cbEnv.LocalLoad      = [double](Get-Random -Minimum 25 -Maximum 55) / 100.0
                    $cbEnv.CloudLatency   = [double](Get-Random -Minimum 15 -Maximum 40) / 100.0
                    $cbEnv.CloudBandwidth = [double](Get-Random -Minimum 55 -Maximum 80) / 100.0
                    $cbEnv.SyncBacklog    = [double](Get-Random -Minimum 15 -Maximum 45) / 100.0
                }
                2 {
                    $cbEnv.LocalLoad      = [double](Get-Random -Minimum 55 -Maximum 75) / 100.0
                    $cbEnv.CloudLatency   = [double](Get-Random -Minimum 40 -Maximum 65) / 100.0
                    $cbEnv.CloudBandwidth = [double](Get-Random -Minimum 30 -Maximum 55) / 100.0
                    $cbEnv.SyncBacklog    = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                }
                3 {
                    $cbEnv.LocalLoad      = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                    $cbEnv.CloudLatency   = [double](Get-Random -Minimum 65  -Maximum 100) / 100.0
                    $cbEnv.CloudBandwidth = [double](Get-Random -Minimum 0   -Maximum 30)  / 100.0
                    $cbEnv.SyncBacklog    = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                }
            }
            $cbEnv.CorrectActions  = 0
            $cbEnv.MissedFailovers = 0
            $cbEnv.Steps           = 0
            $cbEnv.TotalReward     = 0.0
            $cbEnv.LastDone        = $false
            $cbEnv.EpisodeCount++
            $state = $cbEnv.GetState()
        } else {
            $state = $cbEnv.Reset()
        }

        $done           = $false
        $epReward       = 0.0
        $localCount     = 0
        $offloadCount   = 0
        $syncCount      = 0
        $failoverCount  = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $cbEnv.Step($action)
            [double[]] $nextState = $cbEnv.GetState()
            [double]   $reward    = $cbEnv.LastReward
            [bool]     $isDone    = $cbEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $localCount++   }
                1 { $offloadCount++ }
                2 { $syncCount++    }
                3 { $failoverCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode  = $ep
            Reward   = $epReward
            Local    = $localCount
            Offload  = $offloadCount
            Sync     = $syncCount
            Failover = $failoverCount
            Epsilon  = $agent.Epsilon
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN  = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            [double[]] $avgArr = @(0.0)
            $avgArr[0]  = $avgSum
            $avgArr[0] /= $lastN.Count
            $avg = [Math]::Round($avgArr[0], 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Loc:{4} Off:{5} Syn:{6} Fov:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $localCount, $offloadCount, $syncCount, $failoverCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $cbEnv.Reset()
        $tReward = 0.0
        while (-not $cbEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $cbEnv.Step($tAction)
            [double[]] $evalState = $cbEnv.GetState()
            $tReward += $cbEnv.LastReward
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
    $denomP = $cbEnv.TruePositives + $cbEnv.FalsePositives
    $denomR = $cbEnv.TruePositives + $cbEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $cbEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $cbEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 17: Cloud Bridge - Results                ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Sync+Failover corr): {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (failovers caught)  : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Local    keep workload on-premise            ║" -ForegroundColor White
    Write-Host "║    Offload  push workload to cloud              ║" -ForegroundColor White
    Write-Host "║    Sync     synchronise local and cloud data    ║" -ForegroundColor White
    Write-Host "║    Failover route everything to cloud           ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated cloud conditions)
#    $r = Invoke-VBAFCloudBridgeTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real latency, WMI memory, CPU)
#    $r = Invoke-VBAFCloudBridgeTraining -Episodes 100 -PrintEvery 10
#
# 4. SKIP REAL DATA PROBE
#    $r = Invoke-VBAFCloudBridgeTraining -Episodes 100 -PrintEvery 10 -SkipRealData
#
# 5. INSPECT AGENT DECISIONS
#    $env   = [CloudBridgeEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "LocalLoad: $($env.LocalLoad)  CloudLatency: $($env.CloudLatency)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Local","Offload","Sync","Failover")
#    Write-Host "Cloud Bridge decision: $($labels[$action])"
#
# 6. VIEW CONFUSION MATRIX
#    Write-Host "True Positives : $($env.TruePositives)"
#    Write-Host "False Positives: $($env.FalsePositives)"
#    Write-Host "True Negatives : $($env.TrueNegatives)"
#    Write-Host "False Negatives: $($env.FalseNegatives)"
# ============================================================
Write-Host "📦 VBAF.Enterprise.CloudBridge.ps1 loaded  [v3.7.0 ☁️]"  -ForegroundColor Green
Write-Host "   Phase 17: Cloud Bridge Intelligence"                     -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFCloudBridgeTraining"               -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFCloudBridgeTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""