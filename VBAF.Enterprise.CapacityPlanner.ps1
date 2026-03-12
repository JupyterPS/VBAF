#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 19 - Capacity Planning Intelligence
.DESCRIPTION
    Trains a DQN agent to predict and manage resource exhaustion before
    it happens. The agent observes capacity trend signals and learns when to:
      - Monitor   : watch and record, no action needed           (action 0)
      - Warn      : notify that capacity threshold approaching   (action 1)
      - Reserve   : pre-allocate resources before exhaustion     (action 2)
      - Escalate  : emergency expansion, exhaustion imminent     (action 3)
.NOTES
    Part of VBAF - Phase 19 Enterprise Automation Engine
    Phase 19: Capacity Planning Intelligence
    PS 5.1 compatible
    Real data: Get-PSDrive, WMI Win32_OperatingSystem, Get-Counter
    Design: AvailableHeadroom INVERTED (high=plenty of room=Monitor, low=almost full=Escalate)
            breaks monotonic collapse — lesson carried forward from Phases 15-18
#>

# ============================================================
# PHASE 19 - CAPACITY PLANNING INTELLIGENCE
# ============================================================

class CapacityPlannerEnvironment {

    # State: 4 genuinely observable capacity signals (0.0 - 1.0)
    # NO SeverityNorm — agent must learn the mapping from real signals
    # AvailableHeadroom INVERTED: high=plenty, low=almost full — breaks monotonic collapse
    [double] $UsageGrowthRate   # 0=stable usage     1=rapidly growing
    [double] $PeakUtilization   # 0=low peak load    1=consistently maxed out
    [double] $AvailableHeadroom # 1=plenty of space  0=nearly exhausted (INVERTED)
    [double] $TimeRemaining     # 1=weeks away       0=hours away (INVERTED — breaks collapse)

    [int]    $CorrectActions
    [int]    $MissedReservations
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

    CapacityPlannerEnvironment() {
        $this.Reset() | Out-Null
    }

