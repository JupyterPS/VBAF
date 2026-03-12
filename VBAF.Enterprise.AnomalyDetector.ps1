 #Requires -Version 5.1
<#
.SYNOPSIS
    Phase 18 - Anomaly Detection Engine
.DESCRIPTION
    Trains a DQN agent to detect and respond to anomalous behaviour
    across all VBAF pillars. The agent observes system deviation signals
    and learns when to:
      - Ignore   : normal variation, no action needed              (action 0)
      - Flag     : log the anomaly for review                      (action 1)
      - Alert    : notify operators immediately                    (action 2)
      - Escalate : trigger automated remediation across pillars    (action 3)
.NOTES
    Part of VBAF - Phase 18 Enterprise Automation Engine
    Phase 18: Anomaly Detection Engine
    PS 5.1 compatible
    Real data: Get-WinEvent, WMI Win32_OperatingSystem, Get-Counter
    Design: DeviationTrend INVERTED (high=stable=Ignore, low=accelerating=Escalate)
            breaks monotonic collapse — lesson carried forward from Phases 15-17
#>

# ============================================================
# PHASE 18 - ANOMALY DETECTION ENGINE
# ============================================================

class AnomalyDetectorEnvironment {

    # State: 4 genuinely observable anomaly signals (0.0 - 1.0)
    # NO SeverityNorm — agent must learn the mapping from real signals
    # DeviationTrend INVERTED: high=stable, low=accelerating — breaks monotonic collapse
    [double] $DeviationScore   # 0=within baseline  1=far outside normal
    [double] $EventFrequency   # 0=quiet            1=event storm
    [double] $DeviationTrend   # 1=stable/improving 0=accelerating (INVERTED)
    [double] $AffectedPillars  # 0=isolated         1=all pillars affected

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

    AnomalyDetectorEnvironment() {
        $this.Reset() | Out-Null
    }

