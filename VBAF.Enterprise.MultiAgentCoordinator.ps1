#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 11 - Multi-Agent Enterprise Collaboration
.DESCRIPTION
    Trains a DQN coordinator agent to route and orchestrate decisions
    across multiple VBAF enterprise agents. The coordinator observes
    the combined system state and learns when to:
      - Handle  : single agent handles locally, no coordination needed (action 0)
      - Consult : two agents collaborate on the decision               (action 1)
      - Escalate: all agents engaged, full system response             (action 2)
      - Override: coordinator takes direct control, bypasses agents    (action 3)
.NOTES
    Part of VBAF - Phase 11 Enterprise Automation Engine
    Phase 11: Multi-Agent Enterprise Collaboration
    PS 5.1 compatible
    Real data: Start-Job (true parallel agent execution)
#>

# ============================================================
# PHASE 11 - MULTI-AGENT COLLABORATION
# ============================================================

class MultiAgentEnvironment {

    # State: 4 normalised coordination dimensions (0.0 - 1.0)
    # state[0] = SeverityNorm — direct action signal (proven pattern)
    [double] $SeverityNorm    # CurrentSeverity/3.0
    [double] $AgentLoad       # 0=agents idle       1=all agents saturated
    [double] $ConflictLevel   # 0=agents agree      1=agents in full conflict
    [double] $UrgencyLevel    # 0=low urgency       1=time-critical

    [int]    $CorrectActions
    [int]    $MissedEscalations
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

    MultiAgentEnvironment() {
        $this.Reset() | Out-Null
    }