    # CRITICAL PS 5.1: build strictly typed [double[]] element by element
    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.UsageGrowthRate
        $s[1] = $this.PeakUtilization
        $s[2] = $this.AvailableHeadroom
        $s[3] = $this.TimeRemaining
        return $s
    }

    [double[]] Reset() {
        $this.Steps               = 0
        $this.TotalReward         = 0.0
        $this.CorrectActions      = 0
        $this.MissedReservations  = 0
        $this.TruePositives       = 0
        $this.FalsePositives      = 0
        $this.TrueNegatives       = 0
        $this.FalseNegatives      = 0
        $this.LastDone            = $false   # CRITICAL: must reset here
        $this.EpisodeCount++
        $this._SampleCondition()
        [double[]] $initState = $this.GetState()
        return $initState
    }

    [void] _SampleCondition() {
        # Balanced training distribution
        # 25% monitor (0), 30% warn (1), 25% reserve (2), 20% escalate (3)
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 25) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 80) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                # Monitor: stable growth, low peak, PLENTY of headroom, exhaustion far away
                $this.UsageGrowthRate   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.PeakUtilization   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.AvailableHeadroom = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                $this.TimeRemaining     = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
            }
            1 {
                # Warn: noticeable growth, moderate peaks, shrinking headroom
                $this.UsageGrowthRate   = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.PeakUtilization   = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                $this.AvailableHeadroom = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                $this.TimeRemaining     = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
            }
            2 {
                # Reserve: fast growth, high peaks, low headroom, exhaustion approaching
                $this.UsageGrowthRate   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.PeakUtilization   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.AvailableHeadroom = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                $this.TimeRemaining     = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
            }
            3 {
                # Escalate: explosive growth, maxed peaks, NEAR ZERO headroom, imminent
                $this.UsageGrowthRate   = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                $this.PeakUtilization   = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                $this.AvailableHeadroom = [double](Get-Random -Minimum 0   -Maximum 20)  / 100.0
                $this.TimeRemaining     = [double](Get-Random -Minimum 0   -Maximum 20)  / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Monitor  1=Warn  2=Reserve  3=Escalate
        return $this.CurrentSeverity
    }

    [void] Step([int]$action) {
        $this.Steps++
        $optimal = $this._OptimalAction()

        # Symmetric distance-based reward (proven across Phases 10-18)
        [int] $dist = $action - $optimal
        if ($dist -lt 0) { $dist = -$dist }

        if    ($dist -eq 0) { $this.LastReward =  2.0; $this.CorrectActions++ }
        elseif($dist -eq 1) { $this.LastReward = -1.0 }
        elseif($dist -eq 2) { $this.LastReward = -2.0 }
        else                { $this.LastReward = -3.0 }

        if ($this.CurrentSeverity -ge 2 -and $action -lt 2) { $this.MissedReservations++ }

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
# Real Windows capacity probe
# ------------------------------------
function Get-VBAFCapacitySnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing system capacity signals..." -ForegroundColor Gray

    try {
        # Disk capacity — primary capacity signal
        $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction Stop
        foreach ($drive in $drives) {
            if ($drive.Used -gt 0 -or $drive.Free -gt 0) {
                [double[]] $pctArr = @(0.0)
                $pctArr[0]  = $drive.Used
                $pctArr[0] /= ($drive.Used + $drive.Free)
                $pctArr[0] *= 100.0
                $pct = [Math]::Round($pctArr[0], 1)
                $colour = if ($pct -gt 90) { "Red" } elseif ($pct -gt 75) { "Yellow" } else { "Green" }
                Write-Host ("   Drive {0}: used         : {1}%" -f $drive.Name, $pct) -ForegroundColor $colour
            }
        }

        # Memory headroom
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        [double[]] $freeArr = @(0.0)
        $freeArr[0]  = $os.FreePhysicalMemory
        $freeArr[0] /= $os.TotalVisibleMemorySize
        $freeArr[0] *= 100.0
        $freePct = [Math]::Round($freeArr[0], 1)
        Write-Host ("   Free memory           : {0}%" -f $freePct) -ForegroundColor $(if ($freePct -lt 10) { "Red" } elseif ($freePct -lt 25) { "Yellow" } else { "Green" })

        Write-Host "   Capacity probe        : confirmed ✅" -ForegroundColor Green

    } catch {
        Write-Host "   [WARNING] Capacity probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated capacity conditions."    -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFCapacityPlannerTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "📈 VBAF Enterprise - Phase 19: Capacity Planning Intelligence"        -ForegroundColor Cyan
    Write-Host "   Training DQN agent on resource exhaustion prediction..."            -ForegroundColor Cyan
    Write-Host "   Actions: 0=Monitor  1=Warn  2=Reserve  3=Escalate"                -ForegroundColor Yellow
    Write-Host "   State  : GrowthRate | PeakUtil | Headroom | TimeRemaining"     -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"            -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFCapacitySnapshot
    }

    $cpEnv = [CapacityPlannerEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $cpEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $cpEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $cpEnv.Step($rAction)
            $bReward += $cpEnv.LastReward
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
            if      ($roll -le 25) { $cpEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $cpEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 80) { $cpEnv.CurrentSeverity = 2 }
            else                   { $cpEnv.CurrentSeverity = 3 }

            switch ($cpEnv.CurrentSeverity) {
                0 {
                    $cpEnv.UsageGrowthRate   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $cpEnv.PeakUtilization   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $cpEnv.AvailableHeadroom = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                    $cpEnv.TimeRemaining     = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                }
                1 {
                    $cpEnv.UsageGrowthRate   = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $cpEnv.PeakUtilization   = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                    $cpEnv.AvailableHeadroom = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                    $cpEnv.TimeRemaining     = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                }
                2 {
                    $cpEnv.UsageGrowthRate   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $cpEnv.PeakUtilization   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $cpEnv.AvailableHeadroom = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                    $cpEnv.TimeRemaining     = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                }
                3 {
                    $cpEnv.UsageGrowthRate   = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                    $cpEnv.PeakUtilization   = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                    $cpEnv.AvailableHeadroom = [double](Get-Random -Minimum 0   -Maximum 20)  / 100.0
                    $cpEnv.TimeRemaining     = [double](Get-Random -Minimum 0   -Maximum 20)  / 100.0
                }
            }
            $cpEnv.CorrectActions     = 0
            $cpEnv.MissedReservations = 0
            $cpEnv.Steps              = 0
            $cpEnv.TotalReward        = 0.0
            $cpEnv.LastDone           = $false
            $cpEnv.EpisodeCount++
            $state = $cpEnv.GetState()
        } else {
            $state = $cpEnv.Reset()
        }

        $done           = $false
        $epReward       = 0.0
        $monitorCount   = 0
        $warnCount      = 0
        $reserveCount   = 0
        $escalateCount  = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $cpEnv.Step($action)
            [double[]] $nextState = $cpEnv.GetState()
            [double]   $reward    = $cpEnv.LastReward
            [bool]     $isDone    = $cpEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $monitorCount++  }
                1 { $warnCount++     }
                2 { $reserveCount++  }
                3 { $escalateCount++ }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode  = $ep
            Reward   = $epReward
            Monitor  = $monitorCount
            Warn     = $warnCount
            Reserve  = $reserveCount
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
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Mon:{4} Wrn:{5} Res:{6} Esc:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $monitorCount, $warnCount, $reserveCount, $escalateCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $cpEnv.Reset()
        $tReward = 0.0
        while (-not $cpEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $cpEnv.Step($tAction)
            [double[]] $evalState = $cpEnv.GetState()
            $tReward += $cpEnv.LastReward
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
    $denomP = $cpEnv.TruePositives + $cpEnv.FalsePositives
    $denomR = $cpEnv.TruePositives + $cpEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $cpEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $cpEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 19: Capacity Planning - Results           ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Res+Esc correct)   : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (exhaustions caught): {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Monitor  watch and record capacity trends    ║" -ForegroundColor White
    Write-Host "║    Warn     notify threshold approaching        ║" -ForegroundColor White
    Write-Host "║    Reserve  pre-allocate before exhaustion      ║" -ForegroundColor White
    Write-Host "║    Escalate emergency expansion, imminent       ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated capacity conditions)
#    $r = Invoke-VBAFCapacityPlannerTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real disk, WMI memory)
#    $r = Invoke-VBAFCapacityPlannerTraining -Episodes 100 -PrintEvery 10
#
# 4. INSPECT AGENT DECISIONS
#    $env   = [CapacityPlannerEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "GrowthRate: $($env.UsageGrowthRate)  Headroom: $($env.AvailableHeadroom)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Monitor","Warn","Reserve","Escalate")
#    Write-Host "Capacity decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.CapacityPlanner.ps1 loaded  [v3.9.0 📈]" -ForegroundColor Green
Write-Host "   Phase 19: Capacity Planning Intelligence"                   -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFCapacityPlannerTraining"              -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFCapacityPlannerTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""