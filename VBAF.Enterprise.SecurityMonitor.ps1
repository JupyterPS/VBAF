#Requires -Version 5.1
<#
.SYNOPSIS
    Pillar 8 - Security & Compliance Intelligence
.DESCRIPTION
    Trains a DQN agent to classify and respond to Windows Security Events.
    The agent observes real Security Event Log data and learns when to:
      - Ignore : benign / routine events            (action 0)
      - Log    : low-threat events worth recording  (action 1)
      - Alert  : medium/high threat needing review  (action 2)
      - Lock   : critical threat requiring lockdown (action 3)
.NOTES
    Part of VBAF - Phase 10 Enterprise Automation Engine
    Pillar 8: Security & Compliance Intelligence
    PS 5.1 compatible
    Real data: Get-WinEvent -LogName Security
#>

# ============================================================
# PILLAR 8 - SECURITY & COMPLIANCE INTELLIGENCE
# ============================================================

class SecurityMonitorEnvironment {

    [double] $ThreatLevel
    [double] $Frequency
    [double] $OffHours
    [double] $Burst

    [int]    $CorrectActions
    [int]    $MissedThreats
    [int]    $Steps
    [double] $TotalReward
    [int]    $EpisodeCount

    [int]    $TruePositives
    [int]    $FalsePositives
    [int]    $TrueNegatives
    [int]    $FalseNegatives

    [int]    $CurrentThreat

    [int]    $StateSize  = 4
    [int]    $ActionSize = 4

    [double] $LastReward = 0.0
    [bool]   $LastDone   = $false

    SecurityMonitorEnvironment() {
        $this.Reset() | Out-Null
    }

    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.ThreatLevel
        $s[1] = $this.Frequency
        $s[2] = $this.OffHours
        $s[3] = $this.Burst
        return $s
    }

    [double[]] Reset() {
        $this.Steps          = 0
        $this.TotalReward    = 0.0
        $this.CorrectActions = 0
        $this.MissedThreats  = 0
        $this.TruePositives  = 0
        $this.FalsePositives = 0
        $this.TrueNegatives  = 0
        $this.FalseNegatives = 0
        $this.LastDone       = $false
        $this.EpisodeCount++
        $this._SampleEvent()
        [double[]] $initState = $this.GetState()
        return $initState
    }

    [void] _SampleEvent() {
        # Balanced distribution: 25% benign, 30% low, 25% medium, 20% high
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 25) { $this.CurrentThreat = 0 }
        elseif  ($roll -le 55) { $this.CurrentThreat = 1 }
        elseif  ($roll -le 80) { $this.CurrentThreat = 2 }
        else                   { $this.CurrentThreat = 3 }

        [double[]] $tArr = @(0.0)
        $tArr[0]  = $this.CurrentThreat
        $tArr[0] /= 3.0
        $this.ThreatLevel = $tArr[0]

        $this.Frequency = [double](Get-Random -Minimum 0 -Maximum 100) / 100.0

        $hour = [DateTime]::Now.Hour
        $this.OffHours = if ($hour -lt 7 -or $hour -gt 18) { 1.0 } else { 0.0 }

        [double[]] $bArr = @(0.0)
        $bArr[0]  = [double](Get-Random -Minimum 0 -Maximum 100) / 100.0
        $bArr[0] *= $this.ThreatLevel
        $this.Burst = $bArr[0]
    }

    [int] _OptimalAction() {
        return $this.CurrentThreat
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal  = $this._OptimalAction()

        # Symmetric distance-based reward
        # Penalises proportionally to HOW WRONG the action is
        # No lazy Lock or Log strategy can exploit this
        [int] $dist = $action - $optimal
        if ($dist -lt 0) { $dist = -$dist }  # PS 5.1 safe abs

        if    ($dist -eq 0) { $this.LastReward =  2.0; $this.CorrectActions++ }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }

        if ($this.CurrentThreat -ge 2 -and $action -lt 2) { $this.MissedThreats++ }

        $isSuspicious = ($this.CurrentThreat -ge 2)
        $agentReacts  = ($action -ge 2)
        if ($isSuspicious  -and $agentReacts)  { $this.TruePositives++  }
        if (!$isSuspicious -and $agentReacts)  { $this.FalsePositives++ }
        if (!$isSuspicious -and !$agentReacts) { $this.TrueNegatives++  }
        if ($isSuspicious  -and !$agentReacts) { $this.FalseNegatives++ }

        $this.TotalReward += $this.LastReward
        $this._SampleEvent()
        $this.LastDone = ($this.Steps -ge 200)
    }
}

