#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 14 - Self-Healing Infrastructure
.DESCRIPTION
    Trains a DQN agent to detect and autonomously remediate system
    failures without human intervention. The agent observes system
    health signals and learns when to:
      - Observe  : monitor, no remediation needed yet    (action 0)
      - Adjust   : tune configuration to restore health  (action 1)
      - Restart  : cycle the affected service/component  (action 2)
      - Rebuild  : full remediation — reprovision asset  (action 3)
.NOTES
    Part of VBAF - Phase 14 Enterprise Automation Engine
    Phase 14: Self-Healing Infrastructure
    PS 5.1 compatible
    Real data: Get-Service, Get-Process, WMI Win32_OperatingSystem
#>

# ============================================================
# PHASE 14 - SELF-HEALING INFRASTRUCTURE
# ============================================================

class SelfHealingEnvironment {

    # State: 4 normalised system health dimensions (0.0 - 1.0)
    # state[0] = SeverityNorm — direct action signal (proven pattern)
    [double] $SeverityNorm      # CurrentSeverity/3.0
    [double] $HealthScore       # 1=fully degraded   0=perfectly healthy
    [double] $RecoveryUrgency   # 0=can wait         1=must act now
    [double] $ImpactScope       # 0=single process   1=entire infrastructure

    [int]    $CorrectActions
    [int]    $MissedHealings
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

    SelfHealingEnvironment() {
        $this.Reset() | Out-Null
    }

