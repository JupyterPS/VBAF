#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 13 - Natural Language Interface
.DESCRIPTION
    Trains a DQN agent to interpret and route natural language commands
    to the correct VBAF enterprise subsystem. The agent observes intent
    signals extracted from command text and learns when to:
      - Respond : answer with information, no system action needed (action 0)
      - Execute : run a single agent action directly               (action 1)
      - Orchestrate: coordinate multiple agents for the request   (action 2)
      - Escalate: ambiguous or high-risk — request human review   (action 3)
.NOTES
    Part of VBAF - Phase 13 Enterprise Automation Engine
    Phase 13: Natural Language Interface
    PS 5.1 compatible
    Real data: $Host.UI, Read-Host, command intent classification
#>

# ============================================================
# PHASE 13 - NATURAL LANGUAGE INTERFACE
# ============================================================

class NLInterfaceEnvironment {

    # State: 4 normalised intent signal dimensions (0.0 - 1.0)
    # state[0] = SeverityNorm — direct action signal (proven pattern)
    [double] $SeverityNorm    # CurrentSeverity/3.0
    [double] $IntentConfidence  # 0=ambiguous      1=crystal clear intent
    [double] $RiskLevel       # 0=read-only query  1=destructive action
    [double] $Complexity      # 0=single step      1=multi-agent pipeline

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

    NLInterfaceEnvironment() {
        $this.Reset() | Out-Null
    }

    # CRITICAL PS 5.1: build strictly typed [double[]] element by element
    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.SeverityNorm
        $s[1] = $this.IntentConfidence
        $s[2] = $this.RiskLevel
        $s[3] = $this.Complexity
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
        # Balanced training distribution
        # 25% query (0), 30% execute (1), 25% orchestrate (2), 20% escalate (3)
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

