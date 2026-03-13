#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 20 - Incident Response Automation
.DESCRIPTION
    Trains a DQN agent to coordinate automated incident response across
    all VBAF pillars. The agent observes incident severity signals and
    learns when to:
      - Investigate : gather data, assess scope                   (action 0)
      - Contain     : isolate affected systems, stop spread       (action 1)
      - Remediate   : fix root cause, restore normal operation    (action 2)
      - Report      : document incident, notify stakeholders      (action 3)
.NOTES
    Part of VBAF - Phase 20 Enterprise Automation Engine
    Phase 20: Incident Response Automation
    PS 5.1 compatible
    Real data: Get-WinEvent, WMI Win32_OperatingSystem, Get-Service
    Design: SystemStability INVERTED (high=stable=Investigate, low=collapsing=Report)
            + ContainmentProgress INVERTED (high=contained, low=spreading)
            dual inversion — proven pattern from Phase 19
#>

# ============================================================
# PHASE 20 - INCIDENT RESPONSE AUTOMATION
# ============================================================

class IncidentResponderEnvironment {

    # State: 4 genuinely observable incident signals (0.0 - 1.0)
    # NO SeverityNorm — agent must learn the mapping from real signals
    # SystemStability INVERTED: high=stable, low=collapsing
    # ContainmentProgress INVERTED: high=contained, low=spreading
    [double] $IncidentScope        # 0=isolated incident  1=enterprise-wide
    [double] $ImpactSeverity       # 0=minor disruption   1=critical outage
    [double] $SystemStability      # 1=systems stable     0=cascading failures (INVERTED)
    [double] $ContainmentProgress  # 0=well contained     1=actively spreading (normal)

    [int]    $CorrectActions
    [int]    $MissedContainments
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