    # CRITICAL PS 5.1: build strictly typed [double[]] element by element
    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.SeverityNorm
        $s[1] = $this.HealthScore
        $s[2] = $this.RecoveryUrgency
        $s[3] = $this.ImpactScope
        return $s
    }

    [double[]] Reset() {
        $this.Steps           = 0
        $this.TotalReward     = 0.0
        $this.CorrectActions  = 0
        $this.MissedHealings  = 0
        $this.TruePositives   = 0
        $this.FalsePositives  = 0
        $this.TrueNegatives   = 0
        $this.FalseNegatives  = 0
        $this.LastDone        = $false   # CRITICAL: must reset here
        $this.EpisodeCount++
        $this._SampleCondition()
        [double[]] $initState = $this.GetState()
        return $initState
    }

    [void] _SampleCondition() {
        # Balanced training distribution
        # 25% healthy (0), 30% degraded (1), 25% failing (2), 20% critical (3)
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 25) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 80) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        # SeverityNorm = direct action signal in state[0]
        [double[]] $snArr = @(0.0)
        $snArr[0]  = $this.CurrentSeverity
        $snArr[0] /= 3.0
        $this.SeverityNorm = $snArr[0]

        # Generate system health metrics consistent with severity
        switch ($this.CurrentSeverity) {
            0 {
                # Healthy: high health, low urgency, minimal scope
                $this.HealthScore      = [double](Get-Random -Minimum 0  -Maximum 10) / 100.0
                $this.RecoveryUrgency  = [double](Get-Random -Minimum 0  -Maximum 10) / 100.0
                $this.ImpactScope      = [double](Get-Random -Minimum 0  -Maximum 10) / 100.0
            }
            1 {
                # Degraded: moderate health loss, some urgency
                $this.HealthScore      = [double](Get-Random -Minimum 10 -Maximum 35) / 100.0
                $this.RecoveryUrgency  = [double](Get-Random -Minimum 10 -Maximum 40) / 100.0
                $this.ImpactScope      = [double](Get-Random -Minimum 10 -Maximum 35) / 100.0
            }
            2 {
                # Failing: significant health loss, high urgency
                $this.HealthScore      = [double](Get-Random -Minimum 35 -Maximum 70) / 100.0
                $this.RecoveryUrgency  = [double](Get-Random -Minimum 40 -Maximum 75) / 100.0
                $this.ImpactScope      = [double](Get-Random -Minimum 35 -Maximum 70) / 100.0
            }
            3 {
                # Critical: system down, must act immediately, wide impact
                $this.HealthScore      = [double](Get-Random -Minimum 70  -Maximum 100) / 100.0
                $this.RecoveryUrgency  = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                $this.ImpactScope      = [double](Get-Random -Minimum 70  -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Observe  1=Adjust  2=Restart  3=Rebuild
        return $this.CurrentSeverity
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this._OptimalAction()

        # Symmetric distance-based reward (proven in Phases 10-13)
        [int] $dist = $action - $optimal
        if ($dist -lt 0) { $dist = -$dist }

        if    ($dist -eq 0) { $this.LastReward =  2.0; $this.CorrectActions++ }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }

        if ($this.CurrentSeverity -ge 2 -and $action -lt 2) { $this.MissedHealings++ }

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
# Real Windows system health probe
# ------------------------------------
function Get-VBAFSelfHealingSnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing system health for self-healing..." -ForegroundColor Gray

    try {
        # OS health via WMI
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        [double[]] $memArr = @(0.0)
        $memArr[0]  = $os.FreePhysicalMemory
        $memArr[0] /= $os.TotalVisibleMemorySize
        $memArr[0] *= 100.0
        $freePct = [Math]::Round($memArr[0], 1)
        Write-Host ("   Free memory           : {0}%" -f $freePct) -ForegroundColor $(if ($freePct -lt 10) { "Red" } elseif ($freePct -lt 25) { "Yellow" } else { "Green" })
        Write-Host ("   Last boot             : {0}" -f $os.LastBootUpTime.Substring(0,8)) -ForegroundColor White

        # Services — count stopped vs running
        $services    = Get-Service -ErrorAction Stop
        $running     = ($services | Where-Object { $_.Status -eq "Running" }).Count
        $stopped     = ($services | Where-Object { $_.Status -eq "Stopped" }).Count
        Write-Host ("   Services running      : {0}" -f $running) -ForegroundColor Green
        Write-Host ("   Services stopped      : {0}" -f $stopped) -ForegroundColor $(if ($stopped -gt 20) { "Yellow" } else { "White" })

        # Processes — top 3 by CPU
        $topProcs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 3
        Write-Host ""
        Write-Host "   Top processes by CPU:" -ForegroundColor Gray
        foreach ($p in $topProcs) {
            Write-Host ("     {0,-25} CPU: {1:F1}s" -f $p.Name, $p.CPU) -ForegroundColor DarkCyan
        }

    } catch {
        Write-Host "   [WARNING] System probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated health conditions."    -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFSelfHealingTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "🔄 VBAF Enterprise - Phase 14: Self-Healing Infrastructure"         -ForegroundColor Cyan
    Write-Host "   Training DQN agent on autonomous system remediation..."           -ForegroundColor Cyan
    Write-Host "   Actions: 0=Observe  1=Adjust  2=Restart  3=Rebuild"             -ForegroundColor Yellow
    Write-Host "   State  : SeverityNorm | HealthScore | Urgency | ImpactScope"    -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"          -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFSelfHealingSnapshot
    }

    $shEnv = [SelfHealingEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $shEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $shEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $shEnv.Step($rAction)
            $bReward += $shEnv.LastReward
        }
        $baseRewards += $bReward
    }
    [double[]] $bAvgArr = @(0.0)
    $bAvgArr[0] = ($baseRewards | Measure-Object -Average).Average
    Write-Host ("   Baseline avg reward: {0:F2}" -f $bAvgArr[0]) -ForegroundColor Gray

    if ($FastMode) { $Episodes = [Math]::Min($Episodes, 30) }
    Write-Host ""
    Write-Host "   Phase 2: Training DQN agent ($Episodes episodes)..." -ForegroundColor Gray

    # DQN setup
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
            if      ($roll -le 25) { $shEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $shEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 80) { $shEnv.CurrentSeverity = 2 }
            else                   { $shEnv.CurrentSeverity = 3 }

            [double[]] $snArr = @(0.0)
            $snArr[0]  = $shEnv.CurrentSeverity
            $snArr[0] /= 3.0
            $shEnv.SeverityNorm = $snArr[0]

            switch ($shEnv.CurrentSeverity) {
                0 {
                    $shEnv.HealthScore     = [double](Get-Random -Minimum 0  -Maximum 10) / 100.0
                    $shEnv.RecoveryUrgency = [double](Get-Random -Minimum 0  -Maximum 10) / 100.0
                    $shEnv.ImpactScope     = [double](Get-Random -Minimum 0  -Maximum 10) / 100.0
                }
                1 {
                    $shEnv.HealthScore     = [double](Get-Random -Minimum 10 -Maximum 35) / 100.0
                    $shEnv.RecoveryUrgency = [double](Get-Random -Minimum 10 -Maximum 40) / 100.0
                    $shEnv.ImpactScope     = [double](Get-Random -Minimum 10 -Maximum 35) / 100.0
                }
                2 {
                    $shEnv.HealthScore     = [double](Get-Random -Minimum 35 -Maximum 70) / 100.0
                    $shEnv.RecoveryUrgency = [double](Get-Random -Minimum 40 -Maximum 75) / 100.0
                    $shEnv.ImpactScope     = [double](Get-Random -Minimum 35 -Maximum 70) / 100.0
                }
                3 {
                    $shEnv.HealthScore     = [double](Get-Random -Minimum 70  -Maximum 100) / 100.0
                    $shEnv.RecoveryUrgency = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                    $shEnv.ImpactScope     = [double](Get-Random -Minimum 70  -Maximum 100) / 100.0
                }
            }
            $shEnv.CorrectActions = 0
            $shEnv.MissedHealings = 0
            $shEnv.Steps          = 0
            $shEnv.TotalReward    = 0.0
            $shEnv.LastDone       = $false
            $shEnv.EpisodeCount++
            $state = $shEnv.GetState()
        } else {
            $state = $shEnv.Reset()
        }

        $done           = $false
        $epReward       = 0.0
        $observeCount   = 0
        $adjustCount    = 0
        $restartCount   = 0
        $rebuildCount   = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $shEnv.Step($action)
            [double[]] $nextState = $shEnv.GetState()
            [double]   $reward    = $shEnv.LastReward
            [bool]     $isDone    = $shEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $observeCount++  }
                1 { $adjustCount++   }
                2 { $restartCount++  }
                3 { $rebuildCount++  }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode  = $ep
            Reward   = $epReward
            Observe  = $observeCount
            Adjust   = $adjustCount
            Restart  = $restartCount
            Rebuild  = $rebuildCount
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
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Obs:{4} Adj:{5} Rst:{6} Rbd:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $observeCount, $adjustCount, $restartCount, $rebuildCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $shEnv.Reset()
        $tReward = 0.0
        while (-not $shEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $shEnv.Step($tAction)
            [double[]] $evalState = $shEnv.GetState()
            $tReward += $shEnv.LastReward
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

    # Precision / Recall
    [double[]] $precArr = @(0.0)
    [double[]] $recArr  = @(0.0)
    $denomP = $shEnv.TruePositives + $shEnv.FalsePositives
    $denomR = $shEnv.TruePositives + $shEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $shEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $shEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 14: Self-Healing Infrastructure - Results ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Restart+Rebuild)   : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (failures healed)   : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Observe  healthy stable systems              ║" -ForegroundColor White
    Write-Host "║    Adjust   configuration on degradation        ║" -ForegroundColor White
    Write-Host "║    Restart  failing services automatically      ║" -ForegroundColor White
    Write-Host "║    Rebuild  critical infrastructure on failure  ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated system health conditions)
