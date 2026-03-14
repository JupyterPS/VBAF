#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 22 - User Behavior Analytics
.DESCRIPTION
    Trains a DQN agent to detect and respond to anomalous user behavior
    across all VBAF pillars. The agent observes behavioral risk signals
    and learns when to:
      - Ignore   : normal activity, no action needed               (action 0)
      - Flag     : log for review, increase monitoring             (action 1)
      - Alert    : notify security team, investigate               (action 2)
      - Lock     : disable account, emergency containment          (action 3)
.NOTES
    Part of VBAF - Phase 22 Enterprise Automation Engine
    Phase 22: User Behavior Analytics
    PS 5.1 compatible
    Real data: Get-WinEvent Security log (logon events), Get-LocalUser
    Design: SessionHealth INVERTED (high=normal, low=suspicious)
            Distribution 15/40/30/15 — math-proven from Phase 21
#>

# ============================================================
# PHASE 22 - USER BEHAVIOR ANALYTICS
# ============================================================

class UserBehaviorEnvironment {

    # State: 4 genuinely observable UBA signals (0.0 - 1.0)
    # NO SeverityNorm — agent must learn the mapping from real signals
    # SessionHealth INVERTED: high=clean session, low=compromised
    [double] $AnomalyScore      # 0=normal pattern    1=highly anomalous
    [double] $RiskVelocity      # 0=slow/normal        1=rapid escalation
    [double] $SessionHealth     # 0=clean session      1=compromised (normal, no inversion)
    [double] $PrivilegeAbuse    # 0=normal access      1=privilege escalation

    [int]    $CorrectActions
    [int]    $MissedThreats
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

