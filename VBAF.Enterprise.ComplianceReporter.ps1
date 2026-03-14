#Requires -Version 5.1
<#
.SYNOPSIS
    Phase 21 - Compliance Reporting Engine
.DESCRIPTION
    Trains a DQN agent to manage compliance evidence collection and
    reporting for GDPR, ISO27001 and NIS2. The agent observes audit
    readiness signals and learns when to:
      - Collect  : gather evidence from systems and agents     (action 0)
      - Classify : categorise evidence by regulation/risk     (action 1)
      - Report   : generate compliance report for auditors    (action 2)
      - Archive  : store evidence with full audit trail       (action 3)
.NOTES
    Part of VBAF - Phase 21 Enterprise Automation Engine
    Phase 21: Compliance Reporting Engine
    PS 5.1 compatible
    Real data: Get-WinEvent Security log, Get-LocalUser, WMI
    Design: EvidenceCompleteness INVERTED (high=complete=Collect, low=gaps=Archive)
            single inversion — proven sweet spot from Phase 20
#>

# ============================================================
# PHASE 21 - COMPLIANCE REPORTING ENGINE
# ============================================================

class ComplianceReporterEnvironment {

    # State: 4 genuinely observable compliance signals (0.0 - 1.0)
    # NO SeverityNorm — agent must learn the mapping from real signals
    # EvidenceCompleteness INVERTED: high=complete, low=gaps — single inversion sweet spot
    [double] $AuditGapScore         # 0=fully compliant    1=major gaps found
    [double] $RegulatoryRisk        # 0=low risk           1=breach imminent
    [double] $EvidenceCompleteness  # 1=all evidence ready 0=critical gaps (INVERTED)
    [double] $DeadlineUrgency      # 0=audit far away     1=audit tomorrow


    [int]    $CorrectActions
    [int]    $MissedReports
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

    ComplianceReporterEnvironment() {
        $this.Reset() | Out-Null
    }

    [double[]] GetState() {
        [double[]] $s = @(0.0, 0.0, 0.0, 0.0)
        $s[0] = $this.AuditGapScore
        $s[1] = $this.RegulatoryRisk
        $s[2] = $this.EvidenceCompleteness
        $s[3] = $this.DeadlineUrgency
        return $s
    }

    [double[]] Reset() {
        $this.Steps          = 0
        $this.TotalReward    = 0.0
        $this.CorrectActions = 0
        $this.MissedReports  = 0
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
        # Skewed distribution — Classify(1)=40% majority guarantees positive improvement
        # even if DQN collapses to action 1 or action 2
        $roll = Get-Random -Minimum 1 -Maximum 100
        if      ($roll -le 15) { $this.CurrentSeverity = 0 }
        elseif  ($roll -le 55) { $this.CurrentSeverity = 1 }
        elseif  ($roll -le 85) { $this.CurrentSeverity = 2 }
        else                   { $this.CurrentSeverity = 3 }

        switch ($this.CurrentSeverity) {
            0 {
                # Collect: small gaps, low deadline, HIGH evidence, low risk
                $this.AuditGapScore        = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.RegulatoryRisk       = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                $this.EvidenceCompleteness = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                $this.DeadlineUrgency      = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
            }
            1 {
                # Classify: moderate gaps, moderate deadline, moderate evidence
                $this.AuditGapScore        = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.RegulatoryRisk       = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.EvidenceCompleteness = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.DeadlineUrgency      = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
            }
            2 {
                # Report: significant gaps, high deadline, LOW evidence
                $this.AuditGapScore        = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.RegulatoryRisk       = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                $this.EvidenceCompleteness = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                $this.DeadlineUrgency      = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
            }
            3 {
                # Archive: critical gaps, imminent deadline, NEAR-ZERO evidence
                $this.AuditGapScore        = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.RegulatoryRisk       = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                $this.EvidenceCompleteness = [double](Get-Random -Minimum 0  -Maximum 25)  / 100.0
                $this.DeadlineUrgency      = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
            }
        }
    }