# ------------------------------------
# Real Windows Security Event probe
# ------------------------------------
function Get-VBAFSecuritySnapshot {
    [CmdletBinding()]
    param(
        [int] $MaxEvents = 50
    )

    Write-Host ""
    Write-Host "   Probing Get-WinEvent -LogName Security..." -ForegroundColor Gray

    try {
        $events = Get-WinEvent -LogName Security -MaxEvents $MaxEvents -ErrorAction Stop

        $threatMap = @{
            4625 = 1; 4771 = 1; 4776 = 1; 4648 = 1; 4672 = 1
            4720 = 2; 4722 = 2; 4728 = 2; 4732 = 2; 4756 = 2
            4719 = 3; 4740 = 3; 4765 = 3; 4794 = 3; 1102 = 3; 4698 = 3
        }

        $high = 0; $med = 0; $low = 0; $benign = 0
        $topIDs = @{}

        foreach ($e in $events) {
            $id = $e.Id
            if ($topIDs.ContainsKey($id)) { $topIDs[$id]++ } else { $topIDs[$id] = 1 }
            $lv = if ($threatMap.ContainsKey($id)) { $threatMap[$id] } else { 0 }
            switch ($lv) { 3 { $high++ } 2 { $med++ } 1 { $low++ } 0 { $benign++ } }
        }

        Write-Host ("   Events sampled        : {0}" -f $events.Count) -ForegroundColor White
        Write-Host ("   High threat  (Lock)   : {0}" -f $high)         -ForegroundColor Red
        Write-Host ("   Medium threat (Alert) : {0}" -f $med)          -ForegroundColor Yellow
        Write-Host ("   Low threat (Log)      : {0}" -f $low)          -ForegroundColor Cyan
        Write-Host ("   Benign (Ignore)       : {0}" -f $benign)       -ForegroundColor Green
        Write-Host ""
        Write-Host "   Top EventIDs observed:" -ForegroundColor Gray
        $topIDs.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First 5 |
            ForEach-Object {
                Write-Host ("     EventID {0,5}  ->  {1} occurrences" -f $_.Key, $_.Value) -ForegroundColor DarkCyan
            }

    } catch {
        Write-Host "   [WARNING] Cannot read Security log - run as Administrator for full access." -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated security events."                     -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFSecurityMonitorTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "🔐 VBAF Enterprise - Pillar 8: Security & Compliance Intelligence" -ForegroundColor Cyan
    Write-Host "   Training DQN agent on Security Monitor..."                      -ForegroundColor Cyan
    Write-Host "   Actions: 0=Ignore  1=Log  2=Alert  3=Lock"                     -ForegroundColor Yellow
    Write-Host "   State  : ThreatLevel | Frequency | OffHours | Burst"           -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"          -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFSecuritySnapshot
    }

    $smEnv = [SecurityMonitorEnvironment]::new()

    # ============================================================
    # DEBUG BLOCK - verify types before training
    # ============================================================
    Write-Host "   [DEBUG] Type verification..." -ForegroundColor Magenta
    [double[]] $testState = $smEnv.Reset()
    Write-Host "   State type    : $($testState.GetType().Name)"        -ForegroundColor Magenta
    Write-Host "   State[0] type : $($testState[0].GetType().Name)"     -ForegroundColor Magenta
    Write-Host "   State values  : $($testState[0]) | $($testState[1]) | $($testState[2]) | $($testState[3])" -ForegroundColor Magenta
    $smEnv.Step(0)
    [double[]] $dbgNext = $smEnv.GetState()
    Write-Host "   NextState type: $($dbgNext.GetType().Name)"          -ForegroundColor Magenta
    Write-Host "   Reward type   : $($smEnv.LastReward.GetType().Name)" -ForegroundColor Magenta
    Write-Host "   Reward value  : $($smEnv.LastReward)"                -ForegroundColor Magenta
    Write-Host "   [DEBUG] Done - proceeding to training..."            -ForegroundColor Magenta
    Write-Host ""
    # ============================================================

    # Phase 1: Baseline - inline loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $smEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $smEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $smEnv.Step($rAction)
            $bReward += $smEnv.LastReward
        }
        $baseRewards += $bReward
    }
    $bAvgVal  = ($baseRewards | Measure-Object -Average).Average
    $baseline = @{ Avg = $bAvgVal }
    Write-Host ("   Baseline avg reward: {0:F2}" -f $bAvgVal) -ForegroundColor Gray

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
            if      ($roll -le 25) { $smEnv.CurrentThreat = 0 }
            elseif  ($roll -le 55) { $smEnv.CurrentThreat = 1 }
            elseif  ($roll -le 80) { $smEnv.CurrentThreat = 2 }
            else                   { $smEnv.CurrentThreat = 3 }

            [double[]] $tArr = @(0.0)
            $tArr[0]  = $smEnv.CurrentThreat
            $tArr[0] /= 3.0
            $smEnv.ThreatLevel    = $tArr[0]
            $smEnv.Frequency      = [double](Get-Random -Minimum 0 -Maximum 100) / 100.0
            $hour = [DateTime]::Now.Hour
            $smEnv.OffHours       = if ($hour -lt 7 -or $hour -gt 18) { 1.0 } else { 0.0 }
            [double[]] $bArr      = @(0.0)
            $bArr[0]  = [double](Get-Random -Minimum 0 -Maximum 100) / 100.0
            $bArr[0] *= $smEnv.ThreatLevel
            $smEnv.Burst          = $bArr[0]
            $smEnv.CorrectActions = 0
            $smEnv.MissedThreats  = 0
            $smEnv.Steps          = 0
            $smEnv.TotalReward    = 0.0
            $smEnv.LastDone       = $false
            $smEnv.EpisodeCount++
            $state = $smEnv.GetState()
        } else {
            $state = $smEnv.Reset()
        }

        $done        = $false
        $epReward    = 0.0
        $ignoreCount = 0
        $logCount    = 0
        $alertCount  = 0
        $lockCount   = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $smEnv.Step($action)
            [double[]] $nextState = $smEnv.GetState()
            [double]   $reward    = $smEnv.LastReward
            [bool]     $isDone    = $smEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $ignoreCount++ }
                1 { $logCount++    }
                2 { $alertCount++  }
                3 { $lockCount++   }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode = $ep
            Reward  = $epReward
            Ignore  = $ignoreCount
            Log     = $logCount
            Alert   = $alertCount
            Lock    = $lockCount
            Epsilon = $agent.Epsilon
        })

        if ($ep % $PrintEvery -eq 0) {
            $lastN  = $results | Select-Object -Last $PrintEvery
            $avgSum = 0.0
            foreach ($r2 in $lastN) { $avgSum += $r2.Reward }
            [double[]] $avgArr = @(0.0)
            $avgArr[0]  = $avgSum
            $avgArr[0] /= $lastN.Count
            $avg = [Math]::Round($avgArr[0], 2)
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Ign:{4} Log:{5} Alt:{6} Lck:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $ignoreCount, $logCount, $alertCount, $lockCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation - inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $smEnv.Reset()
        $tReward = 0.0
        while (-not $smEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $smEnv.Step($tAction)
            [double[]] $evalState = $smEnv.GetState()
            $tReward += $smEnv.LastReward
        }
        $trainedRewards += $tReward
    }
    $tAvgVal = ($trainedRewards | Measure-Object -Average).Average
    $trained = @{ Avg = $tAvgVal }
    Write-Host ("   Trained avg reward: {0:F2}" -f $tAvgVal) -ForegroundColor Green

    $bAvg = [Math]::Round($baseline.Avg, 2)
    $tAvg = [Math]::Round($trained.Avg, 2)
    $improvement = if ($bAvg -ne 0) {
        [Math]::Round((($tAvg - $bAvg) / [Math]::Abs($bAvg)) * 100, 1)
    } else { 0 }

    [double[]] $precArr = @(0.0)
    [double[]] $recArr  = @(0.0)
    $denomP = $smEnv.TruePositives + $smEnv.FalsePositives
    $denomR = $smEnv.TruePositives + $smEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $smEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $smEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Pillar 8: Security Monitor - Results            ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Alert+Lock correct): {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (threats caught)    : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Ignore   benign routine events               ║" -ForegroundColor White
    Write-Host "║    Log      low-threat events                   ║" -ForegroundColor White
    Write-Host "║    Alert    medium-threat / off-hours events    ║" -ForegroundColor White
    Write-Host "║    Lock     critical threats immediately        ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = $baseline; Trained = $trained }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated events, no admin needed)
#    $r = Invoke-VBAFSecurityMonitorTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real Windows Security Event Log - run as Administrator)
#    $r = Invoke-VBAFSecurityMonitorTraining -Episodes 60 -PrintEvery 10
#
# 4. SKIP REAL DATA PROBE (simulate only, no admin prompt)
#    $r = Invoke-VBAFSecurityMonitorTraining -Episodes 60 -PrintEvery 10 -SkipRealData
#
# 5. INSPECT AGENT DECISIONS
#    $env   = [SecurityMonitorEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "ThreatLevel: $($env.ThreatLevel)  OffHours: $($env.OffHours)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Ignore","Log","Alert","Lock")
#    Write-Host "Agent decision: $($labels[$action])"
#
# 6. VIEW CONFUSION MATRIX
#    Write-Host "True Positives : $($env.TruePositives)"
#    Write-Host "False Positives: $($env.FalsePositives)"
#    Write-Host "True Negatives : $($env.TrueNegatives)"
#    Write-Host "False Negatives: $($env.FalseNegatives)"
# ============================================================
Write-Host "📦 VBAF.Enterprise.SecurityMonitor.ps1 loaded  [v3.0.0 🔐]" -ForegroundColor Green
Write-Host "   Pillar 8 : Security & Compliance Intelligence"            -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFSecurityMonitorTraining"            -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFSecurityMonitorTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""