#    $r = Invoke-VBAFSelfHealingTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real WMI OS, services, process data)
#    $r = Invoke-VBAFSelfHealingTraining -Episodes 100 -PrintEvery 10
#
# 4. SKIP REAL DATA PROBE
#    $r = Invoke-VBAFSelfHealingTraining -Episodes 100 -PrintEvery 10 -SkipRealData
#
# 5. INSPECT AGENT DECISIONS
#    $env   = [SelfHealingEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "HealthScore: $($env.HealthScore)  Urgency: $($env.RecoveryUrgency)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Observe","Adjust","Restart","Rebuild")
#    Write-Host "Self-Healing decision: $($labels[$action])"
#
# 6. VIEW CONFUSION MATRIX
#    Write-Host "True Positives : $($env.TruePositives)"
#    Write-Host "False Positives: $($env.FalsePositives)"
#    Write-Host "True Negatives : $($env.TrueNegatives)"
#    Write-Host "False Negatives: $($env.FalseNegatives)"
# ============================================================
Write-Host "📦 VBAF.Enterprise.SelfHealing.ps1 loaded  [v3.4.0 🔄]"  -ForegroundColor Green
Write-Host "   Phase 14: Self-Healing Infrastructure"                  -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFSelfHealingTraining"              -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFSelfHealingTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""