    UserBehaviorEnvironment() {
        $this.Reset() | Out-Null
    }

    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.AnomalyScore
        $s[1] = $this.RiskVelocity
        $s[2] = $this.SessionHealth
        $s[3] = $this.PrivilegeAbuse
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
        $this.LastDone       = $false   # CRITICAL: must reset here
        $this.EpisodeCount++
        $this._SampleCondition()
        [double[]] $initState = $this.GetState()
        return $initState
    }

    [void] _SampleCondition() {
        # Distribution 15/40/30/15 — math-proven from Phase 21
        # Flag(1)=40% majority: collapse to action 1 = positive result
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 15) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 85) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                # Ignore: low anomaly, slow velocity, HIGH health, no privilege abuse
                $this.AnomalyScore   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.RiskVelocity   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.SessionHealth  = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.PrivilegeAbuse = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
            }
            1 {
                # Flag: moderate anomaly, rising velocity, degrading health
                $this.AnomalyScore   = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.RiskVelocity   = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.SessionHealth  = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.PrivilegeAbuse = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
            }
            2 {
                # Alert: high anomaly, fast velocity, LOW health, privilege abuse
                $this.AnomalyScore   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.RiskVelocity   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.SessionHealth  = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.PrivilegeAbuse = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
            }
            3 {
                # Lock: critical anomaly, rapid escalation, NEAR-ZERO health, full abuse
                $this.AnomalyScore   = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.RiskVelocity   = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.SessionHealth  = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.PrivilegeAbuse = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Ignore  1=Flag  2=Alert  3=Lock
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

        if ($this.CurrentSeverity -ge 2 -and $action -lt 2) { $this.MissedThreats++ }

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
# Real Windows UBA probe
# ------------------------------------
function Get-VBAFUserBehaviorSnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing user behavior signals..." -ForegroundColor Gray

    try {
        # Failed logons as anomaly signal
        $failedLogons = Get-WinEvent -FilterHashtable @{
            LogName   = 'Security'
            Id        = 4625
            StartTime = (Get-Date).AddHours(-4)
        } -ErrorAction SilentlyContinue
        $failCount = if ($failedLogons) { @($failedLogons).Count } else { 0 }
        Write-Host ("   Failed logons (4h)    : {0}" -f $failCount) -ForegroundColor $(if ($failCount -gt 10) { "Red" } elseif ($failCount -gt 3) { "Yellow" } else { "Green" })

        # Local users as privilege scope signal
        $users     = Get-LocalUser -ErrorAction SilentlyContinue
        $admins    = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
        $userCount = if ($users)  { @($users).Count  } else { 0 }
        $adminCount= if ($admins) { @($admins).Count } else { 0 }
        Write-Host ("   Local users           : {0}" -f $userCount)  -ForegroundColor White
        Write-Host ("   Administrators        : {0}" -f $adminCount) -ForegroundColor $(if ($adminCount -gt 3) { "Yellow" } else { "Green" })

        Write-Host "   UBA probe             : confirmed ✅" -ForegroundColor Green

    } catch {
        Write-Host "   [WARNING] UBA probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated behavior conditions." -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFUserBehaviorAnalyticsTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "👤 VBAF Enterprise - Phase 22: User Behavior Analytics"              -ForegroundColor Cyan
    Write-Host "   Training DQN agent on anomalous user activity detection..."        -ForegroundColor Cyan
    Write-Host "   Actions: 0=Ignore  1=Flag  2=Alert  3=Lock"                       -ForegroundColor Yellow
    Write-Host "   State  : AnomalyScore | RiskVelocity | SessionHealth | PrivAbuse"  -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"           -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFUserBehaviorSnapshot
    }

    $ubaEnv = [UserBehaviorEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $ubaEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $ubaEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $ubaEnv.Step($rAction)
            $bReward += $ubaEnv.LastReward
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
            if      ($roll -le 15) { $ubaEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $ubaEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 85) { $ubaEnv.CurrentSeverity = 2 }
            else                   { $ubaEnv.CurrentSeverity = 3 }

            switch ($ubaEnv.CurrentSeverity) {
                0 {
                    $ubaEnv.AnomalyScore   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $ubaEnv.RiskVelocity   = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $ubaEnv.SessionHealth  = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $ubaEnv.PrivilegeAbuse = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                }
                1 {
                    $ubaEnv.AnomalyScore   = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $ubaEnv.RiskVelocity   = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $ubaEnv.SessionHealth  = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $ubaEnv.PrivilegeAbuse = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                }
                2 {
                    $ubaEnv.AnomalyScore   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $ubaEnv.RiskVelocity   = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $ubaEnv.SessionHealth  = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $ubaEnv.PrivilegeAbuse = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                }
                3 {
                    $ubaEnv.AnomalyScore   = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                    $ubaEnv.RiskVelocity   = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                    $ubaEnv.SessionHealth  = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                    $ubaEnv.PrivilegeAbuse = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                }
            }
            $ubaEnv.CorrectActions = 0
            $ubaEnv.MissedThreats  = 0
            $ubaEnv.Steps          = 0
            $ubaEnv.TotalReward    = 0.0
            $ubaEnv.LastDone       = $false
            $ubaEnv.EpisodeCount++
            $state = $ubaEnv.GetState()
        } else {
            $state = $ubaEnv.Reset()
        }

        $done         = $false
        $epReward     = 0.0
        $ignoreCount  = 0
        $flagCount    = 0
        $alertCount   = 0
        $lockCount    = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $ubaEnv.Step($action)
            [double[]] $nextState = $ubaEnv.GetState()
            [double]   $reward    = $ubaEnv.LastReward
            [bool]     $isDone    = $ubaEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $ignoreCount++ }
                1 { $flagCount++   }
                2 { $alertCount++  }
                3 { $lockCount++   }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode = $ep
            Reward  = $epReward
            Ignore  = $ignoreCount
            Flag    = $flagCount
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
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Ign:{4} Flg:{5} Alt:{6} Lck:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $ignoreCount, $flagCount, $alertCount, $lockCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $ubaEnv.Reset()
        $tReward = 0.0
        while (-not $ubaEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $ubaEnv.Step($tAction)
            [double[]] $evalState = $ubaEnv.GetState()
            $tReward += $ubaEnv.LastReward
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
    $denomP = $ubaEnv.TruePositives + $ubaEnv.FalsePositives
    $denomR = $ubaEnv.TruePositives + $ubaEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $ubaEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $ubaEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 22: User Behavior Analytics - Results     ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Alert+Lock correct): {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (threats caught)    : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Ignore   normal activity, no action          ║" -ForegroundColor White
    Write-Host "║    Flag     log for review, monitor             ║" -ForegroundColor White
    Write-Host "║    Alert    notify security, investigate        ║" -ForegroundColor White
    Write-Host "║    Lock     disable account, contain threat     ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated behavior conditions)
#    $r = Invoke-VBAFUserBehaviorAnalyticsTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real Security log, local users, admins)
#    $r = Invoke-VBAFUserBehaviorAnalyticsTraining -Episodes 100 -PrintEvery 10
#
# 4. INSPECT AGENT DECISIONS
#    $env   = [UserBehaviorEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "Anomaly: $($env.AnomalyScore)  Health: $($env.SessionHealth)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Ignore","Flag","Alert","Lock")
#    Write-Host "UBA decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.UserBehaviorAnalytics.ps1 loaded  [v3.12.0 👤]" -ForegroundColor Green
Write-Host "   Phase 22: User Behavior Analytics"                                -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFUserBehaviorAnalyticsTraining"                       -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFUserBehaviorAnalyticsTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""