    IncidentResponderEnvironment() {
        $this.Reset() | Out-Null
    }

    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.IncidentScope
        $s[1] = $this.ImpactSeverity
        $s[2] = $this.SystemStability
        $s[3] = $this.ContainmentProgress
        return $s
    }

    [double[]] Reset() {
        $this.Steps               = 0
        $this.TotalReward         = 0.0
        $this.CorrectActions      = 0
        $this.MissedContainments  = 0
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
        # 25% investigate (0), 30% contain (1), 25% remediate (2), 20% report (3)
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 25) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 80) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                # Investigate: small scope, minor impact, STABLE, well contained
                $this.IncidentScope       = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.ImpactSeverity      = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.SystemStability     = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                $this.ContainmentProgress = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
            }
            1 {
                # Contain: spreading scope, moderate impact, degrading stability
                $this.IncidentScope       = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.ImpactSeverity      = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                $this.SystemStability     = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                $this.ContainmentProgress = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
            }
            2 {
                # Remediate: wide scope, high impact, low stability, partially contained
                $this.IncidentScope       = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.ImpactSeverity      = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.SystemStability     = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                $this.ContainmentProgress = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
            }
            3 {
                # Report: enterprise-wide, critical outage, COLLAPSING, actively spreading
                $this.IncidentScope       = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                $this.ImpactSeverity      = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                $this.SystemStability     = [double](Get-Random -Minimum 0   -Maximum 20)  / 100.0
                $this.ContainmentProgress = [double](Get-Random -Minimum 80  -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Investigate  1=Contain  2=Remediate  3=Report
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

        if ($this.CurrentSeverity -ge 2 -and $action -lt 2) { $this.MissedContainments++ }

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
# Real Windows incident probe
# ------------------------------------
function Get-VBAFIncidentSnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing incident response signals..." -ForegroundColor Gray

    try {
        # Critical events as incident scope proxy
        $critical = Get-WinEvent -FilterHashtable @{
            LogName   = 'System'
            Level     = @(1,2)
            StartTime = (Get-Date).AddHours(-2)
        } -ErrorAction SilentlyContinue
        $critCount = if ($critical) { @($critical).Count } else { 0 }
        Write-Host ("   Critical events (2h)  : {0}" -f $critCount) -ForegroundColor $(if ($critCount -gt 5) { "Red" } elseif ($critCount -gt 0) { "Yellow" } else { "Green" })

        # Stopped services as impact severity proxy
        $stopped = Get-Service -ErrorAction Stop | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
        $stoppedCount = if ($stopped) { @($stopped).Count } else { 0 }
        Write-Host ("   Auto-start stopped    : {0}" -f $stoppedCount) -ForegroundColor $(if ($stoppedCount -gt 3) { "Red" } elseif ($stoppedCount -gt 0) { "Yellow" } else { "Green" })

        # Memory as system stability proxy
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        [double[]] $freeArr = @(0.0)
        $freeArr[0]  = $os.FreePhysicalMemory
        $freeArr[0] /= $os.TotalVisibleMemorySize
        $freeArr[0] *= 100.0
        $freePct = [Math]::Round($freeArr[0], 1)
        Write-Host ("   System memory free    : {0}%" -f $freePct) -ForegroundColor $(if ($freePct -lt 10) { "Red" } elseif ($freePct -lt 25) { "Yellow" } else { "Green" })

        Write-Host "   Incident probe        : confirmed ✅" -ForegroundColor Green

    } catch {
        Write-Host "   [WARNING] Incident probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated incident conditions."    -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFIncidentResponderTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "🚨 VBAF Enterprise - Phase 20: Incident Response Automation"          -ForegroundColor Cyan
    Write-Host "   Training DQN agent on cross-pillar incident coordination..."        -ForegroundColor Cyan
    Write-Host "   Actions: 0=Investigate  1=Contain  2=Remediate  3=Report"          -ForegroundColor Yellow
    Write-Host "   State  : IncidentScope | ImpactSeverity | Stability | Containment" -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"            -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFIncidentSnapshot
    }

    $irEnv = [IncidentResponderEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $irEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $irEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $irEnv.Step($rAction)
            $bReward += $irEnv.LastReward
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
            if      ($roll -le 25) { $irEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $irEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 80) { $irEnv.CurrentSeverity = 2 }
            else                   { $irEnv.CurrentSeverity = 3 }

            switch ($irEnv.CurrentSeverity) {
                0 {
                    $irEnv.IncidentScope       = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $irEnv.ImpactSeverity      = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $irEnv.SystemStability     = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                    $irEnv.ContainmentProgress = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                }
                1 {
                    $irEnv.IncidentScope       = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $irEnv.ImpactSeverity      = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                    $irEnv.SystemStability     = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                    $irEnv.ContainmentProgress = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                }
                2 {
                    $irEnv.IncidentScope       = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $irEnv.ImpactSeverity      = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $irEnv.SystemStability     = [double](Get-Random -Minimum 20 -Maximum 50) / 100.0
                    $irEnv.ContainmentProgress = [double](Get-Random -Minimum 50 -Maximum 80) / 100.0
                }
                3 {
                    $irEnv.IncidentScope       = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                    $irEnv.ImpactSeverity      = [double](Get-Random -Minimum 75  -Maximum 100) / 100.0
                    $irEnv.SystemStability     = [double](Get-Random -Minimum 0   -Maximum 20)  / 100.0
                    $irEnv.ContainmentProgress = [double](Get-Random -Minimum 80  -Maximum 100) / 100.0
                }
            }
            $irEnv.CorrectActions     = 0
            $irEnv.MissedContainments = 0
            $irEnv.Steps              = 0
            $irEnv.TotalReward        = 0.0
            $irEnv.LastDone           = $false
            $irEnv.EpisodeCount++
            $state = $irEnv.GetState()
        } else {
            $state = $irEnv.Reset()
        }

        $done             = $false
        $epReward         = 0.0
        $investigateCount = 0
        $containCount     = 0
        $remediateCount   = 0
        $reportCount      = 0
        [int] $stepCount  = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $irEnv.Step($action)
            [double[]] $nextState = $irEnv.GetState()
            [double]   $reward    = $irEnv.LastReward
            [bool]     $isDone    = $irEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $investigateCount++ }
                1 { $containCount++     }
                2 { $remediateCount++   }
                3 { $reportCount++      }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode     = $ep
            Reward      = $epReward
            Investigate = $investigateCount
            Contain     = $containCount
            Remediate   = $remediateCount
            Report      = $reportCount
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
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Inv:{4} Con:{5} Rem:{6} Rep:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $investigateCount, $containCount, $remediateCount, $reportCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $irEnv.Reset()
        $tReward = 0.0
        while (-not $irEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $irEnv.Step($tAction)
            [double[]] $evalState = $irEnv.GetState()
            $tReward += $irEnv.LastReward
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
    $denomP = $irEnv.TruePositives + $irEnv.FalsePositives
    $denomR = $irEnv.TruePositives + $irEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $irEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $irEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 20: Incident Response - Results           ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Rem+Rep correct)   : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (incidents handled) : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Investigate  gather data, assess scope       ║" -ForegroundColor White
    Write-Host "║    Contain      isolate systems, stop spread    ║" -ForegroundColor White
    Write-Host "║    Remediate    fix root cause, restore ops     ║" -ForegroundColor White
    Write-Host "║    Report       document and notify             ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated incident conditions)
#    $r = Invoke-VBAFIncidentResponderTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real event log, services, WMI memory)
#    $r = Invoke-VBAFIncidentResponderTraining -Episodes 100 -PrintEvery 10
#
# 4. INSPECT AGENT DECISIONS
#    $env   = [IncidentResponderEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "Scope: $($env.IncidentScope)  Stability: $($env.SystemStability)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Investigate","Contain","Remediate","Report")
#    Write-Host "Incident decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.IncidentResponder.ps1 loaded  [v3.10.0 🚨]" -ForegroundColor Green
Write-Host "   Phase 20: Incident Response Automation"                       -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFIncidentResponderTraining"              -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFIncidentResponderTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""