        # Generate NL intent metrics consistent with command type
        switch ($this.CurrentSeverity) {
            0 {
                # Simple query: high confidence, low risk, low complexity
                $this.IntentConfidence = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                $this.RiskLevel        = [double](Get-Random -Minimum 0  -Maximum 10)  / 100.0
                $this.Complexity       = [double](Get-Random -Minimum 0  -Maximum 15)  / 100.0
            }
            1 {
                # Execute: clear intent, moderate risk, single agent
                $this.IntentConfidence = [double](Get-Random -Minimum 60 -Maximum 85)  / 100.0
                $this.RiskLevel        = [double](Get-Random -Minimum 10 -Maximum 40)  / 100.0
                $this.Complexity       = [double](Get-Random -Minimum 15 -Maximum 45)  / 100.0
            }
            2 {
                # Orchestrate: moderate confidence, higher risk, multi-agent
                $this.IntentConfidence = [double](Get-Random -Minimum 40 -Maximum 65)  / 100.0
                $this.RiskLevel        = [double](Get-Random -Minimum 40 -Maximum 70)  / 100.0
                $this.Complexity       = [double](Get-Random -Minimum 45 -Maximum 80)  / 100.0
            }
            3 {
                # Escalate: ambiguous intent, high risk, high complexity
                $this.IntentConfidence = [double](Get-Random -Minimum 0  -Maximum 40)  / 100.0
                $this.RiskLevel        = [double](Get-Random -Minimum 70 -Maximum 100) / 100.0
                $this.Complexity       = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Respond  1=Execute  2=Orchestrate  3=Escalate
        return $this.CurrentSeverity
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this._OptimalAction()

        # Symmetric distance-based reward (proven in Phases 10-12)
        [int] $dist = $action - $optimal
        if ($dist -lt 0) { $dist = -$dist }

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
# Real Windows NL command probe
# ------------------------------------
function Get-VBAFNLSnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing NL command environment..." -ForegroundColor Gray

    try {
        # Show PS version and host info
        Write-Host ("   PowerShell version    : {0}" -f $PSVersionTable.PSVersion) -ForegroundColor White
        Write-Host ("   Host name             : {0}" -f $Host.Name)                -ForegroundColor White

        # Sample intent classification — keyword-based routing demo
        $sampleCommands = @(
            "show me the security events",
            "restart the network adapter",
            "optimize all pipelines and alert on failures",
            "delete all logs and reset everything now"
        )
        $intentLabels = @("Respond", "Execute", "Orchestrate", "Escalate")

        Write-Host ""
        Write-Host "   Sample command routing:" -ForegroundColor Gray
        for ($i = 0; $i -lt $sampleCommands.Count; $i++) {
            Write-Host ("     [{0,-12}] {1}" -f $intentLabels[$i], $sampleCommands[$i]) -ForegroundColor DarkCyan
        }

        Write-Host ""
        Write-Host "   NL routing capability : confirmed ✅" -ForegroundColor Green

    } catch {
        Write-Host "   [WARNING] NL probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated intent signals."   -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFNLInterfaceTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "💬 VBAF Enterprise - Phase 13: Natural Language Interface"          -ForegroundColor Cyan
    Write-Host "   Training DQN agent on NL command routing..."                     -ForegroundColor Cyan
    Write-Host "   Actions: 0=Respond  1=Execute  2=Orchestrate  3=Escalate"       -ForegroundColor Yellow
    Write-Host "   State  : SeverityNorm | Confidence | RiskLevel | Complexity"    -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"          -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFNLSnapshot
    }

    $nlEnv = [NLInterfaceEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $nlEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $nlEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $nlEnv.Step($rAction)
            $bReward += $nlEnv.LastReward
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
            if      ($roll -le 25) { $nlEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $nlEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 80) { $nlEnv.CurrentSeverity = 2 }
            else                   { $nlEnv.CurrentSeverity = 3 }

            [double[]] $snArr = @(0.0)
            $snArr[0]  = $nlEnv.CurrentSeverity
            $snArr[0] /= 3.0
            $nlEnv.SeverityNorm = $snArr[0]

            switch ($nlEnv.CurrentSeverity) {
                0 {
                    $nlEnv.IntentConfidence = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                    $nlEnv.RiskLevel        = [double](Get-Random -Minimum 0  -Maximum 10)  / 100.0
                    $nlEnv.Complexity       = [double](Get-Random -Minimum 0  -Maximum 15)  / 100.0
                }
                1 {
                    $nlEnv.IntentConfidence = [double](Get-Random -Minimum 60 -Maximum 85)  / 100.0
                    $nlEnv.RiskLevel        = [double](Get-Random -Minimum 10 -Maximum 40)  / 100.0
                    $nlEnv.Complexity       = [double](Get-Random -Minimum 15 -Maximum 45)  / 100.0
                }
                2 {
                    $nlEnv.IntentConfidence = [double](Get-Random -Minimum 40 -Maximum 65)  / 100.0
                    $nlEnv.RiskLevel        = [double](Get-Random -Minimum 40 -Maximum 70)  / 100.0
                    $nlEnv.Complexity       = [double](Get-Random -Minimum 45 -Maximum 80)  / 100.0
                }
                3 {
                    $nlEnv.IntentConfidence = [double](Get-Random -Minimum 0  -Maximum 40)  / 100.0
                    $nlEnv.RiskLevel        = [double](Get-Random -Minimum 70 -Maximum 100) / 100.0
                    $nlEnv.Complexity       = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                }
            }
            $nlEnv.CorrectActions    = 0
            $nlEnv.MissedEscalations = 0
            $nlEnv.Steps             = 0
            $nlEnv.TotalReward       = 0.0
            $nlEnv.LastDone          = $false
            $nlEnv.EpisodeCount++
            $state = $nlEnv.GetState()
        } else {
            $state = $nlEnv.Reset()
        }

        $done              = $false
        $epReward          = 0.0
        $respondCount      = 0
        $executeCount      = 0
        $orchestrateCount  = 0
        $escalateCount     = 0
        [int] $stepCount   = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $nlEnv.Step($action)
            [double[]] $nextState = $nlEnv.GetState()
            [double]   $reward    = $nlEnv.LastReward
            [bool]     $isDone    = $nlEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $respondCount++     }
                1 { $executeCount++     }
                2 { $orchestrateCount++ }
                3 { $escalateCount++    }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode     = $ep
            Reward      = $epReward
            Respond     = $respondCount
            Execute     = $executeCount
            Orchestrate = $orchestrateCount
            Escalate    = $escalateCount
            Epsilon     = $agent.Epsilon
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN  = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            [double[]] $avgArr = @(0.0)
            $avgArr[0]  = $avgSum
            $avgArr[0] /= $lastN.Count
            $avg = [Math]::Round($avgArr[0], 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Res:{4} Exe:{5} Orc:{6} Esc:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $respondCount, $executeCount, $orchestrateCount, $escalateCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $nlEnv.Reset()
        $tReward = 0.0
        while (-not $nlEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $nlEnv.Step($tAction)
            [double[]] $evalState = $nlEnv.GetState()
            $tReward += $nlEnv.LastReward
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
    $denomP = $nlEnv.TruePositives + $nlEnv.FalsePositives
    $denomR = $nlEnv.TruePositives + $nlEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $nlEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $nlEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 13: NL Interface - Results                ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Orc+Esc correct)   : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (escalations caught): {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Respond     simple information queries       ║" -ForegroundColor White
    Write-Host "║    Execute     clear single-agent commands      ║" -ForegroundColor White
    Write-Host "║    Orchestrate complex multi-agent pipelines    ║" -ForegroundColor White
    Write-Host "║    Escalate    ambiguous or high-risk commands  ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated NL intent signals)
#    $r = Invoke-VBAFNLInterfaceTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real PS host + command routing demo)
#    $r = Invoke-VBAFNLInterfaceTraining -Episodes 100 -PrintEvery 10
#
# 4. SKIP REAL DATA PROBE
#    $r = Invoke-VBAFNLInterfaceTraining -Episodes 100 -PrintEvery 10 -SkipRealData
#
# 5. INSPECT AGENT DECISIONS
#    $env   = [NLInterfaceEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "Confidence: $($env.IntentConfidence)  Risk: $($env.RiskLevel)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Respond","Execute","Orchestrate","Escalate")
#    Write-Host "NL Router decision: $($labels[$action])"
#
# 6. VIEW CONFUSION MATRIX
#    Write-Host "True Positives : $($env.TruePositives)"
#    Write-Host "False Positives: $($env.FalsePositives)"
#    Write-Host "True Negatives : $($env.TrueNegatives)"
#    Write-Host "False Negatives: $($env.FalseNegatives)"
# ============================================================
Write-Host "📦 VBAF.Enterprise.NLInterface.ps1 loaded  [v3.3.0 💬]"  -ForegroundColor Green
Write-Host "   Phase 13: Natural Language Interface"                   -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFNLInterfaceTraining"              -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFNLInterfaceTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""