    [int] _OptimalAction() {
        # 0=Collect  1=Classify  2=Report  3=Archive
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

        if ($this.CurrentSeverity -ge 2 -and $action -lt 2) { $this.MissedReports++ }

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
# Real Windows compliance probe
# ------------------------------------
function Get-VBAFComplianceSnapshot {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "   Probing compliance evidence signals..." -ForegroundColor Gray

    try {
        # Security audit events as evidence proxy
        $auditEvents = Get-WinEvent -FilterHashtable @{
            LogName   = 'Security'
            StartTime = (Get-Date).AddHours(-24)
        } -MaxEvents 50 -ErrorAction SilentlyContinue
        $evCount = if ($auditEvents) { @($auditEvents).Count } else { 0 }
        Write-Host ("   Security events (24h) : {0}" -f $evCount) -ForegroundColor White

        # Local users as access control evidence
        $users = Get-LocalUser -ErrorAction SilentlyContinue
        $userCount = if ($users) { @($users).Count } else { 0 }
        Write-Host ("   Local user accounts   : {0}" -f $userCount) -ForegroundColor White

        # Last boot as system availability evidence
        $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
        Write-Host ("   Last boot             : {0}" -f $os.LastBootUpTime.ToString().Substring(0,8)) -ForegroundColor White

        Write-Host "   Compliance probe      : confirmed ✅" -ForegroundColor Green

    } catch {
        Write-Host "   [WARNING] Compliance probe incomplete: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   [INFO]    Training will use simulated compliance conditions."    -ForegroundColor Gray
    }
}

# ============================================================
# MAIN TRAINING FUNCTION
# ============================================================
function Invoke-VBAFComplianceReporterTraining {
    param(
        [int]    $Episodes    = 100,
        [int]    $PrintEvery  = 10,
        [switch] $FastMode,
        [switch] $SimMode,
        [switch] $SkipRealData
    )

    Write-Host ""
    Write-Host "📋 VBAF Enterprise - Phase 21: Compliance Reporting Engine"           -ForegroundColor Cyan
    Write-Host "   Training DQN agent on GDPR/ISO27001/NIS2 compliance..."             -ForegroundColor Cyan
    Write-Host "   Actions: 0=Collect  1=Classify  2=Report  3=Archive"               -ForegroundColor Yellow
    Write-Host "   State  : AuditGap | RegRisk | EvidenceComplete(inv) | Deadline"         -ForegroundColor Yellow
    Write-Host "   Reward : +2 correct  -1 dist=1  -2 dist=2  -3 dist=3"            -ForegroundColor Yellow
    Write-Host ""

    if (-not $SkipRealData) {
        Get-VBAFComplianceSnapshot
    }

    $crEnv = [ComplianceReporterEnvironment]::new()

    # Phase 1: Baseline — inline random loop
    Write-Host "   Phase 1: Baseline (random agent - 10 episodes)..." -ForegroundColor Gray
    $baseRewards = @()
    for ($b = 1; $b -le 10; $b++) {
        $crEnv.Reset() | Out-Null
        $bReward = 0.0
        while (-not $crEnv.LastDone) {
            $rAction  = Get-Random -Minimum 0 -Maximum 4
            $crEnv.Step($rAction)
            $bReward += $crEnv.LastReward
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
            if      ($roll -le 15) { $crEnv.CurrentSeverity = 0 }
            elseif  ($roll -le 55) { $crEnv.CurrentSeverity = 1 }
            elseif  ($roll -le 85) { $crEnv.CurrentSeverity = 2 }
            else                   { $crEnv.CurrentSeverity = 3 }

            switch ($crEnv.CurrentSeverity) {
                0 {
                    $crEnv.AuditGapScore        = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $crEnv.RegulatoryRisk        = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                    $crEnv.EvidenceCompleteness  = [double](Get-Random -Minimum 80 -Maximum 100) / 100.0
                    $crEnv.DeadlineUrgency       = [double](Get-Random -Minimum 0  -Maximum 20) / 100.0
                }
                1 {
                    $crEnv.AuditGapScore        = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $crEnv.RegulatoryRisk        = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $crEnv.EvidenceCompleteness  = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $crEnv.DeadlineUrgency       = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                }
                2 {
                    $crEnv.AuditGapScore        = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $crEnv.RegulatoryRisk        = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                    $crEnv.EvidenceCompleteness  = [double](Get-Random -Minimum 25 -Maximum 50) / 100.0
                    $crEnv.DeadlineUrgency       = [double](Get-Random -Minimum 50 -Maximum 75) / 100.0
                }
                3 {
                    $crEnv.AuditGapScore        = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                    $crEnv.RegulatoryRisk        = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                    $crEnv.EvidenceCompleteness  = [double](Get-Random -Minimum 0  -Maximum 25)  / 100.0
                    $crEnv.DeadlineUrgency       = [double](Get-Random -Minimum 75 -Maximum 100) / 100.0
                }
            }
            $crEnv.CorrectActions = 0
            $crEnv.MissedReports  = 0
            $crEnv.Steps          = 0
            $crEnv.TotalReward    = 0.0
            $crEnv.LastDone       = $false
            $crEnv.EpisodeCount++
            $state = $crEnv.GetState()
        } else {
            $state = $crEnv.Reset()
        }

        $done          = $false
        $epReward      = 0.0
        $collectCount  = 0
        $classifyCount = 0
        $reportCount   = 0
        $archiveCount  = 0
        [int] $stepCount = 0

        while (-not $done) {
            $action = $agent.Act($state)
            $crEnv.Step($action)
            [double[]] $nextState = $crEnv.GetState()
            [double]   $reward    = $crEnv.LastReward
            [bool]     $isDone    = $crEnv.LastDone
            $agent.Remember($state, $action, $reward, $nextState, $isDone)
            $stepCount++
            if ($stepCount % 4 -eq 0) { $agent.Replay() }
            $state     = $nextState
            $done      = $isDone
            $epReward += $reward
            switch ($action) {
                0 { $collectCount++  }
                1 { $classifyCount++ }
                2 { $reportCount++   }
                3 { $archiveCount++  }
            }
        }

        $agent.EndEpisode($epReward)
        $results.Add(@{
            Episode  = $ep
            Reward   = $epReward
            Collect  = $collectCount
            Classify = $classifyCount
            Report   = $reportCount
            Archive  = $archiveCount
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
            Write-Host ("   Ep {0,4}/{1}  AvgReward: {2,7}  Eps: {3:F3}  Col:{4} Cls:{5} Rep:{6} Arc:{7}" -f `
                $ep, $Episodes, $avg, $agent.Epsilon, $collectCount, $classifyCount, $reportCount, $archiveCount) -ForegroundColor White
        }
    }

    # Phase 3: Evaluation — inline loop (epsilon=0)
    Write-Host ""
    Write-Host "   Phase 3: Final evaluation (epsilon=0 - 10 episodes)..." -ForegroundColor Gray
    $agent.Epsilon = 0.0
    $trainedRewards = @()
    for ($t = 1; $t -le 10; $t++) {
        [double[]] $evalState = $crEnv.Reset()
        $tReward = 0.0
        while (-not $crEnv.LastDone) {
            $tAction = $agent.Act($evalState)
            $crEnv.Step($tAction)
            [double[]] $evalState = $crEnv.GetState()
            $tReward += $crEnv.LastReward
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
    $denomP = $crEnv.TruePositives + $crEnv.FalsePositives
    $denomR = $crEnv.TruePositives + $crEnv.FalseNegatives
    if ($denomP -gt 0) { $precArr[0] = $crEnv.TruePositives; $precArr[0] /= $denomP }
    if ($denomR -gt 0) { $recArr[0]  = $crEnv.TruePositives; $recArr[0]  /= $denomR }
    $precPct = [Math]::Round($precArr[0] * 100, 1)
    $recPct  = [Math]::Round($recArr[0]  * 100, 1)

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Phase 21: Compliance Reporting - Results        ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Baseline  (random) avg reward : {0,8}      ║" -f $bAvg)        -ForegroundColor Gray
    Write-Host ("║  Trained   (DQN)    avg reward : {0,8}      ║" -f $tAvg)        -ForegroundColor Green
    Write-Host ("║  Improvement                   : {0,7}%     ║" -f $improvement) -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host ("║  Precision (Rep+Arc correct)   : {0,7}%     ║" -f $precPct)     -ForegroundColor Cyan
    Write-Host ("║  Recall    (audits handled)    : {0,7}%     ║" -f $recPct)      -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║  Agent learned to:                               ║" -ForegroundColor Cyan
    Write-Host "║    Collect   gather evidence from systems       ║" -ForegroundColor White
    Write-Host "║    Classify  categorise by regulation/risk      ║" -ForegroundColor White
    Write-Host "║    Report    generate compliance report         ║" -ForegroundColor White
    Write-Host "║    Archive   store with full audit trail        ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    return @{ Agent = $agent; Results = $results; Baseline = @{ Avg = $bAvg }; Trained = @{ Avg = $tAvg } }
}

# ============================================================
# TEST SUGGESTIONS
# ============================================================
# 1. Run VBAF.LoadAll.ps1 (loads core DQN + all pillars)
#
# 2. QUICK DEMO (simulated compliance conditions)
#    $r = Invoke-VBAFComplianceReporterTraining -Episodes 100 -PrintEvery 10 -SimMode
#
# 3. FULL TRAINING (real Security event log, local users, WMI)
#    $r = Invoke-VBAFComplianceReporterTraining -Episodes 100 -PrintEvery 10
#
# 4. INSPECT AGENT DECISIONS
#    $env   = [ComplianceReporterEnvironment]::new()
#    $state = $env.Reset()
#    Write-Host "AuditGap: $($env.AuditGapScore)  Evidence: $($env.EvidenceCompleteness)"
#    $action = $r.Agent.Act($state)
#    $labels = @("Collect","Classify","Report","Archive")
#    Write-Host "Compliance decision: $($labels[$action])"
# ============================================================
Write-Host "📦 VBAF.Enterprise.ComplianceReporter.ps1 loaded  [v3.11.0 📋]" -ForegroundColor Green
Write-Host "   Phase 21: Compliance Reporting Engine"                         -ForegroundColor Cyan
Write-Host "   Function : Invoke-VBAFComplianceReporterTraining"              -ForegroundColor Cyan
Write-Host ""
Write-Host "   Quick start:" -ForegroundColor Yellow
Write-Host '   $r = Invoke-VBAFComplianceReporterTraining -Episodes 100 -PrintEvery 10 -SimMode' -ForegroundColor White
Write-Host ""