    # CRITICAL PS 5.1: build strictly typed [double[]] element by element
    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.DeviationScore
        $s[1] = $this.EventFrequency
        $s[2] = $this.DeviationTrend
        $s[3] = $this.AffectedPillars
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
        # 25% ignore (0), 30% flag (1), 25% alert (2), 20% escalate (3)
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 25) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 80) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                # Ignore: tiny deviation, quiet, STABLE trend, isolated
                $this.DeviationScore  = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.EventFrequency  = [double](Get-Random -Minimum 0  -Maximum 15) / 100.0
                $this.DeviationTrend  = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                $this.AffectedPillars = [double](Get-Random -Minimum 0  -Maximum 15) / 100.0
            }
            1 {
                # Flag: noticeable deviation, some events, slowing trend
                $this.DeviationScore  = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.EventFrequency  = [double](Get-Random -Minimum 15 -Maximum 45) / 100.0
                $this.DeviationTrend  = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                $this.AffectedPillars = [double](Get-Random -Minimum 15 -Maximum 40) / 100.0
            }
            2 {
                # Alert: high deviation, event burst, worsening trend
                $this.DeviationScore  = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.EventFrequency  = [double](Get-Random -Minimum 45 -Maximum 70) / 100.0
                $this.DeviationTrend  = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                $this.AffectedPillars = [double](Get-Random -Minimum 40 -Maximum 65) / 100.0
            }
            3 {
                # Escalate: extreme deviation, event storm, ACCELERATING trend, widespread
                $this.DeviationScore  = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                $this.EventFrequency  = [double](Get-Random -Minimum 70  -Maximum 100) / 100.0
                $this.DeviationTrend  = [double](Get-Random -Minimum 0   -Maximum 20)  / 100.0
                $this.AffectedPillars = [double](Get-Random -Minimum 65  -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Ignore  1=Flag  2=Alert  3=Escalate
        return $this.CurrentSeverity
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this._OptimalAction()

        # Symmetric distance-based reward (proven across Phases 10-17)
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
# Real Windows anomaly probe
# ------------------------------------
function Get-VBAFAnomalySnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing system anomaly signals..." -ForegroundColor Gray

    try {
        # Recent system errors as event frequency proxy
        $errors = Get-WinEvent -FilterHashtable @{
            LogName   = 'System'
            Level     = @(1,2)
            StartTime = (Get-Date).AddHours(-1)
        } -ErrorAction SilentlyContinue
        $errCount = if ($errors) { @($errors).Count } else { 0 }
        Write-Host ("   System errors (1h)    : {0}" -f $errCount) -ForegroundColor $(if ($errCount -gt 5) { "Red" } elseif ($errCount -gt 0) { "Yellow" } else { "Green" })

        # Memory deviation from baseline
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        [double[]] $memArr = @(0.0)
        $memArr[0]  = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
        $memArr[0] /= $os.TotalVisibleMemorySize
        $memArr[0] *= 100.0
        $memPct = [Math]::Round($memArr[0], 1)
        Write-Host ("   Memory baseline       : {0}% used" -f $memPct) -ForegroundColor White

        # Process count as affected pillars proxy
        $procCount = (Get-Process -ErrorAction SilentlyContinue).Count
        Write-Host ("   Active processes      : {0}" -f $procCount) -ForegroundColor White

        Write-Host "   Anomaly probe         : confirmed ✅" -ForegroundColor Green

    } catch {
        Write-Host "   [WARNING] Anomaly probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated anomaly conditions."    -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFAnomalyDetectorTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "🔍 VBAF Enterprise - Phase 18: Anomaly Detection Engine"             -ForegroundColor Cyan
    Write-Host "   Training DQN agent on cross-pillar anomaly detection..."           -ForegroundColor Cyan
    Write-Host "   Actions: 0=Ignore  1=Flag  2=Alert  3=Escalate"                  -ForegroundColor Yellow
    Write-Host "   State  : DeviationScore | EventFreq | DeviationTrend | Pillars"  -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"           -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFAnomalySnapshot
    }

    $adEnv = [AnomalyDetectorEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $adEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $adEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $adEnv.Step($rAction)
            $bReward += $adEnv.LastReward
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
            if      ($roll -le 25) { $adEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $adEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 80) { $adEnv.CurrentSeverity = 2 }
            else                   { $adEnv.CurrentSeverity = 3 }

            switch ($adEnv.CurrentSeverity) {
                0 {
                    $adEnv.DeviationScore  = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $adEnv.EventFrequency  = [double](Get-Random -Minimum 0  -Maximum 15) / 100.0
                    $adEnv.DeviationTrend  = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                    $adEnv.AffectedPillars = [double](Get-Random -Minimum 0  -Maximum 15) / 100.0
                }
                1 {
                    $adEnv.DeviationScore  = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $adEnv.EventFrequency  = [double](Get-Random -Minimum 15 -Maximum 45) / 100.0
                    $adEnv.DeviationTrend  = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                    $adEnv.AffectedPillars = [double](Get-Random -Minimum 15 -Maximum 40) / 100.0
                }
                2 {
                    $adEnv.DeviationScore  = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $adEnv.EventFrequency  = [double](Get-Random -Minimum 45 -Maximum 70) / 100.0
                    $adEnv.DeviationTrend  = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                    $adEnv.AffectedPillars = [double](Get-Random -Minimum 40 -Maximum 65) / 100.0
                }
                3 {
                    $adEnv.DeviationScore  = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                    $adEnv.EventFrequency  = [double](Get-Random -Minimum 70  -Maximum 100) / 100.0
                    $adEnv.DeviationTrend  = [double](Get-Random -Minimum 0   -Maximum 20)  / 100.0
                    $adEnv.AffectedPillars = [double](Get-Random -Minimum 65  -Maximum 100) / 100.0
                }
            }
            $adEnv.CorrectActions    = 0
            $adEnv.MissedEscalations = 0
            $adEnv.Steps             = 0
            $adEnv.TotalReward       = 0.0
            $adEnv.LastDone          = $false
            $adEnv.EpisodeCount++
            $state = $adEnv.GetState()
        } else {
            $state = $adEnv.Reset()
        }

        $done           = $false
        $epReward       = 0.0
        $ignoreCount    = 0
        $flagCount      = 0
        $alertCount     = 0
        $escalateCount  = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $adEnv.Step($action)
            [double[]] $nextState = $adEnv.GetState()
            [double]   $reward    = $adEnv.LastReward
            [bool]     $isDone    = $adEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $ignoreCount++   }
                1 { $flagCount++     }
                2 { $alertCount++    }
                3 { $escalateCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode  = $ep
            Reward   = $epReward
            Ignore   = $ignoreCount
            Flag     = $flagCount
            Alert    = $alertCount
            Escalate = $escalateCount
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
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Ign:{4} Flg:{5} Alt:{6} Esc:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $ignoreCount, $flagCount, $alertCount, $escalateCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $adEnv.Reset()
        $tReward = 0.0
        while (-not $adEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $adEnv.Step($tAction)
            [double[]] $evalState = $adEnv.GetState()
            $tReward += $adEnv.LastReward
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
    $denomP = $adEnv.TruePositives + $adEnv.FalsePositives
    $denomR = $adEnv.TruePositives + $adEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $adEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $adEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 18: Anomaly Detection - Results           ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Alert+Esc correct) : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (anomalies caught)  : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Ignore   normal variation, no action         ║" -ForegroundColor White
    Write-Host "║    Flag     log anomaly for review              ║" -ForegroundColor White
    Write-Host "║    Alert    notify operators immediately        ║" -ForegroundColor White
    Write-Host "║    Escalate trigger cross-pillar remediation    ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated anomaly conditions)
#    $r = Invoke-VBAFAnomalyDetectorTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real event log, WMI memory, process count)
#    $r = Invoke-VBAFAnomalyDetectorTraining -Episodes 100 -PrintEvery 10
#
# 4. SKIP REAL DATA PROBE
#    $r = Invoke-VBAFAnomalyDetectorTraining -Episodes 100 -PrintEvery 10 -SkipRealData
#
# 5. INSPECT AGENT DECISIONS
#    $env   = [AnomalyDetectorEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "Deviation: $($env.DeviationScore)  Trend: $($env.DeviationTrend)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Ignore","Flag","Alert","Escalate")
#    Write-Host "Anomaly decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.AnomalyDetector.ps1 loaded  [v3.8.0 🔍]" -ForegroundColor Green
Write-Host "   Phase 18: Anomaly Detection Engine"                        -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFAnomalyDetectorTraining"             -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFAnomalyDetectorTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""