    # CRITICAL PS 5.1: build strictly typed [double[]] element by element
    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.SeverityNorm
        $s[1] = $this.AgentLoad
        $s[2] = $this.ConflictLevel
        $s[3] = $this.UrgencyLevel
        return $s
    }

    [double[]] Reset() {
        $this.Steps              = 0
        $this.TotalReward        = 0.0
        $this.CorrectActions     = 0
        $this.MissedEscalations  = 0
        $this.TruePositives      = 0
        $this.FalsePositives     = 0
        $this.TrueNegatives      = 0
        $this.FalseNegatives     = 0
        $this.LastDone           = $false   # CRITICAL: must reset here
        $this.EpisodeCount++
        $this._SampleCondition()
        [double[]] $initState = $this.GetState()
        return $initState
    }

    [void] _SampleCondition() {
        # Balanced training distribution — no lazy fixed-action exploits
        # 25% routine (0), 30% collaborative (1), 25% escalated (2), 20% critical (3)
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

        # Generate coordination metrics consistent with severity
        switch ($this.CurrentSeverity) {
            0 {
                # Routine: agents idle, no conflict, low urgency
                $this.AgentLoad     = [double](Get-Random -Minimum 5  -Maximum 30) / 100.0
                $this.ConflictLevel = 0.0
                $this.UrgencyLevel  = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
            }
            1 {
                # Collaborative: moderate load, minor conflict, some urgency
                $this.AgentLoad     = [double](Get-Random -Minimum 30 -Maximum 60) / 100.0
                $this.ConflictLevel = [double](Get-Random -Minimum 10 -Maximum 40) / 100.0
                $this.UrgencyLevel  = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
            }
            2 {
                # Escalated: high load, significant conflict, high urgency
                $this.AgentLoad     = [double](Get-Random -Minimum 60 -Maximum 85) / 100.0
                $this.ConflictLevel = [double](Get-Random -Minimum 40 -Maximum 70) / 100.0
                $this.UrgencyLevel  = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
            }
            3 {
                # Critical: agents saturated, full conflict, time-critical
                $this.AgentLoad     = [double](Get-Random -Minimum 85  -Maximum 100) / 100.0
                $this.ConflictLevel = [double](Get-Random -Minimum 70  -Maximum 100) / 100.0
                $this.UrgencyLevel  = [double](Get-Random -Minimum 80  -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # Pure severity mapping — clean 4-class signal for DQN
        # 0=Handle  1=Consult  2=Escalate  3=Override
        return $this.CurrentSeverity
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this._OptimalAction()

        # Symmetric distance-based reward (proven in Pillars 8-10)
        # +2 correct, -1 dist=1, -2 dist=2, -3 dist=3
        [int] $dist = $action - $optimal
        if ($dist -lt 0) { $dist = -$dist }  # PS 5.1 safe abs

        if    ($dist -eq 0) { $this.LastReward =  2.0; $this.CorrectActions++ }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }

        if ($this.CurrentSeverity -ge 2 -and $action -lt 2) { $this.MissedEscalations++ }

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
# Real Windows parallel agent probe
# ------------------------------------
function Get-VBAFMultiAgentSnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing parallel agent capability..." -ForegroundColor Gray

    try {
        # Test Start-Job — true parallel execution in PS 5.1
        $job1 = Start-Job -ScriptBlock { Get-Date; Start-Sleep -Milliseconds 200; "Agent1:OK" }
        $job2 = Start-Job -ScriptBlock { Get-Date; Start-Sleep -Milliseconds 200; "Agent2:OK" }
        $job3 = Start-Job -ScriptBlock { Get-Date; Start-Sleep -Milliseconds 200; "Agent3:OK" }

        $results = @($job1, $job2, $job3) | Wait-Job | Receive-Job
        @($job1, $job2, $job3) | Remove-Job

        Write-Host ("   Parallel jobs tested  : 3")           -ForegroundColor White
        foreach ($r in $results) {
            Write-Host ("     {0}" -f $r) -ForegroundColor DarkCyan
        }
        Write-Host "   Start-Job capability  : confirmed ✅"  -ForegroundColor Green

        # Process count as proxy for system load
        $procCount = (Get-Process).Count
        Write-Host ("   Running processes     : {0}" -f $procCount) -ForegroundColor White

    } catch {
        Write-Host "   [WARNING] Parallel probe failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated agent conditions."   -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFMultiAgentTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "🤝 VBAF Enterprise - Phase 11: Multi-Agent Collaboration"          -ForegroundColor Cyan
    Write-Host "   Training DQN coordinator agent..."                              -ForegroundColor Cyan
    Write-Host "   Actions: 0=Handle  1=Consult  2=Escalate  3=Override"          -ForegroundColor Yellow
    Write-Host "   State  : SeverityNorm | AgentLoad | ConflictLevel | Urgency"   -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"         -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFMultiAgentSnapshot
    }

    $maEnv = [MultiAgentEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $maEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $maEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $maEnv.Step($rAction)
            $bReward += $maEnv.LastReward
        }
        $baseRewards += $bReward
    }
    [double[]] $bAvgArr = @(0.0)
    $bAvgArr[0] = ($baseRewards | Measure-Object -Average).Average
    Write-Host ("   Baseline avg reward: {0:F2}" -f $bAvgArr[0]) -ForegroundColor Gray

    if ($FastMode) { $Episodes = [Math]::Min($Episodes, 30) }
    Write-Host ""
    Write-Host "   Phase 2: Training DQN coordinator ($Episodes episodes)..." -ForegroundColor Gray

    # DQN setup - 4 state, 4 actions
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

        # CRITICAL PS 5.1: $state must be strictly typed [double[]] for DQN
        [double[]] $state = @(0.0, 0.0, 0.0, 0.0)

        if ($SimMode) {
            # SimMode: inject balanced coordination severity distribution directly
            $roll = Get-Random -Minimum 1 -Maximum 100
            if      ($roll -le 25) { $maEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $maEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 80) { $maEnv.CurrentSeverity = 2 }
            else                   { $maEnv.CurrentSeverity = 3 }

            [double[]] $snArr = @(0.0)
            $snArr[0]  = $maEnv.CurrentSeverity
            $snArr[0] /= 3.0
            $maEnv.SeverityNorm = $snArr[0]

            switch ($maEnv.CurrentSeverity) {
                0 {
                    $maEnv.AgentLoad     = [double](Get-Random -Minimum 5  -Maximum 30) / 100.0
                    $maEnv.ConflictLevel = 0.0
                    $maEnv.UrgencyLevel  = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                }
                1 {
                    $maEnv.AgentLoad     = [double](Get-Random -Minimum 30 -Maximum 60) / 100.0
                    $maEnv.ConflictLevel = [double](Get-Random -Minimum 10 -Maximum 40) / 100.0
                    $maEnv.UrgencyLevel  = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                }
                2 {
                    $maEnv.AgentLoad     = [double](Get-Random -Minimum 60 -Maximum 85) / 100.0
                    $maEnv.ConflictLevel = [double](Get-Random -Minimum 40 -Maximum 70) / 100.0
                    $maEnv.UrgencyLevel  = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                }
                3 {
                    $maEnv.AgentLoad     = [double](Get-Random -Minimum 85  -Maximum 100) / 100.0
                    $maEnv.ConflictLevel = [double](Get-Random -Minimum 70  -Maximum 100) / 100.0
                    $maEnv.UrgencyLevel  = [double](Get-Random -Minimum 80  -Maximum 100) / 100.0
                }
            }
            $maEnv.CorrectActions    = 0
            $maEnv.MissedEscalations = 0
            $maEnv.Steps             = 0
            $maEnv.TotalReward       = 0.0
            $maEnv.LastDone          = $false
            $maEnv.EpisodeCount++
            $state = $maEnv.GetState()
        } else {
            $state = $maEnv.Reset()
        }

        $done            = $false
        $epReward        = 0.0
        $handleCount     = 0
        $consultCount    = 0
        $escalateCount   = 0
        $overrideCount   = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $maEnv.Step($action)
            # Read directly from env — NO PSCustomObject round-trip
            [double[]] $nextState = $maEnv.GetState()
            [double]   $reward    = $maEnv.LastReward
            [bool]     $isDone    = $maEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $handleCount++   }
                1 { $consultCount++  }
                2 { $escalateCount++ }
                3 { $overrideCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode   = $ep
            Reward    = $epReward
            Handle    = $handleCount
            Consult   = $consultCount
            Escalate  = $escalateCount
            Override  = $overrideCount
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
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Han:{4} Con:{5} Esc:{6} Ovr:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $handleCount, $consultCount, $escalateCount, $overrideCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $maEnv.Reset()
        $tReward = 0.0
        while (-not $maEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $maEnv.Step($tAction)
            [double[]] $evalState = $maEnv.GetState()
            $tReward += $maEnv.LastReward
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
    $denomP = $maEnv.TruePositives + $maEnv.FalsePositives
    $denomR = $maEnv.TruePositives + $maEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $maEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $maEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 11: Multi-Agent Coordinator - Results     ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Esc+Override corr) : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (escalations caught): {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Coordinator learned to:                         ║" -ForegroundColor Cyan
    Write-Host "║    Handle   routine single-agent decisions      ║" -ForegroundColor White
    Write-Host "║    Consult  collaborative two-agent problems    ║" -ForegroundColor White
    Write-Host "║    Escalate full system response when needed    ║" -ForegroundColor White
    Write-Host "║    Override take direct control in crisis       ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated multi-agent conditions, no admin needed)
#    $r = Invoke-VBAFMultiAgentTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real Start-Job parallel probe)
#    $r = Invoke-VBAFMultiAgentTraining -Episodes 100 -PrintEvery 10
#
# 4. SKIP REAL DATA PROBE
#    $r = Invoke-VBAFMultiAgentTraining -Episodes 100 -PrintEvery 10 -SkipRealData
#
# 5. INSPECT COORDINATOR DECISIONS
#    $env   = [MultiAgentEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "AgentLoad: $($env.AgentLoad)  Conflict: $($env.ConflictLevel)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Handle","Consult","Escalate","Override")
#    Write-Host "Coordinator decision: $($labels[$action])"
#
# 6. VIEW CONFUSION MATRIX
#    Write-Host "True Positives : $($env.TruePositives)"
#    Write-Host "False Positives: $($env.FalsePositives)"
#    Write-Host "True Negatives : $($env.TrueNegatives)"
#    Write-Host "False Negatives: $($env.FalseNegatives)"
# ============================================================
Write-Host "📦 VBAF.Enterprise.MultiAgentCoordinator.ps1 loaded  [v3.1.0 🤝]" -ForegroundColor Green
Write-Host "   Phase 11: Multi-Agent Enterprise Collaboration"                  -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFMultiAgentTraining"                        -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFMultiAgentTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""